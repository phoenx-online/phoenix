import base64
import json
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from studio_jobs import RenderCoordinator, JobInputError, JobConflictError, JobBusyError
from server import validate_project, render_video


def fixture():
    tiny = b'\x89PNG\r\n\x1a\nplaceholder'
    return {
        'image_data_url': 'data:image/png;base64,' + base64.b64encode(tiny).decode(),
        'scenes': [{'style': 'hero', 'seconds': 1, 'caption': 'Internal preview'}],
        'provider': 'local_ffmpeg',
        'rights_confirmed': True,
        'max_cost_cents': 0,
        'idempotency_key': 'sample-test-key-0000001',
    }


def fake_render(payload, target, width, height):
    target.write_bytes(b'fake mp4 for queue test')


def await_finished(manager, job_id, seconds=10):
    expiry = time.monotonic() + seconds
    while time.monotonic() < expiry:
        job = manager.status(job_id)
        if job['state'] in ('DONE', 'FAILED'):
            return job
        time.sleep(0.03)
    raise AssertionError('Job timed out')


class QueueContractTests(unittest.TestCase):
    def setUp(self):
        self.manager = RenderCoordinator(fake_render, validate_project, 96, 160)

    def tearDown(self):
        self.manager.close()

    def test_rejects_missing_acknowledgment_and_paid_provider(self):
        p = fixture(); p['rights_confirmed'] = False
        with self.assertRaises(JobInputError): self.manager.submit(p)
        p = fixture(); p['provider'] = 'kling'
        with self.assertRaises(JobInputError): self.manager.submit(p)
        p = fixture(); p['max_cost_cents'] = 100
        with self.assertRaises(JobInputError): self.manager.submit(p)
        p = fixture(); p['max_cost_cents'] = False
        with self.assertRaises(JobInputError): self.manager.submit(p)

    def test_idempotent_duplicate_and_mismatched_retry(self):
        p = fixture(); first = self.manager.submit(p)
        second = self.manager.submit(p)
        self.assertEqual(first['id'], second['id'])
        p['scenes'][0]['caption'] = 'Altered claim'
        with self.assertRaises(JobConflictError): self.manager.submit(p)
        self.assertEqual(await_finished(self.manager, first['id'])['state'], 'DONE')
        self.assertEqual(self.manager.result(first['id']), b'fake mp4 for queue test')

    def test_failed_worker_does_not_publish_result(self):
        def fail(payload, target, width, height):
            raise RuntimeError('private sensitive info should not be leaked')
        separate = RenderCoordinator(fail, validate_project)
        try:
            p = fixture(); job = separate.submit(p)
            status = await_finished(separate, job['id'])
            self.assertEqual(status['state'], 'FAILED')
            self.assertNotIn('sensitive info', str(status))
            self.assertIsNone(separate.result(job['id']))
            self.assertEqual(status['actual_cost_cents'], 0)
        finally:
            separate.close()

    def test_completed_preview_expires_on_direct_download_without_status_poll(self):
        # Direct GET /api/jobs/{id}/video must not bypass the 15-minute TTL.
        p = fixture()
        created = self.manager.submit(p)
        self.assertEqual(await_finished(self.manager, created['id'])['state'], 'DONE')
        self.assertEqual(self.manager.result(created['id']), b'fake mp4 for queue test')
        with self.manager.lock:
            job = self.manager.jobs[created['id']]
            job['_finished_at'] = time.monotonic() - self.manager.TTL_SECONDS - 1
        # Do not call status() or submit() first; only result() may perform cleanup.
        self.assertIsNone(self.manager.result(created['id']))
        self.assertIsNone(self.manager.status(created['id']))
        self.assertFalse((Path(self.manager.root.name) / (created['id'] + '.mp4')).exists())

    def test_result_metadata_omits_source_image_and_status_unknown(self):
        p = fixture(); job = self.manager.submit(p)
        self.assertNotIn('image_data_url', json.dumps(job))
        self.assertIsNone(self.manager.status('unknown'))
        self.assertIsNone(self.manager.result(job['id'])) if job['state'] != 'DONE' else None

    def test_queue_backpressure_with_blocked_worker(self):
        import threading
        start = threading.Event(); release = threading.Event()
        def blocked(payload, target, width, height):
            start.set(); release.wait(timeout=4)
            fake_render(payload, target, width, height)
        limited = RenderCoordinator(blocked, validate_project)
        try:
            p=fixture(); first=limited.submit(p)
            self.assertTrue(start.wait(2))
            p['idempotency_key']='sample-test-key-0000002'; limited.submit(p)
            p['idempotency_key']='sample-test-key-0000003'; limited.submit(p)
            p['idempotency_key']='sample-test-key-0000004'
            with self.assertRaises(JobBusyError): limited.submit(p)
            release.set()
            self.assertEqual(await_finished(limited, first['id'])['state'], 'DONE')
        finally:
            release.set()
            limited.close()

    @unittest.skipUnless(shutil.which('ffmpeg') and shutil.which('ffprobe'), 'FFmpeg binaries required')
    def test_actual_ffmpeg_job_export(self):
        with tempfile.TemporaryDirectory() as td:
            image = Path(td) / 'original.png'
            subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-f', 'lavfi', '-i',
                            'color=c=white:s=240x400', '-frames:v', '1', '-y', str(image)], check=True)
            p = fixture()
            p['image_data_url'] = 'data:image/png;base64,' + base64.b64encode(image.read_bytes()).decode()
            live = RenderCoordinator(render_video, validate_project, 360, 640)
            try:
                job = live.submit(p)
                status = await_finished(live, job['id'], seconds=40)
                self.assertEqual(status['state'], 'DONE', status['error'])
                result = live.result(job['id'])
                self.assertTrue(result and len(result) > 1000)
                out=Path(td) / 'result.mp4'; out.write_bytes(result)
                meta = json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','v:0',
                    '-show_entries','stream=width,height','-of','json',str(out)]))
                self.assertEqual((meta['streams'][0]['width'], meta['streams'][0]['height']), (360,640))
                self.assertEqual(status['actual_cost_cents'], 0)
            finally:
                live.close()

if __name__ == '__main__': unittest.main()

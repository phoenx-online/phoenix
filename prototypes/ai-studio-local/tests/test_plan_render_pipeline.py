"""No-network regression: untrusted AI-style plan -> checked local FFmpeg preview.

Uses an FFmpeg-generated blank fixture, not real customer or product media.
No OpenAI API, cloud credentials, paid providers, publishing, or server deployment.
"""
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
from editing_plan import PLAN_VERSION, EditPlanError, build_local_preview_job
from server import FONT, render_video, validate_project
from studio_jobs import RenderCoordinator, JobConflictError, JobInputError


def plan():
    return {"schema_version": PLAN_VERSION, "scenes": [
        {"style": "hero", "seconds": 1, "caption": "Internal test frame"},
        {"style": "closing", "seconds": 1, "caption": "Approval pending"},
    ]}


class PlanToVideoTests(unittest.TestCase):
    def test_disallows_ai_override_of_provider_rights_and_budget(self):
        invalid = plan()
        invalid["provider"] = "paid_cloud"
        with self.assertRaises(EditPlanError):
            build_local_preview_job(invalid, image_data_url="data:image/png;base64,AAAA",
                                    rights_confirmed=True, idempotency_key="safe-test-001")
        with self.assertRaises(EditPlanError):
            build_local_preview_job(plan(), image_data_url="data:image/png;base64,AAAA",
                                    rights_confirmed=False, idempotency_key="safe-test-001")
        with self.assertRaises(EditPlanError):
            build_local_preview_job(plan(), image_data_url="data:image/png;base64,AAAA",
                                    rights_confirmed=True, max_cost_cents=1,
                                    idempotency_key="safe-test-001")

    def test_local_media_gate_rejects_fake_image_despite_valid_plan(self):
        payload = build_local_preview_job(plan(), image_data_url="data:image/png;base64,AAAA",
                                          rights_confirmed=True, idempotency_key="safe-test-002")
        worker = RenderCoordinator(render_video, validate_project, 360, 640)
        try:
            with self.assertRaises(ValueError):
                worker.submit(payload)
            self.assertEqual(len(worker.jobs), 0)
        finally:
            worker.close()

    @unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe") and FONT.is_file(),
                         "FFmpeg, FFprobe and DejaVuSans required")
    def test_model_plan_compiles_to_watermarked_local_mp4(self):
        with tempfile.TemporaryDirectory(prefix="phx-plan-test-") as directory:
            root = Path(directory)
            image = root / "blank.png"
            subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-f", "lavfi",
                            "-i", "color=c=white:s=240x400", "-frames:v", "1", "-y", str(image)],
                           check=True, timeout=15)
            payload = build_local_preview_job(
                plan(), image_data_url="data:image/png;base64," +
                base64.b64encode(image.read_bytes()).decode("ascii"),
                rights_confirmed=True, idempotency_key="safe-plan-render-001", max_cost_cents=0,
            )
            worker = RenderCoordinator(render_video, validate_project, 360, 640)
            try:
                queued = worker.submit(payload)
                self.assertIn(queued["state"], {"QUEUED", "RUNNING"})
                duplicate = worker.submit(payload)
                self.assertEqual(queued["id"], duplicate["id"])
                changed = dict(payload, scenes=[{"style": "hero", "seconds": 1,
                                                "caption": "Different source"}])
                with self.assertRaises(JobConflictError):
                    worker.submit(changed)
                deadline = time.monotonic() + 40
                while time.monotonic() < deadline:
                    status = worker.status(queued["id"])
                    if status["state"] in {"DONE", "FAILED"}:
                        break
                    time.sleep(0.05)
                self.assertEqual(status["state"], "DONE", status)
                self.assertEqual(status["actual_cost_cents"], 0)
                self.assertEqual(status["provider"], "local_ffmpeg")
                self.assertNotIn("image_data_url", json.dumps(status))
                mp4 = worker.result(queued["id"])
                self.assertTrue(mp4 and len(mp4) > 1000)
                dest = root / "preview.mp4"
                dest.write_bytes(mp4)
                probe = json.loads(subprocess.check_output([
                    "ffprobe", "-v", "error", "-select_streams", "v:0",
                    "-show_entries", "stream=codec_name,width,height:format=duration",
                    "-of", "json", str(dest)], timeout=15))
                stream = probe["streams"][0]
                self.assertEqual(stream["codec_name"], "h264")
                self.assertEqual((stream["width"], stream["height"]), (360, 640))
                self.assertAlmostEqual(float(probe["format"]["duration"]), 2, delta=0.2)
            finally:
                worker.close()


if __name__ == "__main__":
    unittest.main()

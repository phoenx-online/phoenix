"""Bounded, ephemeral, localhost-only render queue for PHOENIX AI Studio.

This is intentionally NOT an authentication, billing or public upload service.
All third-party AI providers are DISABLED; zero-cost FFmpeg previews only.
"""
from __future__ import annotations

import hashlib
import json
import queue
import re
import tempfile
import threading
import time
import uuid
from pathlib import Path
from typing import Callable


class JobInputError(ValueError):
    pass


class JobConflictError(JobInputError):
    pass


class JobBusyError(JobInputError):
    pass


class RenderCoordinator:
    """Thread-safe queue of preview renders with strict bounds and no media retention after shutdown.

    This manager does not confer product, merchant, regulatory or publishing approval.
    It only records a local operator's acknowledgement of reference-media rights.
    """

    MAX_PENDING = 2
    MAX_TOTAL = 3  # one running plus two queued
    MAX_RESULTS = 20
    MAX_RESULT_BYTES = 48 * 1024 * 1024
    TTL_SECONDS = 15 * 60

    def __init__(self, render: Callable, validate: Callable, output_width: int = 720, output_height: int = 1280):
        self.render = render
        self.validate = validate
        self.width = output_width
        self.height = output_height
        self.lock = threading.RLock()
        self.jobs: dict[str, dict] = {}
        self.idempotency: dict[str, str] = {}
        self.queue: queue.Queue = queue.Queue(maxsize=self.MAX_PENDING)
        self.root = tempfile.TemporaryDirectory(prefix='phx-studio-jobs-')
        self.stop_event = threading.Event()
        self.worker = threading.Thread(target=self._run, name='phx-studio-ffmpeg-worker', daemon=True)
        self.worker.start()

    @staticmethod
    def _view(job: dict) -> dict:
        return {key: job[key] for key in ('id', 'state', 'provider', 'estimated_cost_cents', 'actual_cost_cents', 'created_at', 'error')}

    @staticmethod
    def _fingerprint(payload: dict) -> str:
        # Stable request hash even if a caller changes JSON object-key ordering.
        encoded = json.dumps(payload, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf8')
        return hashlib.sha256(encoded).hexdigest()

    def _expire(self):
        now = time.monotonic()
        for job_id, job in list(self.jobs.items()):
            if job['state'] not in ('DONE', 'FAILED'):
                continue
            if now - job['_finished_at'] <= self.TTL_SECONDS:
                continue
            path = Path(self.root.name) / (job_id + '.mp4')
            path.unlink(missing_ok=True)
            del self.jobs[job_id]
            if job['_key']:
                self.idempotency.pop(job['_key'], None)

    def submit(self, payload: dict) -> dict:
        if not isinstance(payload, dict):
            raise JobInputError('Expected a JSON object')
        if payload.get('provider') != 'local_ffmpeg':
            raise JobInputError('Only local_ffmpeg is enabled; cloud AI generation is disabled')
        if payload.get('rights_confirmed') is not True:
            raise JobInputError('Media rights acknowledgement is required for internal preview')
        if type(payload.get('max_cost_cents')) is not int or payload['max_cost_cents'] != 0:
            raise JobInputError('Local preview requires an exact zero-cent spending limit')
        key = payload.get('idempotency_key')
        if key is not None and (not isinstance(key, str) or not re.fullmatch(r'[A-Za-z0-9_-]{8,80}', key)):
            raise JobInputError('Idempotency key must be 8–80 safe characters')
        # Validate full payload before storage/queue. This is not full media-malware scanning.
        self.validate(payload)
        content_hash = self._fingerprint({k: v for k, v in payload.items() if k != 'idempotency_key'})
        with self.lock:
            self._expire()
            if key and key in self.idempotency:
                old = self.jobs[self.idempotency[key]]
                if old['_hash'] != content_hash:
                    raise JobConflictError('Idempotency key reused for different media or scenes')
                return self._view(old)
            active = sum(job['state'] in ('QUEUED', 'RUNNING') for job in self.jobs.values())
            if active >= self.MAX_TOTAL or self.queue.full():
                raise JobBusyError('Local render queue full; try again after an existing job finishes')
            if len(self.jobs) >= self.MAX_RESULTS:
                raise JobBusyError('Local session history full; restart this development server to clear it')
            job_id = str(uuid.uuid4())
            job = {'id': job_id, 'state': 'QUEUED', 'provider': 'local_ffmpeg',
                   'estimated_cost_cents': 0, 'actual_cost_cents': None,
                   'created_at': int(time.time()), 'error': None,
                   '_hash': content_hash, '_key': key, '_finished_at': None}
            # Keep image bytes only in pending queue, never in job/status metadata.
            self.queue.put_nowait((job_id, payload))
            self.jobs[job_id] = job
            if key:
                self.idempotency[key] = job_id
            return self._view(job)

    def status(self, job_id: str) -> dict | None:
        with self.lock:
            self._expire()
            job = self.jobs.get(job_id)
            return self._view(job) if job else None

    def result(self, job_id: str) -> bytes | None:
        with self.lock:
            job = self.jobs.get(job_id)
            if not job or job['state'] != 'DONE':
                return None
            path = Path(self.root.name) / (job_id + '.mp4')
            if not path.is_file() or path.stat().st_size > self.MAX_RESULT_BYTES:
                return None
            return path.read_bytes()

    def _run(self):
        while not self.stop_event.is_set():
            try:
                job_id, payload = self.queue.get(timeout=0.1)
            except queue.Empty:
                continue
            with self.lock:
                job = self.jobs[job_id]
                job['state'] = 'RUNNING'
            destination = Path(self.root.name) / (job_id + '.mp4')
            try:
                self.render(payload, destination, width=self.width, height=self.height)
                if not destination.is_file() or not (0 < destination.stat().st_size <= self.MAX_RESULT_BYTES):
                    raise RuntimeError('Generated MP4 missing, empty or exceeds preview size cap')
            except Exception as exc:
                destination.unlink(missing_ok=True)
                with self.lock:
                    job['state'] = 'FAILED'
                    job['error'] = 'Local render failed; inspect server logs'
                    job['actual_cost_cents'] = 0
                    job['_finished_at'] = time.monotonic()
                print('PHOENIX preview render failure:', type(exc).__name__, flush=True)
            else:
                with self.lock:
                    job['state'] = 'DONE'
                    job['actual_cost_cents'] = 0
                    job['_finished_at'] = time.monotonic()
            finally:
                # Drop sensitive bytes once this execution frame completes.
                del payload
                self.queue.task_done()

    def close(self):
        self.stop_event.set()
        self.worker.join(timeout=2)
        if self.worker.is_alive():
            raise RuntimeError('Cannot clean up while a local render is still running')
        self.root.cleanup()

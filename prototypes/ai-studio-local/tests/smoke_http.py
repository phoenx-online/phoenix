"""Manual HTTP integration smoke test. Requires Python3 and FFmpeg; no external AI."""
import base64
import json
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ORIGIN = "http://127.0.0.1:8766"

def request(path, payload=None):
    if payload is None:
        return urllib.request.urlopen(ORIGIN + path, timeout=5)
    raw = json.dumps(payload).encode()
    req = urllib.request.Request(ORIGIN + path, raw,
        {"Content-Type": "application/json", "Origin": ORIGIN}, method="POST")
    return urllib.request.urlopen(req, timeout=5)

def expected_error(path, payload, code):
    try:
        request(path, payload).close()
    except urllib.error.HTTPError as exc:
        assert exc.code == code, (path, exc.code)
    else:
        raise AssertionError(f"Expected {code} for {path}")

def main():
    with tempfile.TemporaryDirectory() as directory:
        img = Path(directory) / "reference.png"
        subprocess.run(["ffmpeg","-hide_banner","-loglevel","error","-f","lavfi",
                        "-i","color=c=white:s=240x400","-frames:v","1","-y",str(img)],check=True)
        server = subprocess.Popen([sys.executable,str(ROOT / "server.py")],cwd=ROOT,
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            for _ in range(40):
                try:
                    with request("/api/health") as res:
                        assert json.load(res)["paid_api_enabled"] is False
                        break
                except Exception:
                    time.sleep(.1)
            else:
                raise AssertionError("Local server did not start")
            body = {"image_data_url":"data:image/png;base64," +
                     base64.b64encode(img.read_bytes()).decode(),
                    "scenes":[{"style":"hero","seconds":1,"caption":"Internal test"}],
                    "provider":"local_ffmpeg","rights_confirmed":True,
                    "max_cost_cents":0,"idempotency_key":"qa-http-test-20261117"}
            expected_error("/api/jobs",dict(body,rights_confirmed=False),400)
            expected_error("/api/jobs",dict(body,provider="paid_cloud"),400)
            expected_error("/api/render",body,410)
            with request("/api/jobs",body) as res:
                assert res.status == 202
                created = json.load(res)
            with request("/api/jobs",body) as res:
                assert json.load(res)["id"] == created["id"]
            for _ in range(150):
                with request("/api/jobs/" + created["id"]) as res:
                    state = json.load(res)
                if state["state"] in ("DONE","FAILED"):
                    break
                time.sleep(.2)
            assert state["state"] == "DONE", state
            with request("/api/jobs/" + created["id"] + "/video") as res:
                assert res.headers["Content-Type"] == "video/mp4"
                video = res.read()
            assert len(video) > 1000
            output = Path(directory) / "preview.mp4"
            output.write_bytes(video)
            result = json.loads(subprocess.check_output(["ffprobe","-v","error",
                "-select_streams","v:0","-show_entries","stream=width,height",
                "-of","json",str(output)]))
            assert (result["streams"][0]["width"],result["streams"][0]["height"]) == (720,1280)
            print("PASS: HTTP rights, provider, legacy denial, idempotency, queued MP4 export")
        finally:
            server.terminate()
            try: server.wait(timeout=5)
            except subprocess.TimeoutExpired: server.kill(); server.wait()

if __name__ == "__main__":
    main()

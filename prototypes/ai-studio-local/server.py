#!/usr/bin/env python3
"""PHOENIX AI Studio local creative prototype. No AI services or remote uploads.

Serves a single-user localhost web interface and converts authorized uploaded image
bytes into a motion-graphics MP4 with FFmpeg. Do not expose on public networks.
"""
from __future__ import annotations

import base64
import binascii
import json
import re
import shutil
import subprocess
import tempfile
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parent
HOST = "127.0.0.1"
PORT = 8766
MAX_BODY = 12 * 1024 * 1024
MAX_IMAGE = 8 * 1024 * 1024
MAX_SCENES = 6
ALLOWED_STYLES = {"reveal", "detail", "hero", "closing"}
FONT = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")


class InputError(ValueError):
    pass


def validate_project(payload: dict) -> tuple[bytes, str, list[dict]]:
    if not isinstance(payload, dict):
        raise InputError("Project must be an object")
    source = payload.get("image_data_url")
    if not isinstance(source, str) or len(source) > MAX_BODY:
        raise InputError("A product photo is required (maximum 8 MB)")
    match = re.fullmatch(r"data:image/(png|jpeg|webp);base64,([A-Za-z0-9+/=\r\n]+)", source)
    if not match:
        raise InputError("Provide one PNG, JPEG or WebP image")
    try:
        image = base64.b64decode(match.group(2), validate=True)
    except binascii.Error as exc:
        raise InputError("Invalid image encoding") from exc
    if not image or len(image) > MAX_IMAGE:
        raise InputError("Image must be 1 byte to 8 MB")
    ext = match.group(1)
    valid_magic = (ext == "png" and image.startswith(b"\x89PNG\r\n\x1a\n")) or (
        ext == "jpeg" and image.startswith(b"\xff\xd8\xff")) or (
        ext == "webp" and image.startswith(b"RIFF") and image[8:12] == b"WEBP"
    )
    if not valid_magic:
        raise InputError("Image content does not match its file type")
    scenes = payload.get("scenes")
    if not isinstance(scenes, list) or not 1 <= len(scenes) <= MAX_SCENES:
        raise InputError("Create between 1 and 6 scenes")
    cleaned = []
    total = 0
    for row in scenes:
        if not isinstance(row, dict) or row.get("style") not in ALLOWED_STYLES:
            raise InputError("Unknown scene type")
        seconds = row.get("seconds")
        if type(seconds) is not int or not 1 <= seconds <= 6:
            raise InputError("Each scene must be 1–6 seconds")
        text = row.get("caption", "")
        if not isinstance(text, str) or len(text) > 90 or "\x00" in text:
            raise InputError("Captions must be under 90 characters")
        cleaned.append({"style": row["style"], "seconds": seconds, "caption": text.replace("\n", " ").strip()})
        total += seconds
    if total > 24:
        raise InputError("The prototype supports up to 24 seconds")
    return image, ext, cleaned


def _vf(style: str, caption_path: Path, notice_path: Path, width: int, height: int) -> str:
    # Avoid transforming package art, colors, or labels; only crop/zoom the supplied real photo.
    if style == "reveal":
        zoom = "min(zoom+0.0006,1.08)"
    elif style == "detail":
        zoom = "min(max(zoom,1.09)+0.0003,1.15)"
    elif style == "closing":
        zoom = "1.02"
    else:
        zoom = "1.0"
    # textfile avoids injecting arbitrary user input into the filter string.
    stack = [
        f"scale={width}:{height}:force_original_aspect_ratio=decrease",
        f"pad={width}:{height}:(ow-iw)/2:(oh-ih)/2:color=0xfffbf6",
        f"zoompan=z='{zoom}':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s={width}x{height}:fps=24",
        "format=yuv420p",
    ]
    if caption_path.read_text(encoding="utf8").strip():
        stack.append(
            "drawtext=fontfile=" + str(FONT) + ":textfile=" + str(caption_path)
            + ":fontcolor=white:fontsize=" + str(max(15, width // 24))
            + ":x=(w-text_w)/2:y=h*0.81:box=1:boxcolor=black@0.62:boxborderw=14"
        )
    stack.append(
        "drawtext=fontfile=" + str(FONT) + ":textfile=" + str(notice_path)
        + ":fontcolor=white:fontsize=" + str(max(12, width // 40))
        + ":x=(w-text_w)/2:y=h*0.945:box=1:boxcolor=black@0.62:boxborderw=8"
    )
    return ",".join(stack)


def render_video(payload: dict, target: Path, width: int = 720, height: int = 1280) -> None:
    image, ext, scenes = validate_project(payload)
    if shutil.which("ffmpeg") is None:
        raise RuntimeError("FFmpeg is not installed on this computer")
    with tempfile.TemporaryDirectory(prefix="phx-video-") as td:
        temp = Path(td)
        src = temp / ("source." + ("jpg" if ext == "jpeg" else ext))
        src.write_bytes(image)
        notice = temp / "internal.txt"
        notice.write_text("INTERNAL CONCEPT  -  NOT APPROVED FOR PUBLICATION", encoding="utf8")
        videos = []
        for index, scene in enumerate(scenes):
            caption = temp / f"caption{index}.txt"
            caption.write_text(scene["caption"], encoding="utf8")
            clip = temp / f"clip{index:02}.mp4"
            command = [
                "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
                "-loop", "1", "-framerate", "24", "-i", str(src),
                "-t", str(scene["seconds"]), "-vf", _vf(scene["style"], caption, notice, width, height),
                "-an", "-c:v", "libx264", "-preset", "ultrafast", "-crf", "25",
                "-pix_fmt", "yuv420p", "-r", "24", "-threads", "2", str(clip),
            ]
            try:
                subprocess.run(command, check=True, timeout=90, capture_output=True)
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as exc:
                error = exc.stderr.decode(errors="replace")[-450:] if isinstance(exc, subprocess.CalledProcessError) else "Rendering timed out"
                raise RuntimeError("FFmpeg failed: " + error) from exc
            videos.append(clip)
        concat = temp / "clips.txt"
        concat.write_text("".join(f"file '{c.name}'\n" for c in videos), encoding="utf8")
        command = ["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
                   "-f", "concat", "-safe", "1", "-i", str(concat), "-c", "copy", "-movflags", "+faststart", str(target)]
        try:
            subprocess.run(command, check=True, timeout=40, capture_output=True, cwd=temp)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as exc:
            raise RuntimeError("Could not assemble the MP4") from exc


class LocalHandler(BaseHTTPRequestHandler):
    server_version = "PhoenixLocalStudio/0.1"

    def _json(self, status: int, obj: dict):
        data = json.dumps(obj).encode("utf8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _same_origin(self) -> bool:
        host = self.headers.get("Host", "")
        if host not in (f"127.0.0.1:{PORT}", f"localhost:{PORT}"):
            return False
        origin = self.headers.get("Origin")
        return not origin or origin in (f"http://127.0.0.1:{PORT}", f"http://localhost:{PORT}")

    def do_GET(self):
        if not self._same_origin():
            return self._json(403, {"error": "Local-only access"})
        path = urlsplit(self.path).path
        if path == "/api/health":
            return self._json(200, {"status": "ok", "local_only": True, "ai_generation": False, "ffmpeg": shutil.which("ffmpeg") is not None})
        if path not in ("/", "/index.html"):
            return self._json(404, {"error": "Not found"})
        body = (ROOT / "index.html").read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Security-Policy", "default-src 'none'; img-src 'self' blob: data:; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'; form-action 'none'; base-uri 'none'")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if not self._same_origin():
            return self._json(403, {"error": "Local-only access"})
        if urlsplit(self.path).path != "/api/render":
            return self._json(404, {"error": "Not found"})
        if self.headers.get("Content-Type", "").split(";")[0] != "application/json":
            return self._json(415, {"error": "Expected JSON"})
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return self._json(400, {"error": "Invalid Content-Length"})
        if length <= 0 or length > MAX_BODY:
            return self._json(413, {"error": "Request too large"})
        try:
            payload = json.loads(self.rfile.read(length))
            with tempfile.TemporaryDirectory(prefix="phx-response-") as td:
                output = Path(td) / "preview.mp4"
                render_video(payload, output)
                media = output.read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", "video/mp4")
                self.send_header("Content-Disposition", 'attachment; filename="PHOENIX_AI_Studio_Internal_Concept.mp4"')
                self.send_header("Cache-Control", "no-store")
                self.send_header("X-Content-Type-Options", "nosniff")
                self.send_header("Content-Length", str(len(media)))
                self.end_headers()
                self.wfile.write(media)
        except (ValueError, json.JSONDecodeError) as exc:
            self._json(400, {"error": str(exc)})
        except RuntimeError as exc:
            self._json(500, {"error": str(exc)})


def main():
    if not FONT.is_file():
        raise SystemExit("This prototype needs a DejaVuSans font for visible internal watermark")
    print(f"PHOENIX AI Studio local prototype: http://{HOST}:{PORT}")
    print("Not for public hosting. No AI video provider, remote uploads, or publishing.")
    HTTPServer((HOST, PORT), LocalHandler).serve_forever()


if __name__ == "__main__":
    main()
"""Fail-closed OpenAI-compatible editing plans for localhost PHOENIX previews.

The module makes NO network calls and invokes NO processes. Model output is treated as
untrusted scene suggestions, never permission to access media, spend, or publish.
A trusted local operator must supply the media and explicitly acknowledge rights.
"""
from __future__ import annotations

import re

PLAN_VERSION = "phoenix.edit_plan.v1"
ALLOWED_STYLES = frozenset(("reveal", "detail", "hero", "closing"))
MAX_SCENES = 6
MAX_SECONDS = 24
MAX_CAPTION_CHARS = 90

# Compatible shape for constrained structured output. Always validate locally too.
EDIT_PLAN_JSON_SCHEMA = {
    "name": "phoenix_edit_plan_v1",
    "strict": True,
    "schema": {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "schema_version": {"type": "string", "enum": [PLAN_VERSION]},
            "scenes": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "properties": {
                        "style": {"type": "string", "enum": sorted(ALLOWED_STYLES)},
                        "seconds": {"type": "integer"},
                        "caption": {"type": "string"},
                    },
                    "required": ["style", "seconds", "caption"],
                },
            },
        },
        "required": ["schema_version", "scenes"],
    },
}


class EditPlanError(ValueError):
    """The proposed AI editing instructions cannot be safely used."""


def validate_edit_plan(plan: object) -> list[dict]:
    """Return sanitized local scenes or reject the entire untrusted plan.

    No claims clearance, product authenticity or media-rights approval is inferred.
    This deliberately accepts only operations supported by the existing renderer.
    """
    if type(plan) is not dict or set(plan) != {"schema_version", "scenes"}:
        raise EditPlanError("Editing plan must contain only schema_version and scenes")
    if plan["schema_version"] != PLAN_VERSION:
        raise EditPlanError("Unsupported editing plan version")
    proposed = plan["scenes"]
    if type(proposed) is not list or not 1 <= len(proposed) <= MAX_SCENES:
        raise EditPlanError("Editing plan must include 1–6 scenes")
    scenes: list[dict] = []
    seconds_total = 0
    for row in proposed:
        if type(row) is not dict or set(row) != {"style", "seconds", "caption"}:
            raise EditPlanError("Scene has missing or unsupported fields")
        style, seconds, caption = row["style"], row["seconds"], row["caption"]
        if type(style) is not str or style not in ALLOWED_STYLES:
            raise EditPlanError("Unsupported scene style")
        if type(seconds) is not int or not 1 <= seconds <= 6:
            raise EditPlanError("Scene duration must be an integer from 1 to 6 seconds")
        if type(caption) is not str or len(caption) > MAX_CAPTION_CHARS:
            raise EditPlanError("Caption exceeds supported limit")
        if any(ord(char) < 32 or ord(char) == 127 for char in caption):
            raise EditPlanError("Control characters are not permitted in captions")
        seconds_total += seconds
        if seconds_total > MAX_SECONDS:
            raise EditPlanError("Editing plan exceeds the 24-second preview limit")
        scenes.append({"style": style, "seconds": seconds, "caption": caption.strip()})
    return scenes


def build_local_preview_job(
    plan: object,
    *,
    image_data_url: str,
    rights_confirmed: bool,
    idempotency_key: str,
    max_cost_cents: int = 0,
) -> dict:
    """Compile a validated plan into the existing *local-only* queue contract.

    The scene plan does not carry consent, budget or provider authority. The caller
    supplies those separately. Downstream queue/media checks remain mandatory.
    """
    scenes = validate_edit_plan(plan)
    if rights_confirmed is not True:
        raise EditPlanError("A human must acknowledge rights to the source media")
    if type(max_cost_cents) is not int or max_cost_cents != 0:
        raise EditPlanError("Only zero-cost local previews are permitted")
    if type(image_data_url) is not str or not image_data_url.startswith("data:image/"):
        raise EditPlanError("A local source image is required")
    if type(idempotency_key) is not str or not re.fullmatch(r"[A-Za-z0-9_-]{8,80}", idempotency_key):
        raise EditPlanError("Invalid idempotency key")
    return {
        "provider": "local_ffmpeg",
        "rights_confirmed": True,
        "max_cost_cents": 0,
        "idempotency_key": idempotency_key,
        "image_data_url": image_data_url,
        "scenes": scenes,
    }

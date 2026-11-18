"""Local-only deterministic editing-plan contract regression tests."""
import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from editing_plan import (
    EDIT_PLAN_JSON_SCHEMA, EditPlanError, PLAN_VERSION,
    build_local_preview_job, validate_edit_plan,
)


def sample():
    return {
        "schema_version": PLAN_VERSION,
        "scenes": [
            {"style": "hero", "seconds": 2, "caption": "Approved product pack"},
            {"style": "detail", "seconds": 2, "caption": "Real source photo"},
        ],
    }


class EditingPlanContractTests(unittest.TestCase):
    def test_compiles_supported_plan_without_mutating_it(self):
        raw = sample(); original = copy.deepcopy(raw)
        scenes = validate_edit_plan(raw)
        self.assertEqual(raw, original)
        self.assertEqual(len(scenes), 2)
        compiled = build_local_preview_job(raw, image_data_url="data:image/png;base64,AAAA",
                                           rights_confirmed=True, idempotency_key="test-plan-0001")
        self.assertEqual(compiled["provider"], "local_ffmpeg")
        self.assertEqual(compiled["max_cost_cents"], 0)
        self.assertEqual(compiled["scenes"], scenes)
        self.assertNotIn("api_key", str(compiled))

    def test_refuses_unknown_fields_and_versions(self):
        raw = sample(); raw["provider"] = "runway"
        with self.assertRaises(EditPlanError): validate_edit_plan(raw)
        raw = sample(); raw["schema_version"] = "phoenix.edit_plan.v2"
        with self.assertRaises(EditPlanError): validate_edit_plan(raw)
        raw = sample(); raw["scenes"][0]["shell_command"] = "rm -rf /"
        with self.assertRaises(EditPlanError): validate_edit_plan(raw)

    def test_refuses_unsupported_operations(self):
        for invalid in ("voice_clone", "auto_publish", "arbitrary_filter"):
            raw = sample(); raw["scenes"][0]["style"] = invalid
            with self.subTest(style=invalid), self.assertRaises(EditPlanError):
                validate_edit_plan(raw)

    def test_refuses_invalid_durations_bool_and_total(self):
        for invalid in (0, 7, 1.5, True):
            raw = sample(); raw["scenes"][0]["seconds"] = invalid
            with self.subTest(seconds=invalid), self.assertRaises(EditPlanError):
                validate_edit_plan(raw)
        raw = sample(); raw["scenes"] = [dict(style="hero", seconds=5, caption="") for _ in range(5)]
        with self.assertRaises(EditPlanError): validate_edit_plan(raw)

    def test_refuses_caption_injection_and_missing_fields(self):
        for caption in ("a" * 91, "line\nnew", "bad\x00input"):
            raw = sample(); raw["scenes"][0]["caption"] = caption
            with self.subTest(caption=caption), self.assertRaises(EditPlanError):
                validate_edit_plan(raw)
        raw = sample(); del raw["scenes"][0]["caption"]
        with self.assertRaises(EditPlanError): validate_edit_plan(raw)

    def test_rights_and_budget_are_not_controlled_by_ai_plan(self):
        params = dict(image_data_url="data:image/png;base64,AAAA", idempotency_key="test-plan-0001")
        with self.assertRaises(EditPlanError):
            build_local_preview_job(sample(), rights_confirmed=False, **params)
        with self.assertRaises(EditPlanError):
            build_local_preview_job(sample(), rights_confirmed=True, max_cost_cents=1, **params)
        with self.assertRaises(EditPlanError):
            build_local_preview_job(sample(), rights_confirmed=True, max_cost_cents=False, **params)
        with self.assertRaises(EditPlanError):
            build_local_preview_job(sample(), rights_confirmed=True, image_data_url="https://example.com/img", idempotency_key="test-plan-0001")
        with self.assertRaises(EditPlanError):
            build_local_preview_job(sample(), rights_confirmed=True, image_data_url="data:image/png;base64,AAAA", idempotency_key="bad/key")

    def test_schema_is_closed_and_requires_all_fields(self):
        schema = EDIT_PLAN_JSON_SCHEMA["schema"]
        self.assertFalse(schema["additionalProperties"])
        self.assertFalse(schema["properties"]["scenes"]["items"]["additionalProperties"])
        self.assertEqual(set(schema["required"]), {"schema_version", "scenes"})


if __name__ == "__main__":
    unittest.main()

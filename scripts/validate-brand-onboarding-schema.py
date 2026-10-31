#!/usr/bin/env python3
"""PHOENIX onboarding contract preflight: stdlib-only, no network or client data."""
import json
import pathlib
import sys

CONTRACT = pathlib.Path(__file__).resolve().parents[1] / "config" / "brand-onboarding-v1.json"
VALID_TYPES = {
    "text", "textarea", "email", "tel", "url", "number", "date",
    "boolean", "checkbox", "select", "multiselect"
}
FORBIDDEN_FIELD_FRAGMENTS = (
    "password", "otp", "recovery_code", "private_key", "api_secret",
    "bank_password", "access_token", "refresh_token",
)


def fail(message):
    raise ValueError(message)


def check_condition(condition, known_keys, service_keys):
    if not isinstance(condition, dict):
        fail("Condition must be an object")
    if "field" in condition and condition["field"] not in known_keys:
        fail(f"Unknown condition field: {condition['field']}")
    if "any_services" in condition:
        if not condition["any_services"] or any(
            service not in service_keys for service in condition["any_services"]
        ):
            fail("Condition references an unknown/empty service")
    if not ({"field", "any_services"} & condition.keys()):
        fail("Unsupported condition")


def validate(contract):
    assert contract["schema_version"] == "1.0.0"
    assert contract["status"] == "foundation_contract_not_live"
    services = contract["services"]
    if len(services) != len(set(services)) or len(services) != 6:
        fail("Expected six unique PHOENIX service pillars")
    steps = contract["steps"]
    if len(steps) != 8:
        fail("Expected eight onboarding steps")
    if len({step["key"] for step in steps}) != len(steps):
        fail("Repeated step key")
    questions = [question for step in steps for question in step["questions"]]
    keys = [question["key"] for question in questions]
    if len(keys) != len(set(keys)):
        fail("Repeated question key")
    if any(fragment in key.lower() for key in keys for fragment in FORBIDDEN_FIELD_FRAGMENTS):
        fail("Question must not solicit credentials")
    if not {"selected_services", "truthfulness_attestation",
            "privacy_notice_ack", "operating_authorization"} <= set(keys):
        fail("Missing required scope/authorization questions")
    for step in steps:
        if not step["questions"]:
            fail("Empty onboarding step")
        if "when" in step:
            check_condition(step["when"], keys, services)
    for question in questions:
        if question["type"] not in VALID_TYPES:
            fail(f"Unsupported answer type for {question['key']}")
        if not isinstance(question["required"], bool):
            fail(f"Required flag must be boolean for {question['key']}")
        if question["type"] in {"select", "multiselect"} and not question.get("options"):
            fail(f"Missing options for {question['key']}")
        if question["key"] == "selected_services" and set(question["options"]) != set(services):
            fail("Selected services must cover all six pillars")
        if "when" in question:
            check_condition(question["when"], keys, services)
    documents = contract["document_types"]
    if len(documents) != 13 or len({doc["key"] for doc in documents}) != len(documents):
        fail("Missing/duplicate document categories")
    rules = contract["rules"]
    if not rules["no_platform_passwords_or_one_time_codes"]:
        fail("Marketplace credential prohibition missing")
    if not rules["private_document_storage"]:
        fail("Private file storage prohibition missing")
    if rules["max_document_bytes"] > 20 * 1024 * 1024:
        fail("Unexpected document size limit")
    if "quarantined" not in rules["document_statuses"] or "scanning" not in rules["document_statuses"]:
        fail("Document quarantine/scan gates missing")
    print(f"PASS brand onboarding contract: {len(steps)} steps, "
          f"{len(questions)} questions, {len(documents)} document types, "
          f"{len(services)} pillars")


if __name__ == "__main__":
    try:
        validate(json.loads(CONTRACT.read_text(encoding="utf-8")))
    except (OSError, ValueError, AssertionError, KeyError, TypeError) as exc:
        print(f"FAIL brand onboarding contract: {exc}", file=sys.stderr)
        sys.exit(1)

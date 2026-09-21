#!/usr/bin/env python3
import json
import pathlib
import sys

CONFIG = pathlib.Path("config/production-delivery-standard.json")
DOC = pathlib.Path("PRODUCTION_DELIVERY_COMPLETION_STANDARD_V1.md")
AGENTS = pathlib.Path("AGENTS.md")

required_gates = {
    "canonical_source_preflight",
    "affected_module_tests",
    "synthetic_or_user_facing_acceptance",
    "staging_or_project_equivalent_qualification",
    "rollback_or_forward_repair_readiness",
    "production_authority_gate",
    "post_deploy_smoke_or_health_verification",
    "observability_check",
    "release_evidence",
}

def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)

for path in (CONFIG, DOC, AGENTS):
    if not path.is_file():
        fail(f"missing {path}")

try:
    data = json.loads(CONFIG.read_text(encoding="utf-8"))
except Exception as exc:
    fail(f"invalid JSON in {CONFIG}: {exc}")

if data.get("standard") != "production-delivery-completion-v1":
    fail("unexpected standard identifier")
if data.get("definition_of_done") != "production_verified_observable_recoverable":
    fail("definition_of_done must remain production_verified_observable_recoverable")
if data.get("build_once_promote_same_artifact") is not True:
    fail("build_once_promote_same_artifact must be true")
if data.get("ai_may_waive_failed_gate") is not False:
    fail("AI must never be allowed to waive a failed gate")
if data.get("project_specific_rules_remain_authoritative") is not True:
    fail("project-specific safety rules must remain authoritative")
if data.get("repeated_failure_policy") != "convert_recurring_failure_class_into_deterministic_automation":
    fail("recurring failures must be converted into deterministic automation")
if data.get("close_rule") != "production_bound_work_closes_only_after_verified_production_release":
    fail("production-bound work may close only after verified production release")

release_identity = data.get("release_identity")
if not isinstance(release_identity, list):
    fail("release_identity must be a list")
for item in ("source_commit_sha", "artifact_digest_when_applicable"):
    if item not in release_identity:
        fail(f"release_identity missing {item}")

configured_gates = data.get("required_gates")
if not isinstance(configured_gates, list):
    fail("required_gates must be a list")
if len(configured_gates) != len(set(configured_gates)):
    fail("required_gates contains duplicates")
missing = sorted(required_gates.difference(configured_gates))
if missing:
    fail("required_gates missing: " + ", ".join(missing))

doc = DOC.read_text(encoding="utf-8").lower()
for phrase in ("production", "verified", "observable", "recoverable"):
    if phrase not in doc:
        fail(f"{DOC} missing completion concept: {phrase}")

agents = AGENTS.read_text(encoding="utf-8")
if "Production Delivery Completion Standard" not in agents:
    fail("AGENTS.md must reference the Production Delivery Completion Standard")

print("PRODUCTION_DELIVERY_STANDARD=PASS")
print("AI_GATE_WAIVER=DENIED")
print("BUILD_ONCE_PROMOTE_SAME_ARTIFACT=REQUIRED")
print("RECURRING_FAILURE_AUTOMATION=REQUIRED")

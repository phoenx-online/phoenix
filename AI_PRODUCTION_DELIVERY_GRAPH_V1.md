# PHOENIX — AI Production Delivery Graph V1

Status: Phase 1 shadow rollout for DEV readiness only.

PHOENIX adopts AI Production Delivery Graph V1 while preserving the approved DEV-only isolation baseline. This does not authorize production deployment.

## Phase 1 implementation

- use the dedicated `phoenix-dev` self-hosted runner boundary
- verify the exact candidate SHA
- cancel superseded readiness runs
- classify delivery risk
- validate source, PHP/Composer, shell, and Docker Compose configuration where available
- emit readiness evidence
- never use Craniumtek, MBG, or iBayong secrets or production authority

## Required progression

1. Finish the isolated PostgreSQL-based DEV modernization.
2. Prove application boot, migration, health, restart, and restore gates on PHOENIX DEV.
3. Produce one immutable candidate per accepted SHA.
4. Create an independent PHOENIX staging boundary and verify the exact candidate digest there.
5. Only then design a PHOENIX production controller with least privilege, serialized promotion, reversible blue/green or canary rollout, health checks, and deterministic rollback.

`main` remains canonical source and is not an automatic production-deployment trigger.
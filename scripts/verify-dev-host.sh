#!/usr/bin/env bash
set -Eeuo pipefail

EXPECTED_HOST="craniumtek-lab-01"
MIN_CPU=2
MIN_MEM_KIB=$((5 * 1024 * 1024))
MIN_FREE_KIB=$((100 * 1024 * 1024))
FAIL=0
WARN=0

pass(){ printf '✅ %s\n' "$*"; }
warn(){ printf '⚠️  %s\n' "$*"; WARN=$((WARN+1)); }
fail(){ printf '❌ %s\n' "$*"; FAIL=$((FAIL+1)); }
section(){ printf '\n=== %s ===\n' "$*"; }

section "PHOENIX DEV HOST VERIFICATION"
printf 'Timestamp: %s\n' "$(date -Is)"
printf 'User: %s\n' "$(id -un)"
printf 'Hostname: %s\n' "$(hostname)"

if [[ "$(hostname)" == "$EXPECTED_HOST" ]]; then
  pass "Expected DEV host: $EXPECTED_HOST"
else
  warn "Expected $EXPECTED_HOST but found $(hostname); stop before bootstrap unless this host change is deliberate."
fi

section "OS / KERNEL"
if [[ -r /etc/os-release ]]; then cat /etc/os-release; fi
uname -a

section "CPU"
CPU_COUNT="$(nproc)"
printf 'CPU count: %s\n' "$CPU_COUNT"
lscpu | sed -n '1,25p' || true
if (( CPU_COUNT >= MIN_CPU )); then pass "CPU gate >= ${MIN_CPU}"; else fail "CPU gate requires >= ${MIN_CPU}"; fi

section "MEMORY / SWAP"
free -h
MEM_TOTAL_KIB="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
if (( MEM_TOTAL_KIB >= MIN_MEM_KIB )); then pass "RAM gate >= 5 GiB"; else fail "RAM below 5 GiB"; fi

section "DISK"
df -hT /
FREE_KIB="$(df -Pk / | awk 'NR==2 {print $4}')"
if (( FREE_KIB >= MIN_FREE_KIB )); then pass "Root free-space gate >= 100 GiB"; else fail "Root free space below 100 GiB"; fi
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS,MODEL || true

section "DOCKER"
if command -v docker >/dev/null 2>&1; then
  docker --version
  if docker compose version >/dev/null 2>&1; then
    docker compose version
    pass "Docker Compose plugin available"
  else
    fail "Docker Compose plugin unavailable"
  fi
  if docker info >/dev/null 2>&1; then
    pass "Current user can access Docker"
  else
    fail "Current user cannot access Docker without escalation"
  fi
else
  fail "Docker not installed"
fi

section "EXISTING CONTAINERS"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' || true
  echo
  echo "Docker disk usage:"
  docker system df || true
fi

section "LISTENING PORTS"
ss -lntup 2>/dev/null || ss -lnt 2>/dev/null || true

section "PHOENIX / IBAYONG ACCOUNT BOUNDARY"
for acct in phoenix ibayong; do
  if id "$acct" >/dev/null 2>&1; then
    pass "Linux account exists: $acct"
    id "$acct"
  else
    warn "Linux account missing: $acct"
  fi
done

for path in /home/phoenix/projects /home/phoenix/private /home/ibayong/projects /home/ibayong/private; do
  if [[ -d "$path" ]]; then
    printf 'Present: %s (%s:%s %s)\n' "$path" "$(stat -c %U "$path")" "$(stat -c %G "$path")" "$(stat -c %a "$path")"
  else
    warn "Expected DEV boundary path missing: $path"
  fi
done

section "SELF-HOSTED RUNNER INVENTORY"
ps -eo user,pid,ppid,etime,args | grep -E '[R]unner.Listener|[R]unner.Worker' || echo "No active GitHub runner processes found"
find /home -maxdepth 4 -type f -name '.runner' -print 2>/dev/null || true

section "BACKUP / STORAGE SIGNALS"
find /home -maxdepth 4 \( -iname '*backup*' -o -iname '*restic*' \) -print 2>/dev/null | head -100 || true

section "DISK SMART SIGNAL (READ-ONLY, BEST EFFORT)"
if command -v smartctl >/dev/null 2>&1; then
  for dev in /dev/sda /dev/nvme0n1; do
    [[ -b "$dev" ]] || continue
    if smartctl -H "$dev" 2>/dev/null; then
      pass "SMART health query completed for $dev"
    else
      warn "SMART health query unavailable without privilege for $dev"
    fi
  done
else
  warn "smartctl not installed; relying on prior disk evidence until separately checked"
fi

section "GATE SUMMARY"
printf 'Critical failures: %d\nWarnings: %d\n' "$FAIL" "$WARN"
if (( FAIL > 0 )); then
  echo "RESULT=FAIL"
  exit 1
fi

echo "RESULT=PASS_WITH_REVIEW"
echo "No changes were made by this script. Review warnings and current workload before PHOENIX DEV bootstrap."

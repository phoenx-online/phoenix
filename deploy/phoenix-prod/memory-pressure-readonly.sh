#!/usr/bin/env bash
# PHOENIX P0: diagnostic snapshot only; no service, process, memory or file mutations.
set -Eeuo pipefail

if [[ "$(hostname -s)" != "craniumtek" ]]; then
  echo "PHOENIX_MEMORY_AUDIT=BLOCKED: expected Server 1 craniumtek" >&2
  exit 2
fi

echo "=== TIME / HOST / LOAD ==="
date -Is
hostname -s
uptime
printf 'Logical CPUs: '
nproc

echo "=== MEMORY / SWAP CAPACITY ==="
free -h
swapon --show --noheadings --output NAME,TYPE,SIZE,USED,PRIO || true

echo "=== MEMORY PRESSURE STALL INFORMATION ==="
for p in /proc/pressure/memory /proc/pressure/cpu /proc/pressure/io; do
  if [[ -r "$p" ]]; then
    echo "--- $p ---"
    cat "$p"
  fi
done

echo "=== LIVE SWAPPING AND RUN QUEUE (FIRST vmstat LINE IS SINCE BOOT) ==="
if command -v vmstat >/dev/null 2>&1; then
  vmstat 1 6
else
  echo "vmstat unavailable; no package installation performed"
fi

echo "=== TOP 15 RSS PROCESSES (NO COMMAND ARGUMENTS) ==="
ps -eo pid,comm,rss,pmem,pcpu --sort=-rss | head -n 16 || true

echo "=== DOCKER CONTAINER MEMORY AND CPU SNAPSHOT ==="
docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.CPUPerc}}' ||
  echo "Docker stats could not be collected"

echo "=== KERNEL OOM EVENTS LAST 24 HOURS ==="
if command -v journalctl >/dev/null 2>&1; then
  journalctl --no-pager -k --since '24 hours ago' -o short-iso 2>/dev/null |
    grep -Ei 'out of memory|oom-killer|memory cgroup out of memory|killed process' |
    tail -n 15 || true
fi

echo "PHOENIX_MEMORY_AUDIT_COMPLETED=YES"
echo "NO_SERVICES_OR_DNS_CHANGED=TRUE"

#!/bin/bash
# bob-healthcheck (bob-net, 2026-11-03). Run by bob-healthcheck.timer every ~30 s as root.
# For each Bob service: if it is failed/inactive -> reset-failed + start. If it is active but its local
# port does not answer for FAILS_MAX consecutive runs (and it has been up > GRACE s) -> restart it.
# Only read-only GET endpoints are probed (/health, /state, /login, /ready); never any drive/motion route.
# Disable: systemctl disable --now bob-healthcheck.timer      Log: journalctl -t bob-healthcheck
set -u
PATH=/usr/sbin:/usr/bin:/sbin:/bin
STATE=/run/bob-health; mkdir -p "$STATE"
GRACE=120
log() { logger -t bob-healthcheck "$*"; }

# unit | scope(system|user) | url | consecutive-fail limit
CHECKS="
bob-hmi|system|http://127.0.0.1:8080/login|4
bob-brain|system|http://127.0.0.1:8095/health|3
bob-lights|system|http://127.0.0.1:8096/state|3
bob-detect-lite|system|http://127.0.0.1:8097/health|3
bob-search|system|http://127.0.0.1:8098/health|3
bob-voice|user|http://127.0.0.1:8090/health|3
ollama|system|http://127.0.0.1:11434/api/version|3
bob-tunnel-boot|system|http://127.0.0.1:20241/ready|4
bob-funnel|system||0
"

sc() { if [ "$1" = user ]; then shift; systemctl --user -M bob@ "$@"; else shift; systemctl "$@"; fi; }

up_for() {   # seconds since the unit last became active
  local t; t=$(sc "$1" show -p ActiveEnterTimestampMonotonic --value "$2" 2>/dev/null)
  [ -z "$t" ] || [ "$t" = 0 ] && { echo 0; return; }
  local now; now=$(awk '{printf "%d", $1}' /proc/uptime)
  echo $(( now - t / 1000000 ))
}

echo "$CHECKS" | while IFS='|' read -r unit scope url max; do
  [ -z "$unit" ] && continue
  [ "$(sc "$scope" show -p LoadState --value "$unit" 2>/dev/null)" = loaded ] || continue   # not installed: skip
  sc "$scope" is-enabled -q "$unit" 2>/dev/null || [ "$(sc "$scope" is-active "$unit")" = active ] || continue
  st=$(sc "$scope" is-active "$unit" 2>/dev/null)
  f="$STATE/$unit.fails"
  if [ "$st" = inactive ] && [ "$(sc "$scope" show -p ConditionResult --value "$unit")" = no ]; then
    continue                                                   # skipped on purpose (e.g. transient bob-tunnel owns the job)
  fi
  if [ "$st" = failed ] || [ "$st" = inactive ]; then
    log "$unit is $st -> reset-failed + start"
    sc "$scope" reset-failed "$unit" 2>/dev/null
    sc "$scope" start --no-block "$unit"
    echo 0 > "$f"; continue
  fi
  [ "$st" = active ] || continue                               # activating/deactivating: leave it alone
  [ -z "$url" ] && continue
  code=$(curl -s -o /dev/null -m 8 -w '%{http_code}' "$url" 2>/dev/null)
  if [ "${code:0:1}" = 2 ] || [ "${code:0:1}" = 3 ]; then echo 0 > "$f"; continue; fi
  n=$(( $(cat "$f" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$f"
  up=$(up_for "$scope" "$unit")
  log "$unit: $url -> ${code:-none} (fail $n/$max, up ${up}s)"
  if [ "$n" -ge "$max" ] && [ "$up" -ge "$GRACE" ]; then
    log "$unit hung ($n failed probes) -> restart"
    sc "$scope" restart --no-block "$unit"
    echo 0 > "$f"
  fi
done
exit 0

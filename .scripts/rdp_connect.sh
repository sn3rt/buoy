#!/usr/bin/env bash
# rdp-launch.sh  -- robust launcher for xfreerdp3 (fixed)
set -euo pipefail

SERVER_NAME="$1"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Extract from SSH config
CONFIG_FILE="$HOME/.ssh/config"

# Use awk to find matching Host block
USER=$(awk -v host="$SERVER_NAME" '
    $1=="Host" && $2==host {inblock=1; next}
    $1=="Host" && $2!=host {inblock=0}
    inblock && $1=="User" {print $2}
' "$CONFIG_FILE")

HOST=$(awk -v host="$SERVER_NAME" '
    $1=="Host" && $2==host {inblock=1; next}
    $1=="Host" && $2!=host {inblock=0}
    inblock && $1=="HostName" {print $2}
' "$CONFIG_FILE")

if [[ -z "$USER" ]]; then
    echo "Error: Could not find User for $SERVER_NAME in $CONFIG_FILE"
    exit 1
fi

# HostName is optional in SSH config. When it is omitted, use the Host alias
# and let normal name resolution (including /etc/hosts) resolve it.
HOST="${HOST:-$SERVER_NAME}"
#XF_ARGS=(/dynamic-resolution /cert:tofu)
#XF_ARGS=(/smart-sizing /cert:tofu)
XF_ARGS=(
      /dynamic-resolution
      /cert:tofu
      /auth-pkg-list:!kerberos,!u2u
)

TMPLOG="$(mktemp --tmpdir rdp_log.XXXXXX)"
cleanup() {
  rm -f "$TMPLOG"
}
trap cleanup EXIT

XF_PID=""
PIPE_PID=""

# Start the client so it can prompt on our tty; write logs to TMPLOG.
# Start client FIRST so its early output appears in the logfile.
OPENSSL_CONF="$SCRIPT_DIR/openssl-rdp.cnf" \
  stdbuf -oL -eL xfreerdp3 /u:"$USER" /d: /v:"$HOST" "${XF_ARGS[@]}" < /dev/tty > "$TMPLOG" 2>&1 &
XF_PID=$!

# Monitor tail -> while pipeline. This is the important fixed bit:
# tail -F outputs appended lines; the while loop reads them and reacts.
tail -n +1 -F "$TMPLOG" | (
  connected=0
  while IFS= read -r line; do
    printf '%s\n' "$line"
    lower="${line,,}"
    if [[ $connected -eq 0 && "$lower" == *gdi_init_ex* ]]; then
      connected=1
      printf '>>> rdp-launch: framebuffer negotiated — detaching (grace 1s)...\n'
      # best-effort detach
      if [[ -n "${XF_PID:-}" ]]; then
        disown -h "$XF_PID" 2>/dev/null || true
        kill -CONT "$XF_PID" 2>/dev/null || true
      fi
      # small grace so the client finishes any I/O before we stop listening
      sleep 1
      exit 0
    fi
  done

  # optionally consume a tiny bit more output to avoid races
  end=$((SECONDS + 1))
  while IFS= read -r _line; do
    [[ $SECONDS -ge $end ]] && break
  done
) &
PIPE_PID=$!

# Wait for monitor to finish
wait "$PIPE_PID" 2>/dev/null || true

# Kill any tail processes following this file (cleanup)
# Find tails that reference our TMPLOG and kill them.
mapfile -t TAIL_PIDS < <(pgrep -f -- "tail -n +1 -F $TMPLOG" || true)
if (( ${#TAIL_PIDS[@]} )); then
  kill "${TAIL_PIDS[@]}" 2>/dev/null || true
fi

echo ">>> rdp-launch: finished. RDP client PID=${XF_PID:-unknown} (detached)."
exit 0

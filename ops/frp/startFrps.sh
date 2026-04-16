#!/usr/bin/env bash
set -euo pipefail

FRP_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$FRP_DIR/conf/frps.toml"
LOG="$FRP_DIR/logs/frps.log"

if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
  DEFAULT_BIN="$FRP_DIR/bin/darwin_arm64/frps"
elif [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]]; then
  DEFAULT_BIN="$FRP_DIR/bin/linux_amd64/frps"
elif [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "aarch64" ]]; then
  DEFAULT_BIN="$FRP_DIR/bin/linux_arm64/frps"
else
  DEFAULT_BIN=""
fi

FRPS_BIN="${FRPS_BIN:-$DEFAULT_BIN}"

if [[ -z "$FRPS_BIN" || ! -x "$FRPS_BIN" ]]; then
  echo "frps binary not found. Set FRPS_BIN manually."
  exit 1
fi

mkdir -p "$FRP_DIR/logs"
pkill -f "frps.*$CONF" 2>/dev/null || true
nohup "$FRPS_BIN" -c "$CONF" >> "$LOG" 2>&1 &

echo "frps started in background, log: $LOG"
echo "tailing frps log... press Ctrl+C to stop viewing log"
tail -f "$LOG"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$ROOT_DIR/backend/nginx/frps.toml"
LOG="$ROOT_DIR/logs/frps.log"
FRPS_BIN="${FRPS_BIN:-frps}"

mkdir -p "$ROOT_DIR/logs"

pkill -f "frps.*$CONF" 2>/dev/null || true
nohup "$FRPS_BIN" -c "$CONF" >> "$LOG" 2>&1 &

echo "frps started in background, log: $LOG"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$ROOT_DIR/backend/nginx/frpc.toml"
LOG="$ROOT_DIR/backend/nginx/frpc.log"
FRPC_BIN="${FRPC_BIN:-frpc}"

pkill -f "frpc.*$CONF" 2>/dev/null || true
nohup "$FRPC_BIN" -c "$CONF" >> "$LOG" 2>&1 &

echo "frpc started in background, log: $LOG"

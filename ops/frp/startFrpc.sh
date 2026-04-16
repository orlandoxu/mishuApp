#!/usr/bin/env bash
set -euo pipefail

FRP_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$FRP_DIR/conf/frpc.toml"
LOG="$FRP_DIR/logs/frpc.log"

if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
  DEFAULT_BIN="$FRP_DIR/bin/darwin_arm64/frpc"
elif [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]]; then
  DEFAULT_BIN="$FRP_DIR/bin/linux_amd64/frpc"
elif [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "aarch64" ]]; then
  DEFAULT_BIN="$FRP_DIR/bin/linux_arm64/frpc"
else
  DEFAULT_BIN=""
fi

FRPC_BIN="${FRPC_BIN:-$DEFAULT_BIN}"

if [[ -z "$FRPC_BIN" || ! -x "$FRPC_BIN" ]]; then
  echo "frpc binary not found. Set FRPC_BIN manually."
  exit 1
fi

mkdir -p "$FRP_DIR/logs"
pkill -f "frpc.*$CONF" 2>/dev/null || true
nohup "$FRPC_BIN" -c "$CONF" >> "$LOG" 2>&1 &

echo "frpc started in background, log: $LOG"

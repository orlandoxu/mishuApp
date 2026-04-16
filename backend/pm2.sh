#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
pm2 start "$(command -v bun)" --name mishu-rest --interpreter none -- rest.ts
pm2 start "$(command -v bun)" --name mishu-socket --interpreter none -- socket.ts

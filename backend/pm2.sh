#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
pm2 start "$(command -v bun)" --name mishu-backend --interpreter none -- rest.ts

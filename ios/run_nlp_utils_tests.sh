#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"

xcodebuild test \
  -workspace MishuApp.xcworkspace \
  -scheme MishuApp \
  -destination "$DESTINATION" \
  -only-testing:MishuAppTests/PersonNameDetectorTests \
  -only-testing:MishuAppTests/NaturalDateTimeDetectorTests

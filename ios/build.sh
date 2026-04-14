#!/usr/bin/env bash
set -euo pipefail

xcodegen generate
pod install
open MishuApp.xcworkspace

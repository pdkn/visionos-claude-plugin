#!/usr/bin/env bash
# post-build-log-capture.sh
# After every XcodeBuildMCP build, capture the log output and inject it
# into the Claude Code session context.
#
# This hook feeds the xcode-build-agent the evidence it needs
# without manual copy-paste.
#
# Usage: Called automatically as a post-build hook.
#
# Environment variables:
#   XCODE_BUILD_LOG_PATH  - explicit path to an .xcactivitylog or plain log
#   DERIVED_DATA_PATH     - DerivedData root (default: ~/Library/Developer/Xcode/DerivedData)
#   XCODE_LOG_MODE        - filter mode (default: auto)
#                             full     - emit the entire decompressed log
#                             errors   - emit only lines matching error/warning patterns
#                             auto     - full if log <= 200KB, errors otherwise
#   XCODE_LOG_MAX_LINES   - cap output to N lines (default: 2000)
#
# The filter and cap keep large noisy builds from blowing out the session
# context. visionOS projects with many SwiftPM dependencies routinely produce
# multi-megabyte logs; raw injection of those costs more tokens than signal.

set -euo pipefail

LOG_PATH="${XCODE_BUILD_LOG_PATH:-}"
MODE="${XCODE_LOG_MODE:-auto}"
MAX_LINES="${XCODE_LOG_MAX_LINES:-2000}"
AUTO_THRESHOLD_BYTES=204800   # 200KB

if [ -z "$LOG_PATH" ]; then
  DERIVED_DATA="${DERIVED_DATA_PATH:-$HOME/Library/Developer/Xcode/DerivedData}"
  LOG_PATH=$(find "$DERIVED_DATA" -name "*.xcactivitylog" -type f -print0 2>/dev/null \
    | xargs -0 ls -t 2>/dev/null \
    | head -1)
fi

if [ -z "$LOG_PATH" ] || [ ! -f "$LOG_PATH" ]; then
  echo "post-build-log-capture: no build log found, skipping" >&2
  exit 0
fi

# Decompress if needed.
decompress() {
  if [[ "$LOG_PATH" == *.xcactivitylog ]]; then
    gunzip -c "$LOG_PATH" 2>/dev/null || cat "$LOG_PATH"
  else
    cat "$LOG_PATH"
  fi
}

# Resolve auto mode based on raw log size.
if [ "$MODE" = "auto" ]; then
  RAW_SIZE=$(decompress | wc -c | tr -d ' ')
  if [ "$RAW_SIZE" -le "$AUTO_THRESHOLD_BYTES" ]; then
    MODE="full"
  else
    MODE="errors"
  fi
fi

emit() {
  head -n "$MAX_LINES"
}

case "$MODE" in
  full)
    decompress | emit
    ;;
  errors)
    # Match Xcode/clang/swiftc/linker error and warning lines plus a small
    # amount of surrounding context. Covers:
    #   - "error:" and "warning:" from clang/swiftc
    #   - "fatal error:" from linker
    #   - "ld: " linker errors
    #   - "Undefined symbol" and "duplicate symbol"
    #   - "Entitlement" failures
    #   - "Code Sign error" and "Provisioning" issues
    decompress \
      | grep -E -i -A 2 -B 1 \
        '(error:|warning:|fatal error:|ld: |undefined symbol|duplicate symbol|entitlement|code sign error|provisioning)' \
      | emit
    ;;
  *)
    echo "post-build-log-capture: unknown XCODE_LOG_MODE=$MODE (expected full|errors|auto)" >&2
    exit 1
    ;;
esac

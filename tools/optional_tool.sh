#!/usr/bin/env sh
# Shared helper for optional local tools that are required in CI/strict mode.
# Usage: . optional_tool.sh; require_optional_tool fish "backup fish completion smoke"

require_optional_tool() {
  tool=$1
  label=$2
  if ! command -v "$tool" >/dev/null 2>&1; then
    if [ "${BACKUP_COMPLETION_STRICT:-}" = 1 ] || [ "${PROJECT_TOOLS_OPTIONAL_STRICT:-}" = 1 ] || [ "${CI:-}" = true ]; then
      printf '%s\n' "$label failed: $tool not found" >&2
      exit 1
    fi
    printf '%s\n' "$label skipped: $tool not found"
    exit 0
  fi
}

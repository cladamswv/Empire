#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
python3 tools/static_check.py

GODOT_BIN="${GODOT_BIN:-}"
if [[ -z "$GODOT_BIN" ]]; then
  if command -v godot >/dev/null 2>&1; then GODOT_BIN="$(command -v godot)"; fi
  if [[ -z "$GODOT_BIN" ]] && command -v godot4 >/dev/null 2>&1; then GODOT_BIN="$(command -v godot4)"; fi
fi

if [[ -z "$GODOT_BIN" ]]; then
  echo "Godot executable not installed locally; static checks passed. CI will perform engine parsing."
  exit 0
fi

echo "Using Godot: $GODOT_BIN"
"$GODOT_BIN" --version

run_checked() {
  local output
  local status
  set +e
  output="$("$GODOT_BIN" "$@" 2>&1)"
  status=$?
  set -e
  printf '%s\n' "$output"
  if [[ $status -ne 0 ]]; then
    echo "ERROR: Godot exited with code $status"
    exit "$status"
  fi
  if printf '%s\n' "$output" | grep -Eiq 'SCRIPT ERROR|Parse Error|Failed to load script|Failed to create an autoload'; then
    echo "ERROR: Godot reported script/compiler errors."
    exit 1
  fi
}

run_checked --headless --editor --path "$ROOT" --quit
run_checked --headless --path "$ROOT" --quit-after 2

echo "Godot smoke test PASS"

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
"$GODOT_BIN" --headless --path . --import
for suite in tests/test_core.gd tests/test_levels.gd tests/test_save.gd tests/test_ui.gd tests/test_input.gd tests/test_acceptance.gd tests/test_native_touch.gd tests/test_settings.gd; do
  timeout 60 "$GODOT_BIN" --headless --path . --script "$suite"
done
"$GODOT_BIN" --headless --path . --quit-after 30

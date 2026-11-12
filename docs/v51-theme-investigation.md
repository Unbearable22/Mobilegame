# v0.5.1 theme investigation and acceptance

The physical Android symptom is user-confirmed on v0.5.0. A complete absence of color changes could not be reproduced on Linux with unlocked themes. No Android-only root cause is claimed.

## Findings and changes

- Native touch reaches the theme button, Settings updates its ID, the change signal reaches UIManager and palettes reach Board/Menu. v0.5.0 already changed accents on this host.
- All five backgrounds and surfaces were identical. The menu gradient, menu progress panel, gameplay root and overlay panel also had fixed colors. This was a confirmed incomplete-palette defect, not proof of the reported device-specific failure.
- Settings now owns the current palette; components consume its roles rather than selecting their own theme. Board keeps a defensive rendering snapshot, including compatibility defaults for old eight-role previews.
- All five backgrounds/surfaces/accents visibly differ. Nodes, energy, button states and menus receive named palette roles.
- A failed settings write preserves the previous ID/palette. Successful changes redraw without restarting.
- Locked choices remain locked. Their unlock condition is displayed. Debug-only `ThemeDebug` logs pointer availability, before/requested/after IDs, rejection reasons, signal reception, palette colors and updated component counts.
- Clipboard export shows `Скопировано ✓` only after reading back the same JSON. It requires no storage permission and sends no data.

## Reproducible verification

`tools/v51_capture.gd` injects actual native touch through Godot, renders all five themes on the gameplay/menu screens, checks actual framebuffer colors in background/button/node regions, and recreates the main scene from disk for every selection. A frozen Neon framebuffer is deliberately checked against other themes and must be rejected. This is scene recreation, not a physical Android process restart.

Before the fix, the first rendered test failed 11/41 checks (fixed menu backgrounds/recreation and missing clipboard confirmation). The palette contract failed 21 checks (missing roles and identical backgrounds). Revised regional checks report 71 checks per resolution.

The original 50 JSON puzzles and reaction rules are unchanged for this checkpoint. Existing statistics tests exercise attempts, restart, Undo, terminal outcomes, paused time, persistence and allowlisted JSON export.

## Physical Android checklist

1. Preserve full progress using `docs/android-progress-transfer.md` before installing a differently signed APK. Statistics JSON is not a progress backup.
2. Run `adb logcat -c`, then `adb logcat -s godot` while choosing an available theme. Record `ThemeDebug` messages. Locked themes should show their condition and log availability=false.
3. Check all available themes on the board and main menu, return via Back, close the app completely and reopen. ID and colors should persist.
4. Repeat from an in-progress reaction, with reduced effects, and after background/return. Exercise Undo/Restart and settings.
5. Export statistics, tap Copy and check the visible confirmation and pasted JSON.

The debug trace is absent in release builds. New physical-device confirmation is pending.

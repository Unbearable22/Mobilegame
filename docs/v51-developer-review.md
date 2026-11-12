# v0.5.1 independent developer review

Reviewed 2026-11-12 against working-tree changes following `dc97ce4`, independently of the implementer. Scope: theme selection/persistence/rendering/diagnostics, clipboard confirmation, debug signing workflow and APK verification. Superpowers requesting-code-review and systematic-debugging, and Godot GDScript instructions were applied.

## Findings and disposition

1. **Important — Board palette compatibility and isolation regression. Fixed and independently retested.** The initial implementation assigned the caller's dictionary directly and immediately read new mandatory roles. Existing eight-role callers caused `_draw()` to fail on missing `border`; mutation of the caller changed the board palette unexpectedly. `tests/test_board_effects.gd` reproduced both problems: exit 1, 22 passed / 1 failed plus a script error. The corrected implementation fills missing roles from catalog defaults, derives new roles for legacy callers, and owns a snapshot. Independent rerun: exit 0, **23 passed / 0 failed**.
2. **Important — gameplay outer background bypassed the palette. Fixed in source.** `UIManager._build_screen()` created a permanently fixed `ColorRect`; the original framebuffer test still passed because the board supplied enough matching pixels. The corrected implementation retains `game_background` and updates it from the active palette. Region-specific pixel assertions and fresh captures are required before accepting the final visual result.
3. **Important — modal panel bypassed palette surface/border. Fixed and independently retested.** `_build_overlay()` initially fixed its panel background to `101e33` and border to `385774`; `_apply_visuals()` did not update either. This affects Settings, Themes, Guide, chapter selection and result overlays. The corrected implementation updates the actual modal panel from palette surface/border. A fresh real OpenGL run at 720×1280 independently sampled the actual modal margin pixel after selecting Violet Pulse: it matched the Violet surface, exit 0.
4. **Minor — reinstall instructions must distinguish statistics export from full progress backup. Fixed and rechecked.** Statistics export cannot restore campaign stars, achievements and preferences. Signing documentation now links `android-progress-transfer.md` and explicitly requires complete `progress.json` backup before uninstalling an incompatible-signature APK.

## Independent checks actually run

- `python3 tests/test_android_tools.py`: **7 tests passed**.
- `CHAIN_REACT_REAL_APKSIGNER=/tmp/chain-build-tools-36/android-16/apksigner python3 tests/test_signing.py`: **8 tests passed, no skips**, including signing two APK fixtures with one certificate, wrong-password rejection, credential handling, missing/partial Secrets, and explicit ephemeral mode.
- `godot --headless --path . --script tests/test_theme_contract.gd`: **0 failures**, including failed-write rollback and all required palette roles.
- `godot --headless --path . --script tests/test_board_effects.gd`: initial failure above; corrected rerun **23 passed / 0 failed**.
- Real OpenGL/Mesa llvmpipe run at **1080×1920**, `tools/v51_capture.gd`: **41 checks / 0 failures**, five native touch selections, real menu/game images, persisted selections after scene recreation, frozen-Neon negative control, clipboard contents and visible copy confirmation. This run preceded the final region assertions/background change; it proves the tested route, not final-region coverage.
- Separate real native-touch test on a fresh save at **720×1280** tapped locked Electric Blue: pointer diagnostic reported `available:false`, selection stayed Neon, exit 0. Disabled theme touches remain diagnosable without granting locked rewards.
- An independent `tools/check.sh` invocation reached and passed all suites through Main Menu, including the **50-level / 48,242-simulation audit with 0 failures**. It was intentionally stopped to avoid duplicating the implementer's full run. This is not recorded as a completed full-suite pass.
- `git diff --check`: passed at review time.

## Signing assessment

Normal push, pull-request and default manual runs require complete stable signing configuration and fail closed if it is absent or invalid. Only an explicit manual `allow_ephemeral_signing=true` may create a nonpersistent test identity when all Secrets are absent; it cannot override partial configuration. Artifact names and public reports disclose this mode. Persistent credentials remain outside Git/artifacts and have restrictive permissions. Godot receives a placeholder password; the apksigner proxy supplies actual passwords through environment sources. APK verification compares the finished public certificate with the selected identity.

The connected integration's Actions Secrets endpoints returned HTTP 403, so stable **CI** signing remains pending owner setup. A successful opted-in temporary build does not satisfy stable-signing completion and cannot promise in-place updates to old APKs. The previous CI private key cannot be recovered from an APK.

## Limits

The user's specific v0.5.0 Android theme failure has not been reproduced on a physical device. Source investigation establishes incomplete/hardcoded palette application and the new trace makes the Android route observable; neither establishes the exact original on-device cause. No physical v0.5.1 validation, Android clipboard validation, thermal measurement, or release build is claimed. The implementer must rerun the final complete suite, all three final render resolutions and actual APK verification on the final source. All findings raised in this review have been addressed; stable CI signing and physical-device verification remain explicitly uncompleted external checks.

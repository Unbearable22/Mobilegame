# Independent developer review — Chain React v0.6

Review date: 2026-11-12. Scope: working-tree changes from `faf0d3d`, including the four new mechanics, original campaign compatibility, authored levels 51–100, save schema 4, 25-level chapters, Reactor, Daily, theme consumers and export verification changes. This review ran separately from the implementing agent. It is a source/runtime review, not a physical Android acceptance result.

## Findings and resolution

1. **Important — Daily lost accepted actions after process recreation.** The initial implementation saved a finished result only. Real reproduction: start Daily `2026-11-12` (level 40), rotate node 3, pause and recreate GameManager, reopen the same date; rotation and Undo history disappeared. Fixed with bounded persisted accepted-action checkpoints, pinned level snapshots/fingerprints, deterministic Grid replay, and independent date records. Restart explicitly clears the active checkpoint while retaining an earned result. Eight independent real-GameManager checks now pass, including date changes/rollback and recreation.
2. **Important — failed Daily writes could leave accepted but undurable actions.** The implementation now rolls back state, launch budget, Undo history and action list when checkpoint persistence fails; failed Restart leaves the current run intact. Five independent tests forced an unwritable `/proc` destination, checked failed Undo/Restart/launch and successful retry after storage recovered. The UI exposes `progress.last_error` as a save warning.
3. **Medium — malformed simulation rejection could itself raise script errors.** A valid two-node level with `active: []` reached `has_won` through `_rejected`, causing an invalid array access. Malformed node containers/items/coordinates also failed before rejection. With explicit authorization, the reviewer added regression tests and hardened only `reaction_engine_v6.gd` / `test_v6_engine.gd`: validate shape, finite coordinates, dimensions, state arrays and bounded input sizes before source access; safe outcome/initial-state helpers; atomic rejection preserves the original state and empty frames. Red run: 285 assertions passed, 6 failed, with script errors. Final run: 305 passed, 0 failed, no script errors. Core legacy suite: 21 passed. The implementing agent must independently verify these reviewer-authored changes.
4. **Medium — synchronous Daily checkpoint replay repeated on unrelated saves.** A synthetic 32 unfinished dates × 255 accepted rotations measured approximately 108 ms for sanitization and 148 ms for a save on this desktop before correction. A bounded cache now compares complete immutable checkpoint inputs and returns defensive copies; unchanged records avoid replay. Cold restore and the maximum approximately 289 KB save still cost time. These synthetic desktop timings are not phone FPS or storage guarantees.
5. **Content — unnecessary mastery route.** A mutation probe found level 79 could still be solved by its author sequence after replacing node 4 with a blocker. The author redesigned it; the repeated probe no longer finds the defect. Level 51 retains one explicit wrong-way teaching blocker: removing it does not change the winning space because an empty cell also absorbs a misplaced impulse. Treat it as a teaching/visual exception, not a mechanically essential node.

## Independently executed checks

Environment: Godot 4.7.2 official Linux debug, Compatibility renderer; rendered checks use X11/Xvfb and Mesa llvmpipe. Commands use `/tmp/chain-godot/Godot_v4.7.2-stable_linux.x86_64`.

| Check | Observed result |
|---|---|
| `tests/test_v6_engine.gd` | 305 passed, 0 failed; exact reflector mappings, bilateral portals, AND simultaneity/no latch, delay timing, caps/rollback, malformed inputs and all 50 legacy author replays |
| `tests/test_core.gd` | 21 passed, 0 failed |
| `tests/test_v6_progress.gd` | 9 passed, 0 failed at review checkpoint |
| `tests/test_v6_daily_reactor.gd` | 22 passed, 0 failed after resume/checkpoint implementation |
| `tests/test_v6_campaign.gd` | 607 passed, 0 failed after Daily changes; all 100 levels played through real GameManager, Undo/replay/Restart and 200 genuine win events |
| `tests/test_v6_visuals.gd`, real X11 renderer | 122 passed, 0 failed; 25 rendered glyphs across five themes, distinct glyphs, actual palette pixels and different earned pulse rendering |
| Python `tests.test_level_design`, `tests.test_android_tools` | 10 tests passed |
| `tools/audit_v6_intro.gd` | All levels 51–75 exhaustively completed within the stated budget; all author solutions/three-star bounds and required interactions passed |
| Independent process-recreation/date/Undo/Restart/best-result probe | 8 checks passed |
| Independent write-failure rollback/retry probe | 5 checks passed |
| `git diff --check` | Clean at review checkpoint |
| Original JSON IDs 1–50 versus `faf0d3d` | No changes |
| `tools/check_v6_redundancy.gd` | 438 real-engine witness mutations, 0 failures; ordinary nodes, sources and whole portal pairs |

The independent reproduction scripts were run under `/tmp`; durable regression coverage is in the tracked suites. Content mutations used the real Grid/ReactionEngine, not a Python reimplementation of game rules.

## Visual inspection

Real Godot screenshots at 720×1280 were inspected for the main menu, fresh Reactor and the 25-button chapter grid. Labels were readable; controls, current-level border and navigation fit without overlaps or clipping. Review-only images are `/tmp/review-v6-menu.png`, `/tmp/review-v6-reactor.png` and `/tmp/review-v6-levels.png`. Release screenshots and the full 720×1280 / 1080×1920 / 1440×3200 native-input capture reports are separate acceptance artifacts produced by the implementing agent; this review does not substitute for those runs.

## Release evidence and limitations

- The initial mastery QA commands depended on ignored `build/` helpers. This reproducibility finding is resolved by tracked `tools/check_v6_redundancy.gd`, included in `tools/check.sh`: 438 controlled witness mutations pass independently. It explicitly reports its scope as witness ablation, not exhaustive re-solving of changed puzzles; the teaching blocker in level 51 is documented. Tracked `LevelAuditor` separately proves required interactions for every enumerated win; `tests/test_level_design.py` checks typed D4 diversity. Activation alone is not represented as proof of mechanical necessity.
- Six future node types remain specification only. Future chapters/sectors cannot award progress or cosmetics; only four shipped 25-level chapters contribute sectors.
- Daily uses local offline device dates and a finite authored pool. It is not protected against system-clock changes. Finished results and unfinished checkpoints have separate bounded retention; current caps must be stated in user/test documentation.
- Automated reachability, intended-interaction checks and mutation checks do not establish human enjoyment or final difficulty fairness. New content still needs physical-phone playtesting.
- APK creation, certificate/package/permissions verification, artifact URL and SHA256 belong to the final build report. No APK or physical-device validation is claimed merely from these desktop tests.

Assessment: no unresolved important source/runtime findings remain in the reviewed changes. The reproduced engine, Daily durability and QA reproducibility defects have been corrected and retested. Source review is clear for the final automated/rendered/build gates. This is not a physical Android acceptance or a guarantee of player enjoyment. Stable Android signing/CI secret access and all build artifacts must be reported according to actual evidence.

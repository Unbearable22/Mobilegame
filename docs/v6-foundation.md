# Chain React v0.6 foundation

Runtime rules are specified in [v6-mechanics-spec.md](v6-mechanics-spec.md). Reflector, Portal, AND and Delay are implemented; Toggle, Filter, Inverter, Lock, Amplifier and Temporal remain specifications only.

## Campaign and quality admission

The shipped campaign contains 100 authored JSON puzzles. Original files/IDs 1–50 are unchanged. Visible chapters now contain 25 levels; four are playable. The catalog and Reactor reserve 20 chapters/sectors for the future 500-level target. Future content cannot unlock, complete, award cosmetics or load a puzzle. Existing ten-level achievement/theme collections retain their original criteria and descriptions use exact ranges. New 100-level/300-star milestones have new IDs.

Schema 4 migrates supported schemas 1–3 and saves exact original `.v1.bak`, `.v2.bak` or `.v3.bak` before migration. Old unlocked chapter ranges map into new chapters without losing accessible levels. Stars, achievements, preferences, statistics and last selected level persist. The full legacy campaign opens chapter III. Sector completion derives from actual 25-level completion; it never derives from a claimed unlock flag.

Every board passes schema validation, a bounded solver, three-star author replay through GameManager and complete orientation/source-order enumeration. New boards declare required nodes/events; every legal winning trace must satisfy their intended interactions. `tools/check_v6_redundancy.gd` blocks ordinary nodes, sources and portal pairs and replays the witness, detecting disposable details. This is controlled ablation of the author witness, not exhaustive re-solving of altered boards. Typed topology uniqueness under D4 transforms is a Python gate. Difficulty/interest remain human playtest questions. Level 51's blocker is an explicit wrong-way teaching decoy.

The current content generator is the authored pool. No unchecked procedural candidate enters runtime. Future generators must emit the same schema/witness/proof metadata and pass these gates, including source fingerprints, before admission. There is no runtime random-board generator or claim of 500 puzzles.

## Reactor cosmetics

The 20-segment view lights completed playable chapters. Legacy theme rewards remain earned. Completing chapter III unlocks the optional double-strand pulse, and IV unlocks the prismatic Reactor style. Selection persists. Reduced effects render static semantic states without cosmetic motion. Neither selection changes simulation.

## Daily prototype and future modes

`DailyCatalog.POOL` is a fixed pool of 20 validated authored puzzles. It chooses `SHA256(device-local YYYY-MM-DD)[0:8] modulo pool size`. It works offline and has no streak penalties or server requests. Local date can be changed by the user; this is not clock-tamper protection.

Best results are retained for at most 366 dates. Up to 32 unfinished dates retain at most 256 accepted actions each; reaching the action bound gives a visible Undo/Restart message. Each run pins a schema-validated board snapshot, its SHA256 and pool version 1. Restoration replays accepted actions through Grid/ReactionEngine, reconstructing exact Undo history. Explicit Restart clears the checkpoint; Undo updates it; date changes preserve other checkpoints. Completion atomically stores the best result and clears the active run. Daily never changes campaign completion, campaign stars, last selected campaign level or campaign statistics. Completed results survive retries, Undo and Restart.

Failed checkpoint writes roll back the affected action/Undo, and failed Restart preserves the current run. The UI reports the storage error. A bounded cache compares complete immutable checkpoint input and returns defensive copies; changed content is still validated. It avoids replaying all old actions on every save. A deliberately extreme 32×255-action fixture measured about 86ms cold validation and 31ms warm 289KB write on this desktop; this is not Android timing. Normal runs are much smaller. Storage remains synchronous, so slow/full device storage needs phone testing.

Endless Laboratory, Mastery Records and Weekly Experiments remain architecture only. A future `ChallengeDefinition` must supply a stable content ID/version, admitted level snapshot and result namespace. Campaign progression, Daily results, future mastery records and weekly experiment results must remain distinct. Endless/Weekly would use admitted authored manifests or offline-generated candidates after the same solver/quality gate. No menu entry suggests these modes are playable today.

## Android acceptance

Debug ARM64 packaging retains `org.chainreact.onetappuzzle`, portrait, Compatibility renderer, target SDK36/min24, original icon and zero requested permissions. Build tools require explicit signing configuration; CI fails closed without four owner-managed Secrets. Local builds use the durable debug identity outside Git. The integration cannot configure Secrets or dispatch Actions (HTTP403), so a locally verified APK release is provided separately; this does not establish a successful Actions artifact.

Physical v0.6 testing, Android clipboard validation, GPU/FPS/thermal measurements and human difficulty/fun acceptance remain pending. See the device checklist and verification report for executed checks.

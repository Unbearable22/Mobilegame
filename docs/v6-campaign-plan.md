> Implementation checkpoint: all 100 authored JSON files and the four runtime mechanics are now present. Tables and long-term concepts below retain their design rationale; current verification is recorded in verification.md. Daily actually uses the device-local YYYY-MM-DD date and SHA256 modulo the fixed 20-board pool, superseding the early UTC-ordinal proposal below. Resumable runs pin a validated immutable board snapshot, fingerprint and pool version.

# Chain React v0.6: staged campaign and repeat-play content plan

Status: authoring and acceptance plan. The inspected repository contains the existing 50 level JSON files; this document does not supply or certify the additional 50 playable boards. The v0.6 release target is **100 authored, verified puzzles**, within a planned capacity of 20 chapters × 25 levels = 500. Only chapters backed by shipped, validated content become available. No batch of 450 random boards, placeholder completion rewards or claims of 100 verified levels follow from this plan.

The mechanic rules and exact timing vocabulary are in [v6-mechanics-spec.md](v6-mechanics-spec.md). The content author must use those rules rather than improvise a second simulation. This plan is a concrete design proposal within the requested autonomous scope. Puzzle difficulty, action targets and onboarding effectiveness remain hypotheses until boards are authored, audited and playtested.

## Chapter structure and preservation

Keep every level ID and JSON node order for 1–50. Do not rename their completion/save keys or change source/action indices. Repackage their existing ordered content into chapters 1–2 without revising puzzle geometry. The previous five ten-level chapters remain legacy collections for existing achievement/theme milestones; they are no longer the visible campaign chapter layout.

| New chapter | Level range | Availability in the v0.6 target | Content role |
|---|---|---|---|
| 1 — Awakening | 1–25 | Shipped only after regression audit | Existing fundamentals and first battery progression, unchanged |
| 2 — Interweaving | 26–50 | Shipped only after regression audit | Existing source order, persistent charge and final legacy exams, unchanged |
| 3 — New Routes | 51–75 | Shipped only after all 25 pass audit | Reflector 51–56, Portal 57–62, AND 63–68, Delay 69–75 |
| 4 — Timing | 76–100 | Shipped only after all 25 pass audit | Combination and mastery puzzles 76–100; all four mechanics already introduced |
| 5 | 101–125 | Planned, unavailable | No content or reward entitlement yet |
| 6 | 126–150 | Planned, unavailable | No content or reward entitlement yet |
| 7 | 151–175 | Planned, unavailable | No content or reward entitlement yet |
| 8 | 176–200 | Planned, unavailable | No content or reward entitlement yet |
| 9 | 201–225 | Planned, unavailable | No content or reward entitlement yet |
| 10 | 226–250 | Planned, unavailable | No content or reward entitlement yet |
| 11 | 251–275 | Planned, unavailable | No content or reward entitlement yet |
| 12 | 276–300 | Planned, unavailable | No content or reward entitlement yet |
| 13 | 301–325 | Planned, unavailable | No content or reward entitlement yet |
| 14 | 326–350 | Planned, unavailable | No content or reward entitlement yet |
| 15 | 351–375 | Planned, unavailable | No content or reward entitlement yet |
| 16 | 376–400 | Planned, unavailable | No content or reward entitlement yet |
| 17 | 401–425 | Planned, unavailable | No content or reward entitlement yet |
| 18 | 426–450 | Planned, unavailable | No content or reward entitlement yet |
| 19 | 451–475 | Planned, unavailable | No content or reward entitlement yet |
| 20 | 476–500 | Planned, unavailable | No content or reward entitlement yet |

Compute chapter as `floor((id-1)/25)+1`; total planned chapters is 20, but playable count derives from validated shipped manifests, not `20*25`. The visible entry for future sectors/chapters reads “Planned”/“Coming later” and cannot open missing content. Completion displays use actual available totals: at the intended v0.6 milestone 100 puzzles/300 stars, not 500/1500. Finishing 100 puzzles must not mark a 500-puzzle campaign complete.

First-time progression unlocks chapter 1, then chapter `c+1` after all 25 levels of shipped chapter `c` have been completed at any star rating. Rating does not restrict access. All chapter-5-and-later entries stay unavailable even if a save claims an unlock. Preserve existing access for returning players as described below; do not force replay to recover an old accessible level.

## Migration contract

Introduce the next progress schema version (proposed version 4, after the current version 3) with a pre-migration backup and an atomic write. Accept older supported versions through the existing sanitizer path. Test actual version 1/2/3 fixtures, including partially completed campaigns, completed campaigns, existing themes and statistics. A save with unknown future version must not be overwritten as a successful migration.

1. Copy canonical `completed["1"]..completed["50"]` and their best stars without change. Preserve valid `last_level`, settings, statistics and previously awarded achievement IDs. Never treat a visible old chapter as completed content.
2. For each old unlocked chapter `c` in 1–5, map its old accessible IDs `10*(c-1)+1..10*c` into the new 25-level chapter layout, preserving access to every such ID. Union this with chapters containing completed/last-visited IDs. Examples: old chapters 1–2 map only to new 1; old chapter 3 spans levels 21–30 and preserves access to new 1 **and** new 2. Old chapter 5 maps to new 2. Old chapter visibility never grants new 3.
3. Recompute ordinary unlocks from real completions: all 1–25 unlock new chapter 2; all 26–50 unlock new chapter 3 when that chapter ships. A user who already completed all 50 therefore sees two completed sectors and chapter 3 open, with no need to replay. All first 75 completed unlock chapter 4 after its shipment. Future chapter availability is checked separately.
4. Existing theme criteria stay tied to their original level ranges: Electric Blue 1–10, Violet Pulse 11–20, Emerald Circuit 21–30, Solar Gold 1–50. Retain already earned theme/achievement entitlements. Rewrite descriptions that mention old chapters as named legacy collections or exact level ranges; changing the chapter size must not turn an earned theme off.
5. Preserve legacy achievement IDs and their old criteria. In particular, `chapter_one`, `chapter_two`, `chapter_four`, `three_chapters` and `perfect_chapter` still evaluate the original ten-level collections; `all_levels` remains the original 50-level milestone and `all_stars` the original 150-star milestone, with clear labels. Add distinct future IDs for the 100-level/300-star milestones rather than silently redefining awards already earned.
6. Store reactor unlock/claim data under its own namespace, but derive sector completion from real catalog level completions. Do not copy `unlocked_chapters` into reactor completion. Invalid completion keys beyond the shipped range do not count toward stars, sectors or rewards. Preserve Daily records separately from campaign completion IDs.

Migration must be idempotent: reading/sanitizing/writing an already migrated save yields the same entitlements and completion data. Interrupted writes leave the existing good save intact. A backup read path is useful only if it is exercised by an actual corruption test; do not claim recovery based solely on a `.tmp` filename. If downgrade import is supported later, specify it separately rather than silently dropping valid future records.

## The 50 new puzzle concepts

Every row below is a **unique authoring objective**, not a finished coordinate layout or proof. `L` is a proposed best-launch target; it must be replaced by the audited minimum and matched to the actual rating system. The exact minimum number of player actions, rotation taps and changed nodes is **pending board construction and exhaustive proof** for every row. Never publish a guessed action minimum as proven. Each introduction block progresses from a direct example through applications and a misconception check; chapter 4 combines them into larger capstones. Hints should reveal the rule before they reveal a rotation solution.

### 51–56: Reflector — entry determines the corner

| ID / working title | Unique structure and player objective | Proposed L | Required proof/interaction |
|---|---|---:|---|
| 51 — First Reflection | One source enters a single rotatable mirror from the left; turn it to reach a target above. | 1 | Reflector receives travelling right and emits up; winning without its activation impossible. |
| 52 — From Above | A top-fed corner must route downward travel to the target on the left, teaching the second slash mapping. | 1 | Exact input/output direction pair; the alternative surface misses the target. |
| 53 — Two Corners | A narrow dogleg uses two mirrors with different entry directions; configure both without a fixed-arrow substitute. | 1 | Both mirrors lie on every winning route; record two distinct direction mappings. |
| 54 — Shared Surface | A splitter sends equal-length paths into opposite sides of one mirror, which must serve two terminal targets in one batch. | 1 | Same-tick multi-input reflector produces both mapped outgoing directions once. |
| 55 — Return Visit | A reflected route has a short feedback loop and a target branch; choose the surface that reaches the branch. | 1 | The return arrival is absorbed after first activation; loop cannot bypass the branch. |
| 56 — The Wrong Shortcut | A nearby normal node appears to shorten the route but feeds a blocker; mirror routing must take an upper alcove. | 1 | No direct normal-node leak reaches the target; blocking/removing the mirror kills victory. |

### 57–62: Portal — local exits across distant rooms

| ID / working title | Unique structure and player objective | Proposed L | Required proof/interaction |
|---|---|---:|---|
| 57 — Across the Wall | A single pair bridges separated occupied cells across a blocker wall to one target. | 1 | One transport, only partner exits emit, no signal crosses empty cells as a ray. |
| 58 — Exit Shape | The distant endpoint has two exits serving different targets; use a splitter before entry without relying on entry exits. | 1 | Both partner directions matter; entry's configured exits emit nothing on one-sided use. |
| 59 — Reverse Trip | Two sources, one near each endpoint, use the pair in opposite directions over two launches. | 2 | Each launch uses the other endpoint's own exit shape; both terminal goals require their source. |
| 60 — Choose the Entrance | A routing fork can feed either endpoint; only one choice reaches the useful exit geometry. | 1 | Incorrect endpoint choice cannot accidentally activate the target through neighboring leakage. |
| 61 — Two Labels | Two differently labeled pairs cross disconnected regions without mixing their partners. | 1 | Required transports identify both pair IDs; swapping one pair would invalidate the intended route. |
| 62 — Mirror at the Exit | Portal output immediately enters a reflector whose correct surface reaches a target behind the exit. | 1 | Teleport preserves local outgoing direction for the real neighbor arrival and the mirror uses it. |

### 63–68: AND — simultaneity without memory

| ID / working title | Unique structure and player objective | Proposed L | Required proof/interaction |
|---|---|---:|---|
| 63 — Together | Equal-length paths from one splitter hit two neighbors of one AND and unlock a single target. | 1 | Two distinct predecessor nodes arrive in exactly the same tick; no battery substitute in the route. |
| 64 — Not a Battery | One short and one long branch initially arrive separately; configure an existing routing fork to equalize their lengths. | 1 | Failed timing trace versus successful same-tick trace; gate never stores first input. |
| 65 — Different Neighbors | Two path choices include a false repeated feed through one neighbor; select two genuine incoming neighbors. | 1 | Distinct `from` identities, not event count; no duplicate-edge construction in valid JSON. |
| 66 — Split After the Gate | Convergence feeds a two-exit AND shape serving two final targets. | 1 | One gate activation supplies both exits; neither target can bypass the gate. |
| 67 — Remote Agreement | One branch crosses a portal and another stays local; equalize real hop counts before AND. | 1 | Portal adds no extra teleport tick; both gate inputs have recorded identical arrival ticks. |
| 68 — Mirror Agreement | Opposite-facing mirror corners must deliver distinct same-tick gate inputs. | 1 | Both reflector mappings are required; a nearby return cannot masquerade as the second input. |

### 69–75: Delay — explicit tick alignment

| ID / working title | Unique structure and player objective | Proposed L | Required proof/interaction |
|---|---|---:|---|
| 69 — One Beat | One delay-1 node in a direct path demonstrates arrival, one-tick hold and release before a goal. | 1 | Exact input/release/neighbor timestamps and one waiting frame; delay must lie on the only route. |
| 70 — Catch Up | A shorter branch with delay 1 aligns with a longer ordinary branch at AND. | 1 | Replacing delay with a normal node breaks same-tick success. |
| 71 — Two Beats | A delay-2 branch matches a larger length difference; a tempting delay-1 branch fails. | 1 | Correct configured duration and exact gate tick; duration never adjusted through node rotation. |
| 72 — Three Beats | A delay-3 branch holds while a mirrored long route reaches the opposite gate neighbor. | 1 | Three-tick release arithmetic; no earlier half-input survives to gate activation. |
| 73 — Two Waiting Rooms | Two delay nodes on separate branches release together after different arrival ticks/durations. | 1 | Both release events join one future convergence batch; no duplicate activation from waiting hits. |
| 74 — After the Jump | A portal output enters a delay to synchronize with a local mirror branch. | 1 | Teleport display edge is excluded from timing/input counts; delayed real edge reaches the gate on schedule. |
| 75 — Waiting Loop | Feedback reaches an already waiting delay; only its original countdown may release the useful target branch. | 1 | One release despite feedback; reset-on-hit behavior would fail the golden trace. |

### 76–100: combined mastery with no new rules

| ID / working title | Unique structure and player objective | Proposed L | Required proof/interaction |
|---|---|---:|---|
| 76 — Mirror Battery | Two reflected branches, one with a fixed Delay, reach a battery at different ticks, retaining the old charge rule. | 1 | Battery receives both edge events on different ticks; mirror choice is essential to both. |
| 77 — Two Launch Angles | Two sources enter one configured mirror from different sides on separate launches, reaching different targets through a short portal route. | 2 | Both launches reactivate the mirror; source-order alternatives may be allowed if objective preserved. |
| 78 — Before the Start | A reflector and rotatable splitter must both be prepared before a portal-fed shared battery route is launched. | 1 | Required changed-node bound verified; solver cannot rotate between launches. |
| 79 — Hall of Reflections | A branched three-mirror route serves three goals with a portal branch and a returning edge that cannot reactivate its first mirror. | 1 | Every mirror contributes an indispensable output; exact trace terminates with all targets active. |
| 80 — One Crossing Only | A reflected portal exit feeds a circuit returning to its entry; target must be served in the first use. | 1 | Pair is used once; return is absorbed and cannot generate a second traversal. |
| 81 — Twin Arrivals | Equal-length source branches hit both endpoints in the same tick, feeding two AND circuits in separate exit regions. | 1 | Both transports/exit sets occur exactly once; both are necessary for the targets. |
| 82 — Charge Beyond the Wall | First launch prepares a battery beyond the portal through a Delay; the second completes it and its remote side goal. | 2 | Pair reuses across launches; battery charge persists; early side leakage cannot win in one launch. |
| 83 — Distant Exchange | Two pairs and a mirror route a split wave into three physically separate terminal pockets. | 1 | Required pair transports and mirror mapping recorded; all three pockets depend on the intended exchange. |
| 84 — Two Gates | Two separate balanced convergences, one portal-fed and one reflected, serve independent targets from one source. | 1 | Both gates activate; no success trace can skip either convergence. |
| 85 — Cascade Agreement | A first gate's output crosses a portal to one input of a later gate, with a longer bypass path supplying the other. | 1 | Required gate A before gate B; exact staged arrival equality at gate B. |
| 86 — New Launch, New Test | A first source reaches a standalone goal and one gate input; a second source must generate a complete two-input batch itself through a delayed branch. | 2 | First source's gate input is not latched; solver proves second source supplies both current inputs. |
| 87 — Convergence Exam | A portal and mirrors serve two gates and a persistent battery with different timing needs. | 2 | Gates require same tick; battery may accumulate different ticks/launches; all three are essential. |
| 88 — Charge While Waiting | An early portal-fed hit partially charges a battery; a delayed second hit finishes it later in the same launch. | 1 | Distinct tick battery hits allowed while an equivalent AND layout would fail. |
| 89 — Two Launch Clocks | A first launch charges a battery; a second launch follows a delayed path to finish it and a gate route. | 2 | Tick origin resets on the second launch; charges persist but queue/countdowns do not. |
| 90 — The Timing Bench | Three branch lengths, two fixed delays and one AND require choosing the correct routes through a splitter. | 1 | Every delay contributes; canonical winning trace records each release and final synchronized inputs. |
| 91 — The Remote Corner | Reflect a portal exit into a delayed AND input while the other branch circles a central blocker. | 1 | Mirror → portal → delay → gate sequence, including direction and tick evidence. |
| 92 — Symmetric Exchange | Simultaneous endpoint entry makes both portal exits feed separate timed convergence circuits. | 1 | Both endpoint transports and both gates required, with no hidden index-priority dependency. |
| 93 — Stored and Timed | A stored battery contribution prepares a second-launch gate route through one delay. | 2 | Battery cross-launch state helps, AND input state never persists, source order tested exhaustively. |
| 94 — Two Surfaces, One Window | A shared reflector's first simultaneous batch supplies separate portal and gate branches; a late return is useless. | 1 | Multi-output reflection is essential and once-per-launch rule is observable. |
| 95 — Far Relay | Two portal pairs separated by a delay bring a remote battery output back to a local convergence. | 2 | Pair identity, release tick and battery persistence all appear in the required trace. |
| 96 — Counterflow | Two sources reuse one portal pair in opposite directions, with different mirror entry mappings on each launch. | 2 | Different per-launch paths on the same immutable rotations; each target requires its assigned crossing. |
| 97 — Delayed Cascade | An AND cascade contains a delay between gates while a separate long branch provides its later partner input. | 1 | First AND then delay release then second AND; neither gate can be activated by early leftovers. |
| 98 — Three Pockets | A three-goal board balances portal reach, reflected corners and a delayed battery route without dispensable pieces. | 2 | All goals and all mechanic-role nodes essential under controlled removal/type substitution audits. |
| 99 — Calibration | Several plausible routing configurations win within budget, but only those respecting two synchronized gates attain the best rating. | 1 | Explicit maximum-rating witness; all best-rating wins preserve required gate/portal/delay interactions. |
| 100 — Reactor Ignition | Final four-mechanic network prepares charge, transports a split wave, reflects both branches and releases a final synchronized gate. | 2 | Full intended partial-order trace, every new mechanic indispensable, achievable best rating and complete bypass audit. |

Levels 51–56 introduce Reflector, 57–62 Portal, 63–68 AND and 69–75 Delay. Chapter 3 therefore contains all four introductions; chapter 4 revisits their interactions and escalates toward the final exam. Earlier introductions may reuse already taught types, but never require a later type. The 25 mastery rows need distinct combined geometry; if an inherited concept mentions only one new type, add an essential previously taught interaction and prove it instead of treating it as a filler repetition. If an authored puzzle cannot meet its objective inside the 8×8/current action limits, redesign the geometry, not the engine rule. Never keep a nominally unique row that is only a translated/rotated copy of another.

## Authoring artifacts and acceptance gates

Each new level needs ordinary gameplay data plus `schema_version:2`, `objective`, human-readable `hint`, `author_solution`, `par_launches` and `minimum_rotated_nodes`. Keep the existing action format: `{"type":"rotate"|"launch","index":node_index}`. All rotations occur before launches. Store exact action counts only after replaying the actual sequence. If a minimum has not been proven, use an explicit `null`/“not proven” audit value rather than 0 or the witness length.

Add machine-checkable design assertions in authoring metadata (never as hidden extra player win conditions):

```json
{
  "required_nodes": [4, 7],
  "required_events": [
    {"kind":"reflect", "node":4, "incoming_direction":1, "outgoing_direction":0},
    {"kind":"portal", "pair_id":"p1", "from":7, "to":11},
    {"kind":"and", "node":14, "minimum_distinct_neighbors":2},
    {"kind":"delay_release", "node":12, "delay_ticks":2}
  ]
}
```

The example indices are illustrative, not a playable level. Validate metadata node references/types and direction fields. Assertions can additionally carry `launch`, exact `tick`, exact predecessor sets, or `before_event`/`after_event` relation IDs when the design depends on ordering. Every relation ID must resolve, relation graphs must be acyclic, and repeated event occurrences need an explicit launch/tick selector. A portal assertion matches display `kind:"portal"` transport only; that trace must not become a gameplay hit. Delay assertions compare actual arrival/release ticks. AND assertions inspect the full real arrival batch. Reflector assertions inspect its admitted batch and resulting output.

`required_nodes` means nodes that must activate in every qualifying winning trace within the audited budget. `required_events` means predicates that every qualifying winning trace must satisfy. The author witness must satisfy both, but witness satisfaction alone is insufficient: inspect **all** wins through the declared launch budget (and separately the best-rating subset) for bypasses. A documented alternative solution may be accepted only if it still performs the intended interaction. Exact source order is constrained only when the objective actually requires it; do not reject harmless alternate orders merely to force a single answer.

A puzzle's proof artifact should contain:

- Content fingerprint, schema/engine version, validated immutable node order, audit tool version and deterministic budget values.
- Full legal author-action replay, final all-target state, launches used, rating and per-tick interaction trace. No rejected action can be skipped silently.
- Complete/incomplete search status, visited states, simulation count, observed max ticks/events; explicit minimum launches, changed nodes and rotation taps when individually proven. A solver result `budget_exceeded` is not “unsolvable.”
- A reachable best-rating witness under the real rating rule, and all required interaction checks on the relevant winning traces. A lower-rated witness cannot establish maximum-rating reachability.
- Redundancy results for each nondecorative node: controlled removal/type substitution and whether it invalidates the intended solution space. Blocker removal may make a puzzle easier, so “essential” must be evaluated against its declared route restriction. Flag unused decorative objects instead of inventing meaning for them.
- Canonical typed geometry signature under translation/quarter-turn/reflection, adjacency/branch/convergence counts and signal-timing signature. Mirrored reflector glyph and direction transforms must be included in canonicalization. No duplicate normalized board among new content; existing and new layouts also need comparison.
- Difficulty estimate based on required choices, meaningful misleading routes, launch dependencies, convergence timing and tested interaction depth; then observed playtest data. Search-space size by itself is not a player-difficulty score.

Do not add solver-only constraints to gameplay that forbid winning with an unexpected but legitimate route. Fix a broken puzzle geometry or revise its objective when proof finds a bypass. A unique witness is unnecessary; meaningful distinct choices matter more than cosmetic uniqueness. Limits or incomplete audits block publishing that candidate, even if an author can win manually. Authored replacements are the fallback when generation cannot establish quality.

Release gating is incremental: first four isolated demonstration boards, then each introduction block, then mixed boards, then the full 100-level regression/audit. A block must not be marked shipped merely because its JSON exists. Content availability should be all-or-nothing per 25-level chapter so the chapter-completion and sector criteria remain honest. Internal builds may expose smaller demonstration sets in a separate debug catalog with no campaign awards.

## Reactor Core

The Reactor Core is a progress view with 20 numbered sectors, one per planned chapter. Its source of truth is the catalog and valid per-level completion records. A sector has separate properties `content_available`, `unlocked`, `completed` and `reward_claimed`; these must not be collapsed into one active Boolean. Sector `c` is completed only when all 25 **shipped** IDs in its chapter are completed. For the 100-level release, only sectors 1–4 can complete; sectors 5–20 remain visibly planned. Completing a sector changes its visual geometry/light state and reveals the next shipped chapter.

Display available sector progress as `n/25` and chapter stars `s/75`; overall `n/100` and `s/300` follow the shipped count. Derive completed state on load to repair stale visual flags. Persist only entitlement/claim identifiers that are not derived and make claims idempotent. No runtime replay or save reload may duplicate a reward. Sector completion requires any rating, while maximum stars may provide a separate optional mastery badge.

Rewards are cosmetic themes, pulse effects, reactor appearance and achievements. Keep old theme entitlements intact and assign any new reward a stable ID plus a required shipped chapter/sector. If a reward asset or its chapter is absent, show it as future/unavailable and do not grant an empty entitlement. No paid acceleration, waiting energy or currency is introduced. Do not promise rewards for chapters 5–20 before their content/assets are implemented. Reward presentation is distinct from future content availability: an earned cosmetic must not secretly unlock a missing chapter.

## Daily Puzzle prototype

Use a small **prevalidated authored pool**, in its own ID namespace such as `daily_pool_v1/puzzle_01`; do not reuse campaign completion IDs 1–100 or inflate campaign stars. Pool inclusion requires the same schema, proof, caps and intended-interaction checks as campaign inclusion. Start with a small reviewed pool rather than claiming arbitrary daily generation. Repetition after the pool cycle is allowed and should be described honestly.

Choose an ISO date using the device's **UTC calendar date**, documented in the UI/help. Convert it to an integer day ordinal and select `positive_mod(day_ordinal + fixed_salt, pool_size)` from a stable, sorted pool manifest. The same date, pool version and game rules choose the same puzzle offline. The salt is a constant, not a secret or protection. Persist a date's first selected puzzle ID, pool version and content fingerprint before play, so a catalog update during that date cannot silently replace an in-progress challenge. Retain old pool definitions needed by existing records, or explicitly preserve/reconstruct their immutable content.

Store Daily records separately as `daily[YYYY-MM-DD] = {puzzle_id,pool_version,content_fingerprint,best_result,completed,attempt_state}`. The exact result fields may include best launches/rating and a witness; best results merge monotonically. To protect against accidental app closure, checkpoint completed player actions atomically and reconstruct through the deterministic engine; do not serialize a half-run delay queue. Persist at action acceptance, not only when the app exits. Date records are keyed by date independently of pool version to prevent accidental duplicate completion grants after an update. Daily completion may give a standalone badge, but does not complete a campaign level or reactor sector.

On date change during a run, keep the pinned puzzle/result under its original date and let the player finish. Opening the Daily screen on a later date can show that date's selected puzzle plus the retained result/unfinished record; returning to an earlier device date loads the existing record for that date. Never erase an already earned result, reset campaign progress, revoke rewards or punish the player for a missed day or clock rollback. Offline date selection does **not** prevent the user changing the system clock; make no anti-cheat claim. No streak penalty or mandatory daily reward is introduced. Future server validation would require a separate design.

Daily acceptance examples: same UTC date on two offline installs with identical manifest picks identical puzzle; one day boundary changes selection deterministically; leap days and pre-epoch ordinals use a defined positive modulo; backward clock preserves records; crash between accepted actions restores the last durable action; restarting after a win does not duplicate result/reward; catalog upgrade preserves that date's pinned puzzle; corrupt Daily data does not destroy valid campaign completion.

## Replayability architecture beyond this slice

Endless Laboratory, Mastery Records and Weekly Experiments are specification only. Reserve separate run/result namespaces, stable rule-set/content versions and shared validation/proof interfaces; do not show playable buttons backed by empty modes. Laboratory can later select only certified generator outputs and fall back to authored content when proof is incomplete. Mastery can later aggregate verified efficiency records without retroactively redefining the campaign rating. Weekly Experiments can later use a published, versioned schedule of authored rule sets; offline weekly selection has the same clock limitation as Daily. None changes current engine rules or grants rewards before implementation.

## Generator and solver boundaries

A future candidate pipeline is: choose a mechanic objective → construct geometry with a witnessed route → validate schema → replay witness → bounded exhaustive audit → interaction/bypass audit → redundancy/diversity analysis → human/playtest review → publish to an immutable manifest. Record the seed/configuration only to reproduce a candidate; determinism does not establish puzzle quality. Reject candidates with any invalid action, budget overflow, unattainable best rating, incomplete required-interaction proof or duplicate normalized layout. Fixed proof budgets and stable iteration make acceptance reproducible across machines; machine-time deadlines may stop a batch but cannot turn a partial search into proof.

The current rotation-before-first-launch rule reduces the legal search grammar to orientations followed by source sequences. Add future persistent toggle/unlock arrays to canonical state hashing only when those mechanics actually ship. Do not generate puzzles for the six specification-only types. Until the generator can meet all criteria, the release uses manually authored boards with machine-checked proofs. Fifty good new puzzles satisfy this milestone; hundreds of unverified permutations do not.

## Verification and honest release claims

Before claiming the milestone, archive a machine-readable result for every ID 1–100, full author-action replay, max-rating witness, complete/incomplete proof status and required interaction verdict. Run new node examples alone and mixed, exact same-tick arrivals, portal bilateral entry, legacy battery persistence, caps/rollback, Undo/Restart, save migration/entitlements, reactor idempotence and Daily crash/date behavior. An independent developer review must inspect actual final code/content/proofs; this planning document is not that review.

Visual evidence covers all four new glyphs, portal pair identity and transport, AND half/full feedback, Delay empty waiting ticks, reactor unavailable/partial/completed states, Daily result/resume, guide, multiple themes and normal/reduced effects. Check 720×1280, 1080×1920 and 1440×3200. Android touch and Back require their own test steps; emulator or screenshot evidence must be labeled accurately. Physical-device correctness stays unconfirmed until a real-device run is reported.

The Android handoff must contain the debug ARM64 APK link, exact SHA256, engine/build version, automated test results, content-quality report, screenshots and a concise physical-device checklist. Report theme switching stabilization, all known failures and incomplete audits explicitly. An APK build alone does not demonstrate that 100 levels are high quality or that touch works on a physical phone.

# Chain React Implementation Plan
> Execute inline using superpowers:executing-plans and test-driven-development.
Goal: playable Android-oriented 10-level Godot puzzle.
Architecture: pure deterministic engine, state/history controller, event-driven presentation.
Tech Stack: Godot 4.7.2 / GDScript / JSON.
Spec: docs/superpowers/specs/2026-11-11-chain-react-design.md
## Global Constraints
Portrait 1080×1920, 5×5, seven node types, no paid assets or live ads.
## Review Focus
Simultaneous battery hits; stale animations after restart; malformed saves; invalid levels; small viewports.
## Task 1 — model and tests
- [x] Write tests for propagation, directions, splitter, blocker, battery, cycles and deterministic frames.
- [x] Observe failures then implement ReactionEngine and GridManager; run tests.
## Task 2 — levels and validation
- [x] Create ten authored JSON levels and LevelLoader/LevelValidator with bounded exhaustive search.
- [x] Verify all levels by replaying found solutions, reject invalid/out-of-bounds data.
## Task 3 — persistence and progression
- [x] Test round-trip, corrupt saves, future versions, monotonic stars; implement SaveManager/ProgressionManager.
## Task 4 — playable UI
- [x] Implement GameManager, Board and UIManager: animation, tap, rotate, undo, restart, pause, next, level selector and sound.
- [x] Run scene integration tests, multiple viewport sizes, headless smoke and visual screenshot.
## Task 5 — review and delivery
- [x] Independent developer review, resolve findings, rerun checks, document commands and Android release limitations.

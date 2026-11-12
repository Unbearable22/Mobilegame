# v0.4: levels 19 and 49

## Result and scope

The reported physical Android logical defects could not be reproduced from the supplied description. Both existing JSON author solutions win through the actual asynchronous `GameManager.tap` path and award three stars. Exhaustive orientation/source-sequence searches found no unintended shortcut. No level JSON or global reaction rules were changed: there is no confirmed defect that would justify such a change.

This localizes the remaining report to an unknown reproduction sequence or device/build/input/presentation behavior; it does **not** establish an Android cause or claim physical-device verification. The user did not provide the failing tap sequence, expected/actual node, APK version, or recording. Collect those details before claiming a fix. In particular, capture all pre-launch rotations, source order, the wave where behavior differs, and whether Undo/Restart was used. A short screen recording showing those actions and the APK version is sufficient to start a precise comparison.

Evidence was generated using Godot `4.7.2.stable.official.ed1daf0bf`. [The JSON report](v4-level-diagnostics.json) contains the full state after **every** author action, every emitted asynchronous frame, every energy edge and its checked direction, new targets, battery charge transitions, existing solver results at each launch budget, the existing exhaustive audit, and a separate enumeration of every winning orientation/sequence. Indices below are zero based; coordinates are `(x,y)` with y increasing downward. Directions are up/right/down/left = 0/1/2/3.

## Level 19: Общий выход

Author preparation rotates nodes 1 `(0,1)`, 4 `(4,3)`, and 8 `(2,2)` clockwise once. The first two then point right and left respectively; splitter 8 points up/down. The fixed ingress nodes 6 and 7 point inward.

| Author action | Changed orientation | Used launches | Active targets after action |
| --- | --- | --- | --- |
| Rotate 1 | up → right | 0 | none |
| Rotate 4 | down → left | 0 | none |
| Rotate 8 | left/right → up/down | 0 | none |
| Launch 0 | unchanged | 1 | 2, 9, 10 |
| Launch 3 | unchanged | 2 | 2, 5, 9, 10; win, 3 stars |

Actual first-launch waves: `0 → {1,6}`, then `1 → 2` and `6 → 8`, then `8 → {9,10}`. The first branch delivers right to target 2; the inward route delivers right into the shared splitter, which delivers up/down to targets 9/10.

Actual second-launch waves: `3 → {4,7}`, then `4 → 5` and `7 → 8`, then `8 → {9,10}`. The branch delivers left to target 5; the inward route delivers left into the same splitter. The shared targets remain active and can receive another wave. No previous activation prevents the splitter from emitting in a later launch.

This matches `objective`: the two sources share one configured junction, and each has a separate target. It does not require a unique source order. Both source orders are valid. The hint's shared exit is traversed by both launches; shared targets persist after the first launch.

Exhaustive result: **64 orientations, 384 simulations, 4 winning paths**, minimum **2 launches and 3 rotated nodes**. Every winner has rotation offsets `1=1`, `4=1`; splitter `8=1` or `8=3`; source sequence `[0,3]` or `[3,0]`. The two splitter orientations have identical up/down output sets because its opposite arms are symmetric. These are justified equivalent solutions, not bypasses. Repeating one source cannot reach the other source's private target. All 11 nodes activate in every win. Existing solver with budget 1 exhausts 64 states without a win; budget 2 finds the author solution (65 visited states).

## Level 49: Разделённый горизонт

Author preparation rotates nodes 2, 4, 7, 10, and 13 clockwise once, before any launch. Resulting exits are: 2 up, 4 up, splitter 7 up/right, 10 down, 13 right. Fixed nodes 8 and 12 remain right. The source is node 5 `(0,2)` and is launched three times.

| Author action | Used launches | Battery 6 / battery 9 | Active targets after action |
| --- | --- | --- | --- |
| Rotate 2 | 0 | 0 / 0 | none |
| Rotate 4 | 0 | 0 / 0 | none |
| Rotate 7 | 0 | 0 / 0 | none |
| Rotate 10 | 0 | 0 / 0 | none |
| Rotate 13 | 0 | 0 / 0 | none |
| Launch 5 | 1 | 1 / 0 | none |
| Launch 5 | 2 | 2 / 1 | 0, 3, 15 |
| Launch 5 | 3 | 2 / 2 | 0, 1, 3, 15; win, 3 stars |

Launch 1 only sends right `5 → 6`. Battery 6 stores one hit and does not emit.

Launch 2 charges battery 6 to two at wave 1. At wave 2 it emits to node 2 above, splitter 7 right, node 10 below, and source 5 left; source 5 ignores incoming energy. At wave 3, `2 → 0` and `7 → 3` activate the upper targets, `7 → 8` advances the far branch, and `10 → 12` enters the lower bypass. At wave 4, `8 → 9` gives battery 9 its first charge while `12 → 13` advances the bypass. Then `13 → 14 → 15` reaches the bottom target at wave 6. Normal node 14 also sends up into blocker 11 and left back into already emitted node 13; neither forwards another pulse. Battery 9 and upper branch node 4 remain inactive.

Launch 3 reuses the now-charged battery 6. At wave 4, `8 → 9` brings battery 9 to two charges; it then emits up to 4 and left to already emitted node 8. At wave 6, `4 → 1` activates the last upper-right target. The lower branch also runs again. Blocker 11 never activates. Battery charges are capped at two, and an emitter runs at most once per launch; activation persists across launches. These are existing documented rules, not changes for these levels.

This matches both `objective` and the author solution: prepare the top targets and lower bypass, then finish the far battery. Batteries emit orthogonally toward occupied adjacent cells; directional arrows govern outgoing energy rather than incoming connections. Static adjacency links drawn by the board are a map of neighboring nodes, not a promise that every linked pair conducts in both directions. All actual frame edges were checked against the visible node coordinates and rotated exits.

Exhaustive result: **1,024 orientations, 3,072 simulations, exactly 1 winning path**, minimum **3 launches and 5 rotated nodes**. All five rotatables must have offset 1 and the source sequence must be `[5,5,5]`. Every non-blocker activates in that win; removing any required rotation loses. The existing solver exhausts budgets 1 (1,024 states) and 2 (2,048 states) without a win and finds the author solution at budget 3 (1,026 states). There is no upper-only, lower-only, skipped-battery, or fewer-launch winning alternative.

## Regression evidence

`tests/test_level_regressions.gd`: **300 assertions passed, 0 failed**. It exercises both levels through a real asynchronous `GameManager`, checks all important node states, target wave order, battery thresholds, every edge against actual coordinates/exits, busy input suppression, three-star events and persisted ratings, every Undo snapshot, Undo after winning and replay, Restart, Restart during a pending reaction, author replay after Restart, exhaustive alternatives, existing solver minimums, and deliberate omission of each required rotation.

`tests/test_levels.gd`: **159 passed, 0 failed**; all **50** schemas and solver solutions replay successfully.

`tests/test_level_audit.gd`: **50 levels, 48,242 simulations, 0 failures**; all existing author solutions and design bounds pass exhaustive auditing.

Reproduce from the repository root (substitute the installed Godot executable):

```sh
godot --headless --path . --import
godot --headless --path . --script res://tools/diagnose_levels.gd
godot --headless --path . --script res://tests/test_level_regressions.gd
godot --headless --path . --script res://tests/test_levels.gd
godot --headless --path . --script res://tests/test_level_audit.gd
```

Both integration runners use temporary test save paths and remove them after execution. They do not edit the player's normal progress file. The JSON report is regenerated by `tools/diagnose_levels.gd`; it is evidence from runtime signals rather than a hand-written expected outcome.

## Уточнение пользователя: лишний второй старт

После уточнения «в49, возможно, лишний второй старт» дополнительно проверены фактические источники и удаление каждого нецелевого узла по одному с переиндексацией авторских действий: `tools/check_level_redundancy.gd`, exit0, [полные результаты](v4-node-necessity.json).

- В49 **ровно один source**: узел5, координаты(0,2), слева от первой батареи. Все три старта — повторные запуски одного источника, не три отдельных источника. Второй/третий запуски обязательны по исчерпывающему поиску; это не лишнее действие.
- Удаление любого проводящего узла, обеих батарей или единственного источника ломает авторский путь. Нижний маршрут нужен для цели15.
- Блокер11(3,3), нарисованный крестиком, **не обязателен для достижимости победы**: пустая клетка также остановит импульс, и авторское решение остаётся рабочим. Он явно показывает тупик под неподвижной стрелкой8. Это визуальный/дизайнерский элемент, а не второй старт; он сохранён вместе с семью типами узлов главыV. Нельзя утверждать, что все16узлов49 логически незаменимы.
- В19 источниковдва(0и3); удаление любого делает авторское решение непобедным. Входы6и7 к общей развилке **по отдельности необязательны**: один оставшийся маршрут зажигает общие цели, а отдельные боковые цели всё равно требуют оба источника. Это симметричное перекрытие маршрутов, а не лишний источник. Оно согласуется с тем, что порядок источников не фиксирован.

Аblation проверяет сохранённое авторское решение после удаления узла, а не доказывает незаменимость элемента для всех возможных новых решений. Полный поиск вариантов исходных неизменённых уровней описан выше. По уточнению пользователя удалять элементы без подтверждённой ошибки не требовалось; JSON сохранены.

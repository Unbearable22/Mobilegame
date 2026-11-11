# Chapters IV–V: authored circuit design

These twenty boards were laid out individually as circuits, then blockout-tested against the existing emission rules. They are not generated layouts or rotated copies of earlier boards. Coordinates below are zero-based `(x,y)`. All boards fit within 5×5; most have empty rows/columns to preserve touch spacing. No rule changes are required.

The design metric is **distinct nodes whose orientation must differ from reset**, not number of taps: a 180° turn counts as one changed node. Rotations are locked after the first launch. Every level includes an explicit objective, a replayable author solution, its proved minimum changed-node count, and an optimal launch par for three stars.

IV alternates compact counterintuitive routing with harder single-launch convergence. Levels 33, 36, and 39 deliberately allow alternative source choices and serve as rests before larger loops. V requires every one of the seven node types on every board; staged batteries, source choice, normal-node fan-out, and splitters interact rather than appearing as an isolated mechanic tutorial. Level 46 has a spare launch, with two required for three stars. Other boards use their optimal launch budget.

## IV — Paradox, 31–40

| Level | Authored goal / critical path | Tempting wrong route | Par | Minimum changed nodes |
|---|---|---|---:|---:|
| 31 · Два коротких обхода | The lower corner forks into two adjacent sides of battery `(2,2)`. Both small elbows must point inward; one launch lights the target above it. | Point an elbow toward the visible target column. A single battery contact gives no output. | 1 | 3 |
| 32 · В обход стены | A vertical fork at `(1,1)` goes above and below the blocker at `(2,1)`. The unequal-looking arms return into battery `(3,1)` and release the right target. | Follow the horizontal source-to-target line into the wall, or complete only the shorter-looking arm. | 1 | 5 |
| 33 · Встречные старты | Two perpendicular approaches share battery `(2,2)`. The authored replay launches the left and then lower source; its output reaches an adjacent target and an upward corner target. Repeating the left source is an intentional valid alternative. | Treat the first quiet battery contact as a failed route, or point its right exit directly right instead of upward. | 2 | 2 |
| 34 · Уступить батарее | Repeat the lower-left route to charge the battery, then use a corner splitter to retain both the upper and right targets. | Point the last splitter at only the closest target. Both targets must remain connected in the fixed setup. | 2 | 3 |
| 35 · Два долга | A horizontal fork charges two separated batteries once per launch. Their exits have different target geometry: left goes upward, right turns outward. | Aim the fork at the central blocker or assume the two upper exits need identical orientations. | 2 | 3 |
| 36 · Источник не мост | The left source reaches a fork, an upper target arm, and an outside approach to the right battery. The inner upper cell is another source, which absorbs incoming edges. Multiple source sequences and reverse routing remain valid. | Treat the second source as a normal wire that forwards a received signal. The visible inside shortcut stops there. | 2 | 2 |
| 37 · Позднее эхо | A short upper arm reaches the battery before a longer right loop. The lower/right loop completes its second contact in the same launch. | Rotate only the short arm because it is visibly close to the target. Its first battery hit is deliberately silent. | 1 | 5 |
| 38 · Цель за спиной | The lower fork directly touches battery `(1,2)` and sends a second path up into a return splitter at `(2,2)`. That splitter points left into the battery and up toward the right target; the battery separately feeds the target behind the start. | Turn the return splitter only toward the right-hand target. That strands the battery and its left target. | 1 | 4 |
| 39 · Три контакта | Three selectable sources surround a central battery and normal node. The authored route uses left and lower sources; the upper corner exits and battery's direct upper target must all be reached. Right-source alternatives are allowed. | Assume the nearest source is the only useful source, or align both corner exits inward toward the central target. | 2 | 2 |
| 40 · Парадокс центра | A vertical fork travels up into a corner splitter and down around a wall. The long lower arc returns from the right into the battery while the corner splitter also preserves the left target. | Turn the lower fork horizontally into the central wall or point the upper splitter at just one of its two responsibilities. | 1 | 5 |

## V — Singularity, 41–50

All seven types are present in each level: source, normal, directional, splitter, blocker, battery, and target.

| Level | Authored goal / critical path | Tempting wrong route | Par | Minimum changed nodes |
|---|---|---|---:|---:|
| 41 · Первая сингулярность | Two batteries in series: launch one stores the first charge, launch two wakes the first battery and touches the second, launch three wakes the second. The intermediate splitter also owns a separate target. | Aim the intermediate exit only toward the visible upper target. The second battery and lower normal-node branch still need their input. | 3 | 3 |
| 42 · Общее прошлое | Adjacent batteries can exchange a hit, but two launches require the lower corner fork to prepare both lanes. The authored replay uses the left and lower sources; the two upper exits and right normal branch all end in targets. | Use only a straight repeated charge into the left battery. Serial charging needs a third launch, which is unavailable. | 2 | 4 |
| 43 · После развилки | A bottom fork prepares two batteries in parallel. After the second launch the left exit reaches a near target; the right exit reaches a normal node that turns into the far corner target. | Copy the left-side orientation onto the right side or point the lower arrows outward along the fork rather than upward. | 2 | 5 |
| 44 · Вложенный заряд | A stepped route charges the lower-left battery, then the upper battery on the following launch. Its upper corner splitter retains two targets; the fixed right branch reaches a normal node and the third target. | Rotate the corner only toward the upper target. The adjacent side target stops forwarding and cannot be recovered through the outer normal branch. | 3 | 3 |
| 45 · Две памяти | Two lower batteries need two launches. Both upper arms then converge on a third battery in that same second launch. A lower normal branch preserves a separate target. | Aim either upper arm at open space, or sacrifice one lower battery because the other side already reaches the upper area. The third battery needs both. | 2 | 5 |
| 46 · Лишний путь | The left corner fork prepares both separated batteries; the right source prepares only its near side. Repeating the left source wins in two launches, while a mixed three-launch route is allowed with fewer stars. | Repeatedly choose the source closest to the right target. It cannot charge the left battery. | 2 of 3 | 4 |
| 47 · Нижняя орбита | The first battery wakes on launch two. Its output goes through an upper target splitter, a normal branch, and a lower perimeter loop. The normal branch and perimeter loop give the far battery both hits in that same launch; the far battery owns an otherwise unreachable lower-right target. | Stop when the normal branch lights the upper-right target. Its single contact alone cannot wake the far battery before the launch budget expires. | 2 | 5 |
| 48 · Двойное возвращение | An offset left source and bottom fork feed adjacent batteries through different approaches. The lower fork must preserve both lanes; each upper corner and the right normal fan-out ends at a target. | Use the fork vertically or feed only one battery twice. In two launches the neighboring battery cannot accumulate enough charge without the second approach. | 2 | 5 |
| 49 · Разделённый горизонт | The first battery fans into an upper target, a splitter-owned middle target, a long bottom route through a normal node, and a far serial battery. The far battery opens its own upper target on launch three. | Point the middle splitter solely at the far battery or omit the bottom arc after the upper targets light. The middle and lower targets are independent terminal branches. | 3 | 5 |
| 50 · Последний экзамен | The starting fork prepares two lower batteries. On launch two, both batteries feed outside target routes and two inward corners that jointly charge the third battery. The third battery alone owns the center target. The left normal node fans back into the inward lane, so incoming direction and emitted direction must be understood separately. | Aim the start upward into the blocker, turn either outside corner toward the center too early, or assume that one side can charge the final battery alone. All six rotatable nodes must change orientation. | 2 | 6 |

The final board uses three essential batteries, three splitters, directional elbows, a normal-node fan-out, and blockers in a single fixed pre-launch setup. It combines the battery timing lesson from 41/44, parallel preparation from 43, convergence from 45, and perimeter routing from 47. Its center target cannot be reached through either outside target, because targets do not emit.

## Exhaustive validation

Godot 4.7.2 ran the real `ReactionEngine`, `GridManager`, `LevelValidator`, and `LevelAuditor` for levels 31–50. The probe lived outside the repository at `/tmp/probe_iv_v.gd`; its machine-readable results are `/tmp/iv_v_godot_proof.json` for this session.

The audit enumerated all **14,720 orientation assignments** and every legal source sequence up to each board's launch budget, making **42,302 real-engine simulations**. It completed without a search limit. Every schema passed; every author action sequence was accepted and won at its three-star par. The exact observed minima matched every `minimum_rotated_nodes` and `par_launches` value. Consequently, no level has a zero-rotation win or a win with fewer changed nodes than advertised. No board asserts a required source order; the alternative winning source sequences are intentional.

| Levels | Real-engine simulations | Winning orientation/terminal-sequence combinations |
|---|---:|---:|
| 31–40 | 8,640 | 57 |
| 41–50 | 33,662 | 29 |
| Total | 42,302 | 86 |

The independent Python blockout model also searched every orientation and agreed with all minima. The Godot results are the authoritative completion check. Multiple winning configurations are accepted when they preserve the circuit's actual requirements; metadata makes no uniqueness claim.

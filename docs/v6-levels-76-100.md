# v0.6 — authored mastery levels 76–100

These 25 boards extend the campaign with deliberately placed routes, witnessed solutions and bounded proofs through the actual expanded Godot engine. They are authored puzzles, not randomly sampled boards or rotations of an existing template. Numerical difficulty ratings remain design hypotheses until human playtesting.

## Verified scope

- **25 / 25** author solutions won through `GameManager`, awarded three stars and settled without a busy/paused remainder. This uses actual loading, GridManager transactions, statistics/progression and the production engine, with presentation duration set to zero for deterministic automated replay.
- Complete orientation/source-sequence enumeration through `scripts/core/reaction_engine_v6.gd`: **2,444 launch simulations, 74 winning traces, zero failed design predicates**. Every winning trace within each declared launch budget activates its required nodes and satisfies its required events. Search cap was 500,000 simulations per board; no board approached it.
- All best-rating launch counts and minimum changed-node/rotation-tap counts were proven by enumeration. The largest board has 21 nodes; there are at most four rotatable nodes, two sources and two required launches. Level 99 permits two launches but its witnessed three-star solution uses one.
- **248** ordinary-node substitutions with a blocker made the author solution fail; no non-source/non-target/non-portal node is dispensable to that witness. Separately, **29** source-removal cases and **17** paired-portal-removal cases made the remaining author actions fail.
- Mastery occupied-cell geometry was compared with all 100 boards under translation, quarter turns and reflection: **zero equivalent layouts**. This is a conservative geometry check that ignores node types; distinct geometry alone does not establish interesting play.
- No physical Android test or human difficulty/fun assessment is claimed here.

The blocker/source/pair mutations replay the author witness; they are not an exhaustive re-solve of every mutated board. The exhaustive bypass proof applies to the original boards and all their legal winning traces. Substituting an omnidirectional relay for a reflector is not claimed impossible: it changes the game rule and is a separate mechanic-ablation experiment. Delay duration is essential to convergence in timing boards; boards 85 and 96 also use visible delayed/stored arrival sequences without asserting that replacing Delay with an ordinary relay makes them unsolvable.

## Per-level intent and evidence

`L` is the proven minimum launches and three-star norm. `R` is the proven minimum number of changed nodes. `Actions` is the complete author witness length, including rotation taps and source launches. `Ticks` gives the final tick of each launch; tick zero is its selected source. The exact indexed witness and machine-readable interaction predicates are in the corresponding JSON. Multiple mirror-equivalent orientations and harmless source orders are legal where they retain the intended interaction.

| ID | Name / intended decision | L | R | Actions | Ticks | Winning traces |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| 76 | **Зеркальное согласие** — Сведите две зеркальные дуги в один одновременный вход AND. | 1 | 3 | 4 | 6 | 4 |
| 77 | **Двойное согласие** — Одним запуском замкните два независимых контура AND. | 1 | 2 | 3 | 5 | 4 |
| 78 | **Каскад согласий** — Откройте первый AND, затем разделите его выход для второго. | 1 | 2 | 3 | 9 | 4 |
| 79 | **Без памяти** — Каждый источник нужен своей цели; AND требует свежую пару в одном запуске. | 2 | 2 | 4 | 2, 6 | 8 |
| 80 | **Хранимое согласие** — Дважды синхронизируйте удалённую и местную ветви, чтобы зарядить батарею после AND. | 2 | 3 | 5 | 8, 9 | 2 |
| 81 | **Короткая дорога** — Добавьте два такта к короткому плечу, чтобы встретить длинный обход у AND. | 1 | 2 | 3 | 7 | 1 |
| 82 | **Не сбивайте отсчёт** — Поздний обратный вход не должен перезапустить уже ожидающий Delay; активируйте обе цели. | 1 | 2 | 3 | 7 | 1 |
| 83 | **Три часа** — Согласуйте сумму задержек 1+2 с одним ожиданием в три такта. | 1 | 2 | 3 | 9 | 1 |
| 84 | **После скачка** — Учитывайте нулевую добавочную длительность телепортации и выровняйте ветви задержкой. | 1 | 2 | 3 | 8 | 1 |
| 85 | **Два разных момента** — Зарядите батарею ранним и поздним импульсом в одном запуске. | 1 | 3 | 4 | 8 | 4 |
| 86 | **Обмен навстречу** — Подайте импульсы в оба конца одной пары в один такт: оба выхода нужны AND. | 1 | 2 | 3 | 6 | 4 |
| 87 | **Две удалённые руки** — Две разные пары порталов должны дать AND двух настоящих соседей одновременно. | 1 | 2 | 3 | 4 | 1 |
| 88 | **Второе окно** — Первый AND запускает задержку; второй встречает её с длинным обходом. | 1 | 3 | 4 | 10 | 2 |
| 89 | **Противоток** — Одна пара работает в обе стороны на разных запусках: каждый источник ведёт к своей цели. | 2 | 2 | 4 | 3, 5 | 8 |
| 90 | **Две памяти, одно окно** — Зарядите две батареи за два запуска; их разные пути должны прийти к AND вместе. | 2 | 2 | 4 | 4, 8 | 1 |
| 91 | **Удалённый угол** — Зеркало, портал и Delay должны доставить короткую ветвь к длинному пути у AND. | 1 | 1 | 2 | 8 | 2 |
| 92 | **Двойной обмен** — Оба направления одного обмена питают два независимых синхронных AND. | 1 | 3 | 4 | 6 | 8 |
| 93 | **Сначала запас** — Сначала подготовьте батарею верхним источником; нижний должен дать AND полную пару. | 2 | 2 | 4 | 1, 5 | 1 |
| 94 | **Одна поверхность** — Два одновременных входа одного зеркала должны породить два разных выхода к двум портальным маршрутам. | 1 | 3 | 4 | 7 | 1 |
| 95 | **Дальний ретранслятор** — Две последовательные пары и задержка должны синхронизировать заряд батареи с местной ветвью. | 2 | 2 | 4 | 7, 8 | 1 |
| 96 | **Обмен и запас** — Первый источник заряжает дальнюю батарею двумя путями; обратный обмен завершает вторую. | 2 | 2 | 4 | 6, 5 | 4 |
| 97 | **Каскад через расстояние** — После первого AND задержанный сигнал встречает обход, прошедший через портал и другое ожидание. | 1 | 4 | 5 | 10 | 2 |
| 98 | **Три кармана** — Два запуска питают удалённую батарею и синхронный выход к двум другим целям. | 2 | 3 | 5 | 10, 10 | 4 |
| 99 | **Калибровка окон** — Один двусторонний обмен должен открыть два разных временных окна AND. | 1 | 4 | 5 | 8 | 4 |
| 100 | **Зажигание реактора** — Синхронизируйте первый AND, накопите заряд в двух батареях и откройте финальное окно второго AND. | 2 | 4 | 6 | 9, 14 | 1 |

## Pacing and intended interactions

76–80 recap same-tick agreement, independent gates, gate cascades and fresh-versus-stored inputs. Board 79 explicitly preserves a first source's one-input AND demonstration while making its splitter necessary to its own target; the second source must still form a full current batch. Board 80 joins all four new types with a two-launch battery after a synchronized gate.

81–87 provide shorter timing and transport exercises between larger networks. Board 82 is a waiting-node feedback test: its left Delay receives a late third-tick hit while already waiting, still releases at tick 4, and meets the other branch at AND tick 6. A countdown that restarted on the late hit would miss the window. Board 83 balances distributed delays 1+2 against delay 3. Board 85 distinguishes battery accumulation across different ticks from AND simultaneity. Board 86 requires both same-tick directions of one portal exchange; board 87 uses separate portal pairs in parallel.

88–94 combine distinct reasoning tasks. Board 88 stages a gate, delay and later gate against a longer bypass. Board 89 uses one portal pair in opposite directions on separate launches; both sources and both mirror exits are required. Board 90 aligns two persistent batteries at a gate. Board 91 reduces the rotation burden while retaining a complete mirror→portal→delay→gate route. Board 92 uses a bilateral portal exchange to feed two independent ANDs. Board 93 proves the strict source order A then B; B then A and repeated sources cannot complete both goals in budget. Board 94 requires two simultaneous inputs to the same reflector to yield two outputs at tick 3, each serving its own portal route.

95–100 increase composition depth. Board 95 chains two portal pairs around a delay before a stored battery/gate convergence. Board 96 uses counterflow and local precharging with two necessary sources. Board 97 carries a delayed gate cascade around a portal bypass with a separately timed wait. Board 98 divides the goal into three spatial pockets: two from a timed gate output and one from a persistent remote battery. Board 99 opens two different timed AND windows after a symmetric portal exchange and requires four changed nodes for the one-launch maximum rating.

## Final board 100

The final board has **21 nodes**, four changed-node choices, all four new mechanics, two AND stages, two persistent batteries and one source used twice. The first launch prepares both batteries; the second must reproduce the first synchronized gate and then align the two battery outputs through different routes.

The exact trace is part of `required_events`:

1. Both source branches pass their delay-2 nodes and reach the first AND at **tick 8** in **each** launch. The upper route requires a reflected portal entry; the lower route requires a reflected local corner.
2. Both batteries receive their first hit at tick 9 in launch one. The trace ends at tick 9 with partial charges and no victory.
3. In launch two both batteries activate at tick 9. One output enters a delay-2 node at tick 10 and releases at **tick 12**. The other follows a reflected longer path.
4. The second AND receives both distinct real neighbors at **tick 13** of launch two and reaches the target at tick 14.

Exhaustive search found one winning orientation/source sequence out of 512 launch simulations. All nine generic mechanic predicates plus the additional exact launch/tick predicates are necessary in every winning trace. Each ordinary node, source and portal pair also passed the separate author-witness removal/substitution check. This is an automated composition/difficulty argument, not a claim that the board has been found enjoyable or fairly difficult by phone playtesters.

## Reproduction and artifacts

Authoring and auxiliary probes are deliberately kept under ignored `build/`; the deliverable is the immutable JSON and this report. Final source-wide checks must use the committed production validator/auditor as well. During authoring, the following actual Godot commands produced the reported results:

```bash
GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 bash tools/check.sh
python3 tests/test_level_design.py
# Individual reproducible gates:
godot --headless --path . --script tests/test_level_audit.gd
godot --headless --path . --script tests/test_v6_campaign.gd
godot --headless --path . --script tools/check_v6_redundancy.gd
```

Historical authoring-only reports (not required by these tracked gates): `build/v6-mastery-audit.json`, `build/v6-mastery-mutations.json`, `build/v6-mastery-special-mutations.json` and `build/v6-mastery-diversity.json`. Each source JSON contains its legal author solution, source/node identity mapping, minimum rotation bound, design goal, difficulty estimate/status, required node set and expected interaction events. These QA predicates do not add hidden win conditions to gameplay. The runtime win condition remains activation of all targets.

The first exhaustive pass detected and prompted redesign of an optional leg in 79, a direct-target shortcut from a rotated delay in 91, and a redundant second source in 96. Cross-campaign geometry comparison also prompted replacement of duplicate occupied layouts in 85/86/90. Final proof reports contain no unresolved instance of these defects.

Visual size, touch targets, rendered node readability, guide consistency and final Android packaging are integrated acceptance checks performed by the main implementation, not established by these headless content tests. The larger board 88 is 6×8 and needs particular attention at 720×1280; its node count is 20. No new hint system, ads, purchases, network data collection or future-only mechanic is included.

The tracked ablation gate covers all 50 new boards: **438 mutations, zero failures**, emitting `build/v6-redundancy.json`. It is part of CI through `tools/check.sh`. Typed D4 uniqueness for all 100 is checked by the tracked Python test.

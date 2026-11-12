# Authored v0.6 introduction: levels 51–75

All 25 layouts are hand-authored. JSON preserves original level fields and adds `schema_version: 2`, design intent, a playable action witness and required interaction evidence. The teaching order is Reflector 51–56, Portal 57–62, AND 63–68, Delay 69–75. Combinations reinforce earlier lessons. Difficulty values are design hypotheses, pending human playtesting.

`tools/audit_v6_intro.gd` replays every author witness through `scripts/core/reaction_engine_v6.gd`, then exhaustively explores all four orientations of each rotatable node and every legal source sequence up to the launch budget. Rotations occur only before launches. Every winning trace must activate every declared required node and contain every required event. Both sources are therefore necessary in levels 60, 68 and 75; levels 68 and 75 also prove source order. All searches completed within the 500,000-call bound.

Each board has at most 13 nodes, four rotatable nodes, two sources and three launches. The occupied-cell layouts of these 25 levels are all different under translation, rotation and reflection, even when node types and arrows are ignored. Portal pairs contain exactly two fixed endpoints. AND evidence counts distinct neighbors in one tick. Delay evidence records real engine release events.

Run the authored-content audit:

```bash
godot --headless --path . --script tools/audit_v6_intro.gd
```

The machine report is `build/v6-intro-audit.json`. The following numbers come from a completed Godot 4.7.2 audit. Rotation minima count changed nodes; tap minima are separately enumerated. Equivalent mirror parities can yield multiple winning orientations.

| ID | Puzzle | Design beat | Par launches | Minimum changed nodes | Minimum taps | Last author tick per launch |
| --- | --- | --- | ---: | ---: | ---: | --- |
| 51 | Первое отражение | Освоить зависимость выхода зеркала от направления входящего импульса. | 1 | 1 | 1 | 2 |
| 52 | Два колена | Прочитать два последовательных зеркальных поворота с разными входами. | 1 | 2 | 2 | 5 |
| 53 | Разные стороны | Сопоставить противоположные входящие направления при одинаковом желаемом выходе. | 1 | 1 | 1 | 3 |
| 54 | Карман под развилкой | Сохранить прямую цель и провести отдельную ветвь вокруг нижнего кармана. | 1 | 2 | 2 | 5 |
| 55 | Зеркальный каскад | Соединить повторно используемый зеркальный маршрут с тремя запусками батарейного каскада. | 3 | 1 | 1 | 2, 3, 4 |
| 56 | Один миг — два отражения | Увидеть, что один одновременный пакет отражает оба входа, а не только первый. | 1 | 2 | 4 | 6 |
| 57 | Дальний выход | Разделить роль входа портала и локальных выходных стрелок его партнёра. | 1 | 1 | 1 | 3 |
| 58 | Развилка за порталом | Прочитать разветвление на выходном конце пары и сохранить обе ветви. | 1 | 1 | 3 | 3 |
| 59 | Два перехода | Собрать последовательность двух разных портальных пар через зеркальный поворот. | 1 | 1 | 1 | 4 |
| 60 | Обратный маршрут | Доказать двустороннюю работу пары в разных запусках без лишнего источника. | 2 | 1 | 3 | 3, 2 |
| 61 | Встречный переход | Провести две равные ветви к обоим концам пары в один тик ради двух целей. | 1 | 2 | 4 | 4 |
| 62 | Мост к батарее | Свести локальный и перенесённый импульсы в батарее за один запуск. | 1 | 1 | 1 | 5 |
| 63 | Только вместе | На безопасном ромбе открыть И двумя разными соседями в одном тике. | 1 | 2 | 4 | 5 |
| 64 | Третий луч | Распределить три выхода источника между немедленной целью и синхронным вентилем. | 1 | 3 | 7 | 3 |
| 65 | Зеркальное согласие | Согласовать две зеркальные ветви, затем распределить результат И между двумя целями. | 1 | 3 | 4 | 7 |
| 66 | Дистанция не время | Согласовать длинную местную цепь с пространственно далёким портальным маршрутом. | 1 | 2 | 4 | 6 |
| 67 | Двойное согласие | Построить два последовательных синхронных схождения без накопления между ними. | 1 | 3 | 7 | 5 |
| 68 | Подготовка и совпадение | Отделить сохраняемый заряд батареи от непостоянного одновременного условия И. | 2 | 2 | 3 | 1, 3 |
| 69 | Первое ожидание | Увидеть отдельные моменты активации, ожидания и выпуска задержки +1. | 1 | 1 | 1 | 3 |
| 70 | Короткой ветви — два тика | Использовать задержку +2 как обязательный компенсатор разницы длин перед И. | 1 | 3 | 5 | 5 |
| 71 | Один тик перед прыжком | Согласовать И через задержку +1, портал и зеркало; считать перенос отдельно от обычного шага. | 1 | 2 | 4 | 5 |
| 72 | Медленный запас | Дать передышку после синхронизации и показать полный повтор задержки +3 в следующем запуске. | 2 | 2 | 4 | 6, 7 |
| 73 | Разные часы | Сопоставить две разные задержки и два разных расстояния без изменения настроек между запусками. | 1 | 3 | 5 | 7 |
| 74 | Семь шагов к запасу | Свести четыре новые механики в обязательном семитиковом схождении и повторить его для накопления. | 2 | 3 | 7 | 8, 9 |
| 75 | Подготовить, согласовать, сохранить | Объединить порядок источников, И, перенос, отражение, задержку и два накопителя в одном компактном экзамене. | 3 | 4 | 8 | 1, 8, 10 |

The exhaustive run made 4,348 launch simulations and found 42 winning orientation/source-sequence combinations. All 25 author witnesses won. Every required interaction held in every winning trace, and every declared par/rotation bound matched the exhaustive minimum.

Not established by this content audit: runtime catalog integration, packaged Android resources, touch/back behavior, visual readability or human difficulty/fun. Those require separate integration, export and physical-device checks. Original levels 1–50 were not edited.

Level 51 node 3 is an intentional blocked wrong-way branch for teaching; removing a blocker leaves an empty cell, which also stops transmission. It is not claimed mechanically necessary. All other new ordinary nodes, sources and portal pairs are covered by the tracked 438-case witness ablation gate.

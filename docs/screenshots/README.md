# Реальные скриншоты Godot

OpenGL Compatibility, Xvfb / Mesa llvmpipe; не макеты и не увеличенные копии. Каждый PNG получен из viewport указанного размера. Победа/поражение достигнуты действиями через GameManager. Для снимка реакции таймер и Tween остановлены на паузе, диалог скрыт только в инструменте съёмки.

| Экран | 720×1280 | 1080×1920 | 1440×3200 |
|---|---|---|---|
| Главное меню | [PNG](720x1280-menu.png) | [PNG](1080x1920-menu.png) | [PNG](1440x3200-menu.png) |
| Поле | [PNG](720x1280-gameplay.png) | [PNG](1080x1920-gameplay.png) | [PNG](1440x3200-gameplay.png) |
| Победа | [PNG](720x1280-victory.png) | [PNG](1080x1920-victory.png) | [PNG](1440x3200-victory.png) |
| Поражение | [PNG](720x1280-loss.png) | [PNG](1080x1920-loss.png) | [PNG](1440x3200-loss.png) |
| Выбор уровней | [PNG](720x1280-levels.png) | [PNG](1080x1920-levels.png) | [PNG](1440x3200-levels.png) |
| Пауза | [PNG](720x1280-pause.png) | [PNG](1080x1920-pause.png) | [PNG](1440x3200-pause.png) |
| Цепная реакция | [PNG](720x1280-reaction-paused.png) | [PNG](1080x1920-reaction-paused.png) | [PNG](1440x3200-reaction-paused.png) |

В логах — результаты прохождения и проверок границ. Съёмка использует отдельные файлы сохранений. Физический Android DPI, вырезы, мультитач на устройстве и нагрев этим способом не проверяются.

## Меню 0.4.0 (история)

| Экран | 720×1280 | 1080×1920 | 1440×3200 |
|---|---|---|---|
| Новая игра | [PNG](v4-720x1280-menu-fresh.png) | [PNG](v4-1080x1920-menu-fresh.png) | [PNG](v4-1440x3200-menu-fresh.png) |
| Частичный прогресс | [PNG](v4-720x1280-menu-partial.png) | [PNG](v4-1080x1920-menu-partial.png) | [PNG](v4-1440x3200-menu-partial.png) |
| Кампания завершена | [PNG](v4-720x1280-menu-complete.png) | [PNG](v4-1080x1920-menu-complete.png) | [PNG](v4-1440x3200-menu-complete.png) |
| Справочник | [PNG](v4-720x1280-guide.png) | [PNG](v4-1080x1920-guide.png) | [PNG](v4-1440x3200-guide.png) |
| Настройки | [PNG](v4-720x1280-settings.png) | [PNG](v4-1080x1920-settings.png) | [PNG](v4-1440x3200-settings.png) |
| Главы | [PNG](v4-720x1280-chapters.png) | [PNG](v4-1080x1920-chapters.png) | [PNG](v4-1440x3200-chapters.png) |
| Игровой экран | [PNG](v4-720x1280-game.png) | [PNG](v4-1080x1920-game.png) | [PNG](v4-1440x3200-game.png) |
| Уровень19 | [PNG](v4-720x1280-level-19.png) | [PNG](v4-1080x1920-level-19.png) | [PNG](v4-1440x3200-level-19.png) |
| Уровень49 | [PNG](v4-720x1280-level-49.png) | [PNG](v4-1080x1920-level-49.png) | [PNG](v4-1440x3200-level-49.png) |

Все27 PNG сняты работающим Godot/OpenGL через `tools/v4_capture.gd`. Проверены реальные размеры, границы элементов, минимальные сенсорные области144логических px (Continue160), native Input касания обеих CTA/Info/Settings, Back и отсутствие работы декорации в игре. Полный прогресс — изолированная QA-фикстура. Цвета и формы — собственная процедурная графика.

Логи: [720](v4-720x1280-run.log), [1080](v4-1080x1920-run.log), [1440](v4-1440x3200-run.log); все exit0. [Автотесты](v4-tests.log). Замеры: [720](v4-720x1280-performance.json), [1080](v4-1080x1920-performance.json), [1440](v4-1440x3200-performance.json). Это программный Linux renderer, не FPS/нагрев Android. v0.4.0 на физическом телефоне не проверялась.

## Актуальные экраны0.5.0

Godot/OpenGL, реальные PNG трёх размеров. Завершённая кампания/темы — явная QA-фикстура; обычная игра не получает их бесплатно.

| Экран | 720×1280 | 1080×1920 | 1440×3200 |
|---|---|---|---|
| Меню | [PNG](v5-720x1280-menu.png) | [PNG](v5-1080x1920-menu.png) | [PNG](v5-1440x3200-menu.png) |
| Минимальные уровниI | [PNG](v5-720x1280-levels-i.png) | [PNG](v5-1080x1920-levels-i.png) | [PNG](v5-1440x3200-levels-i.png) |
| Заблокированная сетка | [PNG](v5-720x1280-levels-locked.png) | [PNG](v5-1080x1920-levels-locked.png) | [PNG](v5-1440x3200-levels-locked.png) |
| Минимальные уровниV | [PNG](v5-720x1280-levels-v.png) | [PNG](v5-1080x1920-levels-v.png) | [PNG](v5-1440x3200-levels-v.png) |
| Достижения | [PNG](v5-720x1280-achievements-locked.png) | [PNG](v5-1080x1920-achievements-locked.png) | [PNG](v5-1440x3200-achievements-locked.png) |
| Все достижения | [PNG](v5-720x1280-achievements-complete.png) | [PNG](v5-1080x1920-achievements-complete.png) | [PNG](v5-1440x3200-achievements-complete.png) |
| Темы закрыты | [PNG](v5-720x1280-themes-locked.png) | [PNG](v5-1080x1920-themes-locked.png) | [PNG](v5-1440x3200-themes-locked.png) |
| Темы открыты | [PNG](v5-720x1280-themes-unlocked.png) | [PNG](v5-1080x1920-themes-unlocked.png) | [PNG](v5-1440x3200-themes-unlocked.png) |
| Neon | [PNG](v5-720x1280-theme-neon.png) | [PNG](v5-1080x1920-theme-neon.png) | [PNG](v5-1440x3200-theme-neon.png) |
| Electric Blue | [PNG](v5-720x1280-theme-electric_blue.png) | [PNG](v5-1080x1920-theme-electric_blue.png) | [PNG](v5-1440x3200-theme-electric_blue.png) |
| Violet Pulse | [PNG](v5-720x1280-theme-violet_pulse.png) | [PNG](v5-1080x1920-theme-violet_pulse.png) | [PNG](v5-1440x3200-theme-violet_pulse.png) |
| Emerald Circuit | [PNG](v5-720x1280-theme-emerald_circuit.png) | [PNG](v5-1080x1920-theme-emerald_circuit.png) | [PNG](v5-1440x3200-theme-emerald_circuit.png) |
| Solar Gold | [PNG](v5-720x1280-theme-solar_gold.png) | [PNG](v5-1080x1920-theme-solar_gold.png) | [PNG](v5-1440x3200-theme-solar_gold.png) |
| Частичный заряд | [PNG](v5-720x1280-battery-partial.png) | [PNG](v5-1080x1920-battery-partial.png) | [PNG](v5-1440x3200-battery-partial.png) |
| Реакция | [PNG](v5-720x1280-reaction.png) | [PNG](v5-1080x1920-reaction.png) | [PNG](v5-1440x3200-reaction.png) |
| Победа/достижение | [PNG](v5-720x1280-victory-achievement.png) | [PNG](v5-1080x1920-victory-achievement.png) | [PNG](v5-1440x3200-victory-achievement.png) |
| Настройки | [PNG](v5-720x1280-settings-reduced.png) | [PNG](v5-1080x1920-settings-reduced.png) | [PNG](v5-1440x3200-settings-reduced.png) |
| Статистика | [PNG](v5-720x1280-statistics.png) | [PNG](v5-1080x1920-statistics.png) | [PNG](v5-1440x3200-statistics.png) |
| Экспорт JSON | [PNG](v5-720x1280-statistics-export.png) | [PNG](v5-1080x1920-statistics-export.png) | [PNG](v5-1440x3200-statistics-export.png) |
| Справочник | [PNG](v5-720x1280-guide.png) | [PNG](v5-1080x1920-guide.png) | [PNG](v5-1440x3200-guide.png) |
| Полная кампания | [PNG](v5-720x1280-menu-complete.png) | [PNG](v5-1080x1920-menu-complete.png) | [PNG](v5-1440x3200-menu-complete.png) |

Инструмент `tools/v5_capture.gd` проверяет реальные размеры, видимость/границы текста и кнопок, nativeInput CTA/настроек/достижений/тем/экспорта/копирования и Back. Сначала ждёт layout новых Containers, затем вычисляет позицию касания. Звёзды и заряд получены реальными действиями GameManager. Закрытая сетка — read-only QA-вызов; в обычной навигации закрытая глава отключена. Ширина/высота сенсорных кнопок минимум144логических px.

Логи и Performance monitors: [720](v5-720x1280-run.log)/[JSON](v5-720x1280-performance.json), [1080](v5-1080x1920-run.log)/[JSON](v5-1080x1920-performance.json), [1440](v5-1440x3200-run.log)/[JSON](v5-1440x3200-performance.json). [Автотесты](v5-tests.log). Программный llvmpipe/Linux не заменяет физические FPS/нагрев/вырезы Android0.5.

## Настройки и touch 0.2.0

- 720x1280: [menu](settings-720x1280-menu.png), [panel](settings-720x1280-panel.png), [game](settings-720x1280-game.png), [rotation](settings-720x1280-rotation.png)
- 1080x1920: [menu](settings-1080x1920-menu.png), [panel](settings-1080x1920-panel.png), [game](settings-1080x1920-game.png), [rotation](settings-1080x1920-rotation.png)
- 1440x3200: [menu](settings-1440x3200-menu.png), [panel](settings-1440x3200-panel.png), [game](settings-1440x3200-game.png), [rotation](settings-1440x3200-rotation.png)

Снято обычным Godot через Xvfb. Настройки открываются и переключаются native Input-событиями, поворот — одним native касанием. Это не тест физического Android.

## Интерфейс 0.3.0 (история)

- **720x1280**: [меню](v3-720x1280-menu.png), [поле](v3-720x1280-game.png), [справочник](v3-720x1280-guide.png), [закрытые главы](v3-720x1280-chapters-locked.png), [прогресс глав](v3-720x1280-chapters-complete.png), [уровни V](v3-720x1280-levels-v.png), [настройки](v3-720x1280-settings.png), [победа](v3-720x1280-victory.png), [поражение](v3-720x1280-loss.png)
- **1080x1920**: [меню](v3-1080x1920-menu.png), [поле](v3-1080x1920-game.png), [справочник](v3-1080x1920-guide.png), [закрытые главы](v3-1080x1920-chapters-locked.png), [прогресс глав](v3-1080x1920-chapters-complete.png), [уровни V](v3-1080x1920-levels-v.png), [настройки](v3-1080x1920-settings.png), [победа](v3-1080x1920-victory.png), [поражение](v3-1080x1920-loss.png)
- **1440x3200**: [меню](v3-1440x3200-menu.png), [поле](v3-1440x3200-game.png), [справочник](v3-1440x3200-guide.png), [закрытые главы](v3-1440x3200-chapters-locked.png), [прогресс глав](v3-1440x3200-chapters-complete.png), [уровни V](v3-1440x3200-levels-v.png), [настройки](v3-1440x3200-settings.png), [победа](v3-1440x3200-victory.png), [поражение](v3-1440x3200-loss.png)

Снимки текущей версии сняты Godot/Xvfb, не макеты. Завершённая кампания показана на QA-фикстуре сохранения; обычная новая игра открывает только главуI. Кнопки Info/Settings и узел проверены nativeInput, размеры PNG совпадают с окнами. Физический Android0.3.0 пока не использовался.

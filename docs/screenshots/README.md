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

## Настройки и touch 0.2.0

- 720x1280: [menu](settings-720x1280-menu.png), [panel](settings-720x1280-panel.png), [game](settings-720x1280-game.png), [rotation](settings-720x1280-rotation.png)
- 1080x1920: [menu](settings-1080x1920-menu.png), [panel](settings-1080x1920-panel.png), [game](settings-1080x1920-game.png), [rotation](settings-1080x1920-rotation.png)
- 1440x3200: [menu](settings-1440x3200-menu.png), [panel](settings-1440x3200-panel.png), [game](settings-1440x3200-game.png), [rotation](settings-1440x3200-rotation.png)

Снято обычным Godot через Xvfb. Настройки открываются и переключаются native Input-событиями, поворот — одним native касанием. Это не тест физического Android.

## Актуальный интерфейс 0.3.0

- **720x1280**: [меню](v3-720x1280-menu.png), [поле](v3-720x1280-game.png), [справочник](v3-720x1280-guide.png), [закрытые главы](v3-720x1280-chapters-locked.png), [прогресс глав](v3-720x1280-chapters-complete.png), [уровни V](v3-720x1280-levels-v.png), [настройки](v3-720x1280-settings.png), [победа](v3-720x1280-victory.png), [поражение](v3-720x1280-loss.png)
- **1080x1920**: [меню](v3-1080x1920-menu.png), [поле](v3-1080x1920-game.png), [справочник](v3-1080x1920-guide.png), [закрытые главы](v3-1080x1920-chapters-locked.png), [прогресс глав](v3-1080x1920-chapters-complete.png), [уровни V](v3-1080x1920-levels-v.png), [настройки](v3-1080x1920-settings.png), [победа](v3-1080x1920-victory.png), [поражение](v3-1080x1920-loss.png)
- **1440x3200**: [меню](v3-1440x3200-menu.png), [поле](v3-1440x3200-game.png), [справочник](v3-1440x3200-guide.png), [закрытые главы](v3-1440x3200-chapters-locked.png), [прогресс глав](v3-1440x3200-chapters-complete.png), [уровни V](v3-1440x3200-levels-v.png), [настройки](v3-1440x3200-settings.png), [победа](v3-1440x3200-victory.png), [поражение](v3-1440x3200-loss.png)

Снимки текущей версии сняты Godot/Xvfb, не макеты. Завершённая кампания показана на QA-фикстуре сохранения; обычная новая игра открывает только главуI. Кнопки Info/Settings и узел проверены nativeInput, размеры PNG совпадают с окнами. Физический Android0.3.0 пока не использовался.

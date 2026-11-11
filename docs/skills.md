# Подключённые Skills

Установлены в `/home/codespace/.codex/skills/`; автоматическое обнаружение — со следующего сообщения. В текущей сессии инструкции прочитаны вручную. Это инструкции агента, не расширения игрового движка.

| Запрошено | Подключённый аналог |
|---|---|
| Superpowers | Уже установлен пакет `superpowers`, применены planning, TDD, debugging, verification и review |
| developer review | Уже установлен `superpowers:requesting-code-review`; независимый reviewer выполнил два прохода |
| Godot Expert | `godot-gdscript`, `godot-ui-control` |
| Game Designer | `game-design`, `puzzle` |
| Game QA Tester | `godot-gdscript-headless-testing` |
| Mobile UI/UX | `game-ui-ux`, `godot-ui-control` |
| Level Designer | `level-design` |
| Performance Optimizer | `performance-optimization` |
| Android Release | `godot-export` |
| Ad Monetization | `game-monetization` — частичный аналог: общая монетизация, не интеграция AdMob |

Источники: [Skyrant/gamedev-agent-skills](https://github.com/Skyrant/gamedev-agent-skills) и [poorvith-mp/skills-gamedev](https://github.com/poorvith-mp/skills-gamedev). Подобраны по содержанию SKILL.md, а не совпадению названий. Директории references установлены вместе с навыками. Исходный код или ассеты этих репозиториев в игру не копировались.

Для повторной установки через системный skill-installer:

```bash
python3 /home/codespace/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo Skyrant/gamedev-agent-skills --path \
  skills/godot/godot-gdscript skills/godot/godot-gdscript-headless-testing \
  skills/godot/godot-export skills/godot/godot-ui-control \
  skills/disciplines/game-ui-ux skills/disciplines/level-design \
  skills/disciplines/performance-optimization skills/genres/puzzle
python3 /home/codespace/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo poorvith-mp/skills-gamedev --path skills/game-design skills/game-monetization
```

Установщик не перезаписывает существующие директории. Пути установщика зависят от окружения.

Проверенные исходные ревизии: gamedev-agent-skills `7eb1b53305fab881f4758e2eff2e371cd7869221`; skills-gamedev `d661d370a67c4532034e3d1d87c4aec237077f34`.

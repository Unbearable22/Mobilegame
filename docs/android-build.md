# Android debug ARM64

Godot **4.7.2 stable** + совпадающие official export templates; локальный Temurin **JDK 17.0.21+9**, Android command-line tools, platform-tools, **SDK Platform 36 / Build-tools 36.0.0**. Системная Java не заменялась. NDK/CMake/Gradle не нужны для выбранного экспорта готового APK-шаблона без native-плагинов.

Официальный шаблон использует **minSdk 24 / targetSdk 36**. Package ID `org.chainreact.onetappuzzle`, portrait, Compatibility/OpenGL, только ARM64. Сетевые и иные `uses-permission` отсутствуют. Иконки собственные SVG: основная, прозрачный foreground и сплошной фон adaptive icon. Включён импорт ETC2/ASTC, необходимый валидатору Android export.

## Воспроизведение

Установить SDK через официальный sdkmanager (JDK17 через JAVA_HOME), принять Android SDK licenses, установить `platform-tools`, `build-tools;36.0.0`, `platforms;android-36`. Скачать Godot и export templates точно **4.7.2 stable** с [официального релиза](https://github.com/godotengine/godot/releases/tag/4.7.2-stable). Из TPZ нужны `android_debug.apk`, `android_release.apk`, `version.txt` в одной директории.

```bash
python3 tools/build_android.py \
  --godot /tmp/chain-godot/Godot_v4.7.2-stable_linux.x86_64 \
  --java /tmp/chain-android-toolchain/java/jdk-17.0.21+9 \
  --sdk /tmp/chain-android-toolchain/sdk \
  --templates /tmp/chain-android-toolchain/data/godot/export_templates/4.7.2.stable
```

Скрипт проверяет версии, использует изолированные настройки Godot в игнорируемой `build/tooling/`, запускает 8 Python-тестов и 528 проверок GDScript, затем `--export-debug`. Стандартный debug-ключ создаётся в директории SDK и не попадает в Git/артефакт. Это не release identity. Полная перезапись build-папки не удаляет SDK-ключ.

Результат: **`build/android/chain-react-debug-arm64.apk`**. Рядом `.sha256`, `.verification.json`, `.manifest.txt`, `.badging.txt`, `.signature.txt`, `.smoke.txt`. Хеш зависит от ключа и сборки; сверять с отчётом из той же папки/того же CI-артефакта.

Проверки бинарника: debug=true, portrait, ожидаемые package/SDK/ABI, отсутствие разрешений и dev-файлов; все 10 JSON совпадают с исходниками; наличие mipmap launcher icons; apksigner; zipalign 16KB. Ресурсы извлекаются из APK и запускаются десктопным Godot, где проверяются main scene, меню, десять уровней, ориентация и mobile Compatibility. Это проверка комплектности Android-пакета, **не исполнение Android native-библиотеки и не тест телефона**.

## GitHub Actions и скачивание

[Workflow Android debug APK](https://github.com/Unbearable22/Mobilegame/actions/workflows/android-debug.yml) запускается при push в main/feat/chain-react-mvp и pull request; поддерживает workflow_dispatch. На чистом Ubuntu runner устанавливает toolchain, тестирует, собирает, проверяет и загружает `chain-react-debug-arm64-<commit>` на 14 дней. Нужен вход в GitHub для скачивания Actions artifact. Распаковать ZIP, установить `.apk`; `.sha256` относится именно к нему.

У workflow только `contents: read`. Артефакт содержит APK и отчёты, но не toolchain, ключи или editor settings. CI-подпись debug может меняться между чистыми runners: при конфликте подписи не удалять старое приложение, пока не сохранены результаты тестов.

## Независимый review

Исправлены обнаруженные проблемы: build/tooling и тестовые JSON исключены из экспорта; проверяются точные значения debug/portrait, а не наличие атрибута; выбранная JDK передаётся также через PATH; проверяются реальные launcher mipmaps вместо случайной notification PNG. Добавлены отрицательные тесты для неверных манифестов.

[Чек-лист телефона](android-device-checklist.md). Физический Android не использовался. FPS/нагрев, аппаратный Back, вырезы и жизненный цикл требуют ручной проверки.

## Последняя сборка 0.3.0

[Успешный CI](https://github.com/Unbearable22/Mobilegame/actions/runs/43037655960) · [скачать APK и отчёты (ZIP)](https://github.com/Unbearable22/Mobilegame/actions/runs/43037655960/artifacts/13864186042). Внутри `chain-react-debug-arm64.apk`, **28 392 278 байт**. SHA256 `0a1bafbc8534eb3a1f271623e2cb16eeb9601045a15cfab87ab8ef594a2707ec`. [Проверенный CI-отчёт](android-v3-ci-artifact.json).

528 GDScript +8 Python-проверок прошли. Артефакт содержит `level-audit.json`: все50уровней, полные48 242симуляции, корректные авторские трёхзвёздочные решения и design bounds. Все50JSON включены в APK и совпадают с исходниками; package ID/подпись/ARM64/portrait/min24-target36/отсутствиеpermissions проверены. ZIP скачан обратно, SHA256 и audit сверены.

Пользователь подтвердил физическую работу0.2.0. Новая0.3.0 на устройстве не проверялась. При смене CI debug-подписи сначала сохранить старый прогресс; миграция v1→v2 сохраняет данные, но удаление установки Android стирает их независимо от миграции.

# v0.6.0 verified local debug APK

[Download ARM64 APK](https://github.com/Unbearable22/Mobilegame/releases/download/v0.6.0-debug/chain-react-debug-arm64.apk) · [release](https://github.com/Unbearable22/Mobilegame/releases/tag/v0.6.0-debug) · [machine report](android-v6-build.json).

- Source commit:`9d740f9e3947bada2e2c4bc7b6f4783c11f1d073`.
- Local file:`build/android/chain-react-debug-arm64.apk`, **28,520,396 bytes**.
- SHA256:`d5d045e5657ea56747ae54d8b1a4d7e2b98f74d90386c4cffe8b192ee2739b68`.
- Version0.6.0/code7; package`org.chainreact.onetappuzzle`; onlyARM64; portrait; Compatibility; SDK24–36; debug;100 exact level JSONs; own launcher icons; **zero requested permissions**.
- APK signature and selected persistent certificate match:`3ff232e70e87f245e1e400f4ba31853f64b2c60b7d5d88b6e14a2b42cadae384`.16KB alignment and packaged-resource startup smoke passed. The smoke runs extracted APK resources on desktop Godot; it is not Android runtime/device testing.
- The export tool reran all2,294 GDScript assertions,19 Python tests,55,034 audit simulations and438 witness mutations before exporting. Password scan of build log passed. Public release assets include signature/asset verification, checksum and content audit; no key/password is uploaded.

This is a **local build**, using isolated JDK17/SDK36 and matching Godot4.7.2 templates. The [Actions run](https://github.com/Unbearable22/Mobilegame/actions/runs/43216462879) failed as intended because signing Secrets are absent; Secrets access and dispatch both returnHTTP403 for this integration. It did not produce an artifact. Owner setup:[android-signing.md](android-signing.md). CI now fails closed rather than silently generating a fresh certificate.

A separate [v0.5.1 checkpoint](https://github.com/Unbearable22/Mobilegame/releases/tag/v0.5.1-debug) uses this same new certificate; its APK is28,438,529bytes,SHA256`cb139f6d91a6b3f2e34b2b91d5d7d6eda91910785e5049e91dc88ae64e426415`. Earlier APKs used different per-run certificates. Back up full progress before replacing those installations:[transfer instructions](android-progress-transfer.md).

Physical-device validation, clipboard-on-Android, FPS/heat and human difficulty/fun remain pending. Original Android theme failure was not reproduced on a phone; confirmed palette defects and diagnostic route are documented in[v51-theme-investigation.md](v51-theme-investigation.md).

---

## Earlier build history

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

Скрипт проверяет версии, использует изолированные настройки Godot в игнорируемой `build/tooling/`, запускает 8 Python-тестов и 1026 проверок GDScript, затем `--export-debug`. Стандартный debug-ключ создаётся в директории SDK и не попадает в Git/артефакт. Это не release identity. Полная перезапись build-папки не удаляет SDK-ключ.

Результат: **`build/android/chain-react-debug-arm64.apk`**. Рядом `.sha256`, `.verification.json`, `.manifest.txt`, `.badging.txt`, `.signature.txt`, `.smoke.txt`. Хеш зависит от ключа и сборки; сверять с отчётом из той же папки/того же CI-артефакта.

Проверки бинарника: debug=true, portrait, ожидаемые package/SDK/ABI, отсутствие разрешений и dev-файлов; все 50 JSON совпадают с исходниками; наличие mipmap launcher icons; apksigner; zipalign 16KB. Ресурсы извлекаются из APK и запускаются десктопным Godot, где проверяются main scene, меню, 50 уровней, ориентация и mobile Compatibility. Это проверка комплектности Android-пакета, **не исполнение Android native-библиотеки и не тест телефона**.

В artifact0.4.0 также включена полная диагностическая трасса уровней19/49. Resource smoke проверяет создание нового меню и переход Continue с остановкой декорации.

## GitHub Actions и скачивание

[Workflow Android debug APK](https://github.com/Unbearable22/Mobilegame/actions/workflows/android-debug.yml) запускается при push в main/feat/chain-react-mvp и pull request; поддерживает workflow_dispatch. На чистом Ubuntu runner устанавливает toolchain, тестирует, собирает, проверяет и загружает `chain-react-debug-arm64-<commit>` на 14 дней. Нужен вход в GitHub для скачивания Actions artifact. Распаковать ZIP, установить `.apk`; `.sha256` относится именно к нему.

У workflow только `contents: read`. Артефакт содержит APK и отчёты, но не toolchain, ключи или editor settings. CI-подпись debug может меняться между чистыми runners: при конфликте подписи не удалять старое приложение до проверенной резервной копии. [Точный перенос прогресса через adb](android-progress-transfer.md). Старый приватный CI-ключ недоступен; бесшовное обновление поверх прошлой CI-сборки не гарантируется.

## Независимый review

Исправлены обнаруженные проблемы: build/tooling и тестовые JSON исключены из экспорта; проверяются точные значения debug/portrait, а не наличие атрибута; выбранная JDK передаётся также через PATH; проверяются реальные launcher mipmaps вместо случайной notification PNG. Добавлены отрицательные тесты для неверных манифестов.

[Чек-лист телефона](android-device-checklist.md). Физический Android не использовался. FPS/нагрев, аппаратный Back, вырезы и жизненный цикл требуют ручной проверки.

## Последняя сборка0.5.0

[Успешный run](https://github.com/Unbearable22/Mobilegame/actions/runs/43204226679) · [скачать APK и отчёты](https://github.com/Unbearable22/Mobilegame/actions/runs/43204226679/artifacts/13937640075), source commit `e97aae5204fb1023c3f977c8816d4a038cf6cb23`. **28 438 529байт**. SHA256 `d5c95cbfbb8132be5f986d0d676ffc62bcf5a02430deddac6c11e704d3216c7f`. [CI-отчёт](android-v5-ci-artifact.json).

В чистом CI пройдены1026утверждений GDScript,8Python-тестов,50полных аудитов/48 242симуляции, export/verifier/upload. VersionName0.5.0/code5; package ID прежний; ARM64,portrait,min24/target36,нетuses-permissions; signaturev2/v3 и16KBzipalign. Все50JSON сверены с исходниками после обратного скачивания. Resource-smoke открывает новое меню,10достижений,5тем, экспорт статистики и Continue через десктопный Godot; это не Android-native выполнение.

Локальная копия скачанного CI APK: `/workspaces/Mobilegame/build/android/chain-react-debug-arm64.apk`. ВZIPвсе соответствующие manifest/signature/hash/smoke/auditотчёты; приватных ключей нет. Сертификат0.5.0 `beed4cb670a431f448a69dd2f44e297193751ec154410c56a671ad27e10803ab` отличается от прежнего CI0.4.0. Перед удалением старой установки сохранить progress.json по [инструкции переноса](android-progress-transfer.md). Миграция формата2→3 не защищает данные от Android uninstall.

Пользователь физически подтвердил0.4.0. **Физическая0.5.0 не проверялась.** Нужен [обновлённый чек-лист](android-device-checklist.md): темы/достижения/effects/export/Back/migration/нагрев.

## Предыдущая сборка0.4.0

[Успешный CI](https://github.com/Unbearable22/Mobilegame/actions/runs/43181090575) · [скачать APK и отчёты (ZIP)](https://github.com/Unbearable22/Mobilegame/actions/runs/43181090575/artifacts/13926795328), source commit `98d63e8`. Внутри `chain-react-debug-arm64.apk`, **28 404 892байта**. SHA256 `f6be0b4ccdf0f98654c2264fcbb690c203270200bcd8ac24848885b1295e07fd`. [Проверенный отчёт](android-v4-ci-artifact.json).

Повторены854утверждения GDScript,8Python-тестов и50полных аудитов/48 242симуляции. Manifest: versionName0.4.0/code4, прежний package ID, ARM64,portrait,min24/target36,нетuses-permissions. Signature v2/v3 и16KBzipalign прошли; все50JSON совпадают с исходниками, dev-файлы/ключи отсутствуют. Packaged-resource smoke создаёт новое меню и проверяет Continue; он исполняется десктопным Godot и не является тестом Android-native кода.

ZIP скачан обратно и сверены фактические bytes/SHA256/audit/JSON. Локальная копия того же CI APK: `/workspaces/Mobilegame/build/android/chain-react-debug-arm64.apk`. Физическая проверка0.4.0 не выполнялась. [Сохранение прогресса при смене debug-сертификата](android-progress-transfer.md) обязательно до удаления старой установки.

## Предыдущая сборка 0.3.0

[Успешный CI](https://github.com/Unbearable22/Mobilegame/actions/runs/43037655960) · [скачать APK и отчёты (ZIP)](https://github.com/Unbearable22/Mobilegame/actions/runs/43037655960/artifacts/13864186042). Внутри `chain-react-debug-arm64.apk`, **28 392 278 байт**. SHA256 `0a1bafbc8534eb3a1f271623e2cb16eeb9601045a15cfab87ab8ef594a2707ec`. [Проверенный CI-отчёт](android-v3-ci-artifact.json).

528 GDScript +8 Python-проверок прошли. Артефакт содержит `level-audit.json`: все50уровней, полные48 242симуляции, корректные авторские трёхзвёздочные решения и design bounds. Все50JSON включены в APK и совпадают с исходниками; package ID/подпись/ARM64/portrait/min24-target36/отсутствиеpermissions проверены. ZIP скачан обратно, SHA256 и audit сверены.

Пользователь подтвердил физическую работу0.2.0. Новая0.3.0 на устройстве не проверялась. При смене CI debug-подписи сначала сохранить старый прогресс; миграция v1→v2 сохраняет данные, но удаление установки Android стирает их независимо от миграции.

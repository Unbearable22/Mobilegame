# Перенос прогресса между debug APK с разными подписями

Package ID0.5.0 не изменён; формат3 читает JSON v1/v2/v3 совместимо. Однако существующий CI создаёт новый debug-ключ на каждом чистом runner. Прежний приватный CI-ключ0.3.0 не сохранён в доступном окружении. Восстановить его из APK/сертификата нельзя. Поэтому обычное обновление0.3→0.4 через `adb install -r` с высокой вероятностью будет отклонено (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`). **Не удаляйте прежнюю игру до получения проверенной резервной копии.** Ни код миграции, ни одинаковый package ID не сохранят данные после удаления Android-приложения.

Ниже ручной путь для debug-сборок и доверенного компьютера с adb. Он не требует root, новых разрешений, сетевого сервиса или изменений старого APK. На физическом устройстве в рамках этой разработки не выполнялся.

## 1. Сохранить данные старой установки

Подключить телефон с разрешённой USB-отладкой. Если подключено несколько устройств, добавлять `-s SERIAL` ко всем adb-командам.

```bash
adb devices
adb shell am force-stop org.chainreact.onetappuzzle
adb shell run-as org.chainreact.onetappuzzle find files -name progress.json
```

Штатный путь Godot — `files/progress.json`. Если команда вернула другой путь, использовать именно его в чтении/восстановлении. Если `run-as` запрещён, файла нет или устройство не подключилось, **остановиться и сохранить прежнюю установку**.

```bash
adb exec-out run-as org.chainreact.onetappuzzle cat files/progress.json > chain-react-progress.json
python3 -m json.tool chain-react-progress.json
```

Проверить, что это JSON версии1,2или3 с ожидаемыми `completed`, `last_level` и `sound`; сохранить копию ещё в одном месте. Ошибки adb, пустой файл или несовпадающий прогресс — причина остановиться. Имя резервной копии не должно указывать на существующий нужный файл. Для v1 отдельно можно сохранить `.v1.bak`, если он существует.

## 2. Установить новую версию

Сначала попробовать обычное обновление:

```bash
adb install -r chain-react-debug-arm64.apk
```

Если оно прошло, удалять игру и восстанавливать данные не нужно — проверить меню и прогресс. При конфликте сертификатов и **только после проверки копии** удалить старую установку средствами Android, установить новый APK, один раз запустить его для создания каталога Godot, затем остановить приложение.

## 3. Восстановить и сверить

```bash
adb shell am force-stop org.chainreact.onetappuzzle
adb push chain-react-progress.json /data/local/tmp/chain-react-progress.json
adb shell run-as org.chainreact.onetappuzzle cp /data/local/tmp/chain-react-progress.json files/progress.json
adb exec-out run-as org.chainreact.onetappuzzle cat files/progress.json > chain-react-progress-restored.json
```

Сравнить файлы побайтно до запуска игры:

```bash
python3 -c "from pathlib import Path; assert Path('chain-react-progress.json').read_bytes() == Path('chain-react-progress-restored.json').read_bytes(); print('Backup matches restored data')"
adb shell rm /data/local/tmp/chain-react-progress.json
```

После запуска проверить последнюю главу/уровень, пройденные уровни, лучшие звёзды и SFX. При чтении v1 приложение сохраняет резервную `.v1.bak` и мигрирует в v3. Незавершённый ход не переносится: игра сохраняет прогресс кампании и настройки, а не текущую попытку.

Для будущих бесшовных CI-обновлений нужен постоянный защищённый **debug**-ключ вне Git, например в repository secret. Release-ключи и пароли в Git не добавлялись; текущий этап не создаёт release identity. Пока постоянный ключ не настроен, ограничение подписей действует и на последующие чистые CI-сборки.

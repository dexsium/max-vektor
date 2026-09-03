# Max Vektor — неофициальный iOS/Android-клиент MAX

> **Unofficial MAX client.** Проект не связан с VK и разработчиками
> официального приложения MAX. Название, иконка и Bundle Identifier —
> собственные; официальный логотип и брендинг MAX не используются.

Форк [sansmaster1982/maxim-messenger](https://github.com/sansmaster1982/maxim-messenger),
переименованный и переконфигурированный так, чтобы приложение ставилось на
iPhone **рядом** с официальным MAX и не пересекалось с ним ни Bundle ID, ни
Keychain, ни локальными данными.

| Параметр | Значение |
|---|---|
| Отображаемое имя | `Max Vektor` |
| iOS Bundle Identifier | `ru.vektor.max` |
| iOS тесты | `ru.vektor.max.RunnerTests` |
| Android applicationId | `ru.vektor.max` |
| Dart-пакет | `max_vektor` |
| Минимальный iOS | 15.0 |
| Локальная БД | `max_vektor_<accId>.db` (своя у каждого аккаунта) |
| Ключи Keychain | префикс `mv_a_<accId>_` |
| Аккаунтов одновременно | до 5, у каждого свой `deviceId` |
| Upstream | https://github.com/sansmaster1982/maxim-messenger |

Bundle Identifier лежит в `ios/Runner.xcodeproj/project.pbxproj`
(`PRODUCT_BUNDLE_IDENTIFIER`, четыре вхождения: Debug/Release/Profile у
`Runner` и конфигурации `RunnerTests`). Отображаемое имя —
`ios/Runner/Info.plist`, ключи `CFBundleDisplayName` и `CFBundleName`.

## Установка на iPhone

Финальная компиляция iOS возможна **только на macOS с Xcode** — это
требование Apple, а не проекта. На Windows/Linux можно править код,
гонять `flutter analyze` и `flutter test`, но не собрать `.app`/`.ipa`.

### 1. Flutter

```bash
# macOS
git clone -b stable https://github.com/flutter/flutter.git ~/flutter
export PATH="$HOME/flutter/bin:$PATH"
flutter --version      # нужен Flutter 3.29+ / Dart 3.7+
flutter doctor
```

Xcode ставится из App Store, после установки:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### 2. Зависимости проекта

```bash
git clone <этот-репозиторий> max-vektor
cd max-vektor
flutter pub get
```

### 3. CocoaPods

```bash
sudo gem install cocoapods      # если ещё не стоит
cd ios
pod install                     # при ошибке: pod install --repo-update
cd ..
```

`ios/Podfile` фиксирует `platform :ios, '15.0'` и приводит все поды к тому же
минимальному таргету. 15.0 — это минимум самого Flutter (см.
`Flutter.podspec` в `podhelper.rb`); при более низком значении CocoaPods не
находит совместимый под `Flutter` и `pod install` падает с «required a
higher minimum deployment target». Соответственно, iOS 13 и 14 не
поддерживаются.

### 4. Открыть проект

```bash
open ios/Runner.xcworkspace
```

Именно `.xcworkspace`, а не `.xcodeproj` — иначе поды не подключатся.

### 5. Выбрать свою Apple Developer Team

В Xcode: target **Runner** → вкладка **Signing & Capabilities**:

1. включить **Automatically manage signing**;
2. в поле **Team** выбрать свою учётку (подойдёт и бесплатный Personal Team);
3. **Bundle Identifier** оставить `ru.vektor.max`. Если Xcode скажет, что
   идентификатор занят, поменять на `com.vektor.maxclient` (и точно так же
   заменить суффикс у `RunnerTests`).

В репозитории намеренно **нет** ни `DEVELOPMENT_TEAM`, ни сертификатов, ни
provisioning profile — Team подставляет тот, кто собирает.

### 6. Поставить на устройство

```bash
flutter devices
flutter run --release -d <id-вашего-iPhone>
```

На iPhone первый запуск потребует: **Настройки → Основные → VPN и управление
устройством → доверять разработчику**.

Сборка без установки:

```bash
flutter build ios --release
```

### 7. Archive и .ipa

Через Xcode: **Product → Destination → Any iOS Device**, затем
**Product → Archive**, далее в Organizer — **Distribute App**.

Через Flutter:

```bash
flutter build ipa
```

Готовый архив: `build/ios/archive/Runner.xcarchive`,
экспортированный `.ipa`: `build/ios/ipa/`.

Подпись выполняется вашим сертификатом. Сертификаты не подделываются и
code signing не обходится — при отсутствии сертификата используйте
`flutter build ios --release --no-codesign` и подписывайте архив
самостоятельно.

### Сборка .ipa без своего Mac

В репозитории лежит workflow `.github/workflows/ios-unsigned-ipa.yml`: он
собирает проект на macOS-раннере GitHub Actions и отдаёт **неподписанный**
`.ipa` артефактом.

1. Actions → **iOS unsigned IPA** → *Run workflow* (или просто пуш в ветку
   `max-vektor-ios`).
2. Скачать артефакт `max-vektor-unsigned-ipa`.
3. Подписать своим сертификатом — Xcode, AltStore или Sideloadly — и
   поставить на iPhone.

Никакие сертификаты, ключи и provisioning profile в workflow не
загружаются: подпись целиком остаётся на стороне владельца устройства.

## Совместная установка с официальным MAX

Max Vektor и официальный MAX — два независимых для iOS приложения:

- разные Bundle ID (`ru.vektor.max` против идентификатора официального
  приложения — он не используется нигде в проекте);
- у Max Vektor нет файла entitlements: не объявлены ни App Groups, ни
  Keychain Access Groups, ни associated domains, ни push-entitlement —
  пересекаться нечему;
- URL schemes не регистрируются (`CFBundleURLTypes` в `Info.plist`
  отсутствует);
- Keychain изолирован Bundle ID, а ключи дополнительно имеют префикс `mv_`;
- SQLite-база называется `max_vektor.db` и лежит в песочнице Max Vektor;
- медиа складываются в `Documents/max_vektor_media`.

Данные, токены и сессии официального приложения не читаются и не
используются: вход выполняется штатно внутри Max Vektor (номер → SMS → при
включённом пароле 2FA), токен сохраняется в свой Keychain через
`flutter_secure_storage` и восстанавливается при следующем запуске.

## Что уже работает

Всё, что было в upstream: авторизация (SMS + 2FA), восстановление сессии,
профиль, список чатов, история, приём и отправка текста, вложения, поиск
контакта по номеру, устройства и сессии, logout.

Добавлено в этом форке:

- **несколько аккаунтов MAX в одном приложении** — см. раздел ниже;
- **группы и каналы** больше не выглядят как обычный чат: тип чата
  (`DIALOG` / `CHAT` / `GROUP_CHAT` / `CHANNEL`) читается из ответа сервера,
  сохраняется в БД (миграция схемы до v8) и показывается в UI — отдельная
  иконка группы и канала в списке, тип и число участников в шапке чата,
  имя отправителя над входящим сообщением;
- группы и каналы **появляются в списке сразу после входа**: раньше список
  чатов из ответа `LOGIN` (op 19) использовался только для восстановления
  медиа, и чат без новых сообщений в списке не возникал;
- аватар чата из ответа сервера показывается в списке;
- единый логгер с тегами `[MaxVektor][AUTH]`, `[SOCKET]`, `[INIT]`, `[CHAT]`,
  `[MESSAGE]`, `[ERROR]`; в release остаются только warning и выше. Токены,
  SMS-коды и пароль 2FA в лог не попадают (`mvRedact`).

Ограничения доступа не обходятся: видно ровно то, что сервер MAX отдаёт
вашей собственной авторизованной учётной записи.

## Несколько аккаунтов

Настройки → блок **Аккаунты**: список уже добавленных, тап переключает,
кнопка **Добавить аккаунт** заводит следующий. Тот же блок открывается
иконкой переключателя в шапке списка чатов. Предел — 5 аккаунтов.

Аккаунты изолированы полностью. Всё, что относится к аккаунту, живёт в
namespace его локального id (`acc1`, `acc2`, ...):

| Что | Где |
|---|---|
| Токен, userId, тип токена | Keychain, ключи `mv_a_<accId>_*` |
| `deviceId` для INIT | Keychain, `mv_a_<accId>_device_id` |
| Переписка, контакты, вложения | `max_vektor_<accId>.db` |
| Скачанные файлы | `Documents/max_vektor_media/<accId>` |

### deviceId разведён по аккаунтам

Каждый аккаунт получает **свой** `deviceId` (UUID v4), который создаётся
один раз и живёт всю установку. Два свойства работают одновременно:

- *стабильность внутри аккаунта* — новый `deviceId` на каждый запуск
  антифрод MAX читает как поток новых устройств на одном номере;
- *различие между аккаунтами* — иначе сервер видит одно устройство, на
  котором одновременно сидят несколько номеров.

`userAgent` при этом остаётся честным: реальная модель, версия ОС и
разрешение экрана. Подделывать его под «разные телефоны» проект не
пытается — самосогласованный профиль правдоподобнее выдуманного.

### Переключение не выполняет повторный вход

Сессии аккаунтов живут в пуле `AccountRuntimes` вне Riverpod: соединение,
база и репозитории аккаунта **не уничтожаются** при переходе на соседний.
Возврат к аккаунту не вызывает LOGIN — частые LOGIN с одного устройства
ровно тот поведенческий сигнал, от которого защищается `ReconnectPolicy`
(throttle на 90 секунд). Соединение закрывается только при выходе из
аккаунта.

Обратная сторона: пока открыто несколько аккаунтов, приложение держит
несколько TLS-соединений к `api.oneme.ru` с одного устройства. Это
неизбежная плата за мультиаккаунт — не держите открытыми больше
аккаунтов, чем реально нужно.

Выход из аккаунта (кнопка в его строке или пункт «Выйти» внизу настроек)
удаляет аккаунт из списка вместе с его локальными данными. Соседние
аккаунты не затрагиваются. Если вышли из последнего — на его месте
появляется пустой аккаунт с экраном входа.

При обновлении с одноаккаунтной сборки данные переносятся автоматически:
старые ключи и `max_vektor.db` становятся первым аккаунтом.

## Обновление из upstream

```bash
git remote add upstream https://github.com/sansmaster1982/maxim-messenger.git
git fetch upstream
git checkout max-vektor-ios
git merge upstream/main        # или upstream/master — как называется ветка
```

Конфликты ожидаемы в `pubspec.yaml`, `lib/core/constants.dart`,
`ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj` и
`android/app/build.gradle.kts` — это ровно те файлы, где заданы имя и
идентификаторы. Оставляйте свои значения (`Max Vektor`, `ru.vektor.max`),
код протокола берите из upstream.

## Проверка

```bash
flutter analyze
flutter test
flutter build ios --release      # только на macOS
```

## Иконка

`tool_gen_icon.py` генерирует весь набор иконок (iOS AppIcon asset catalog +
Android mipmap) — минималистичная «V» на графитовом фоне, без элементов
брендинга MAX:

```bash
python tool_gen_icon.py
```

---

# Апстрим: Maxim — кросс-платформенный клиент MAX

Форк-клиент мессенджера MAX (api.oneme.ru) для Android и iOS, написанный
на Flutter.

## Статус

- 0.1.0, MVP-фундамент.
- Текстовые сообщения: отправка, приём (push), история, поиск контактов
  по номеру, авторизация (SMS + 2FA), повторный вход по сохранённому
  токену.
- Локальное хранилище: SQLite + Secure Storage для токена.
- iOS и Android из одной кодовой базы.
- Что не сделано: загрузка/скачивание медиа, голосовые, звонки, реакции,
  группы (видны как обычный чат, но без специфики), системные события,
  push-нотификации через FCM/APNs.

## Стек

- Flutter 3.29+, Dart 3.7+.
- State: Riverpod 2.
- БД: sqflite. Токен: flutter_secure_storage.
- Сеть: SecureSocket (TLS), msgpack_dart.

## Структура

```
lib/
  core/                константы протокола и исключения
  data/
    max/               клиент протокола MAX
      max_client.dart  TCP+TLS, фреймы, опкоды, push
      max_codec.dart   упаковка/распаковка кадров
      raw_parsers.dart парсеры msgpack-полей по сырому байту
      models/          IncomingMessage, MaxChat, MaxMessage, MaxContact
    local/             SQLite + secure storage
    repositories/      auth/chats/contacts/messages
  state/               Riverpod-провайдеры и контроллеры
  ui/
    screens/           splash, login, chats, chat, contacts, settings
    widgets/           message_bubble, chat_input
    theme/             светлая/тёмная тема Material 3
```

## Опкоды протокола MAX

Известны и реализованы:

| Опкод | Назначение                  |
|-------|-----------------------------|
| 6     | INIT (handshake)            |
| 16    | PROFILE (мой профиль)       |
| 17    | AUTH_REQUEST (SMS)          |
| 18    | AUTH_CONFIRM (код)          |
| 19    | LOGIN (по токену)           |
| 32    | CONTACT_INFO (по id)        |
| 46    | CONTACT_INFO_BY_PHONE       |
| 48    | CHAT_INFO                   |
| 49    | CHAT_HISTORY                |
| 51    | CHAT_MEDIA (галерея чата)   |
| 64    | SEND_MESSAGE (+attaches)    |
| 65    | TYPING                      |
| 67    | MSG_EDIT                    |
| 80    | PHOTO_UPLOAD                |
| 81    | STICKER_UPLOAD              |
| 82    | VIDEO_UPLOAD                |
| 83    | VIDEO_PLAY                  |
| 87    | FILE_UPLOAD                 |
| 88    | FILE_DOWNLOAD               |
| 115   | 2FA_PASSWORD                |
| 202   | TRANSCRIBE_MEDIA            |

Детальная таблица с источниками — `docs/MEDIA_OPCODES.md`. Журнал
прогресса разработки — `docs/PROGRESS.md`.

## Установка и запуск

Зависимости:
```
flutter pub get
```

### Android (требуется Android SDK + Java 17)

```
flutter run -d <device-id>
# или
flutter build apk --debug
```

Если `flutter build apk` падает с `Unable to establish loopback connection`
в текущем терминале — собирай через Android Studio: File → Open → выбрать
папку `android/`, Build → Build APK(s). Это известная проблема среды
(JDK NIO UDS), Android Studio её обходит собственным Gradle-daemon.

### iOS (требуется macOS + Xcode)

```
cd ios && pod install && cd ..
flutter run -d <device-id>
```

### Windows desktop (Flutter UI)

Требует **Developer Mode** включённого в Windows (для symlink-плагинов).

1. `start ms-settings:developers` → включить «Режим разработчика».
2. Перелогиниться (или открыть свежий терминал — privilege-token обновляется только в новом logon-сеансе).
3. `flutter build windows --debug`
4. Артефакт: `build/windows/x64/runner/Debug/maxim_messenger.exe`

На desktop:
- Импорт контактов и снимок с камеры недоступны (платформенные плагины).
- Текст, история, файлы через file_picker — работают.
- SQLite через `sqflite_common_ffi` (нативная DLL, не Android).

### CLI (standalone EXE, без Flutter)

`bin/maxim_cli.dart` — полнофункциональный консольный клиент, использует
тот же `MaxClient`. Не требует Developer Mode и Android-toolchain.

```
dart compile exe bin/maxim_cli.dart -o build/maxim_cli.exe
```

Получается ~6 МБ AOT-скомпилированный exe. Smoke:

```
build/maxim_cli.exe --probe      # TLS-хендшейк + INIT, без логина
build/maxim_cli.exe --version
build/maxim_cli.exe               # интерактивный REPL
```

REPL-команды:
- `send <chatId> <text...>` — отправить сообщение
- `hist <chatId> [count]` — последние N сообщений
- `find <phone>` — найти контакт по номеру
- `me` — мой профиль
- `quit` — выход

Токен после первого логина кладётся в `max_token.txt` рядом с exe.

## Авторизация

1. Открыть приложение, ввести номер в формате `+79991234567`.
2. Ввести код из SMS.
3. Если у аккаунта включён пароль 2FA, ввести его.

После успешного входа токен лежит в Keystore/Keychain (Secure Storage).
При повторном запуске сессия восстанавливается автоматически.

## Версии протокола

Зашиты в `lib/core/constants.dart`:
```
host = api.oneme.ru
proto_version = 10
app_version = 26.11.0
```

Когда официальное приложение MAX выпустит мажорное обновление, может
потребоваться поднять `app_version`.

## Безопасность

- Токен хранится в Android Keystore / iOS Keychain.
- Сетевой трафик к `api.oneme.ru` идёт через TLS.
- Локальная SQLite — без шифрования (на телефоне защищена системным
  шифрованием диска). Если нужен прицельный E2E — добавить SQLCipher.

## Git

Репозиторий инициализирован. Откат:
```
git log --oneline
git checkout <commit>
```

Для нормальной работы — ветка `main`, фичевые ветки от неё.

## TODO следующих итераций

1. Опкоды медиа (поднять из декомпила APK).
2. Push-нотификации (FCM Android, APNs iOS).
3. Голосовые сообщения.
4. Реакции, ответы на сообщение, пересылка.
5. Группы (members, аватары, права).
6. Тайпинг-индикатор от собеседника (приходит ли в push — проверить).
7. Дешифровка ASN.1/E2E если он есть в MAX (пока не проверено).

---

Донат-реквизиты автора апстрима из этого форка убраны. Поддержать
оригинальный проект можно на его странице:
<https://github.com/sansmaster1982/maxim-messenger>

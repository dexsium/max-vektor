import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get commonRetry;

  /// No description provided for @commonDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get commonDone;

  /// No description provided for @commonLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get commonLogout;

  /// No description provided for @commonSoon.
  ///
  /// In ru, this message translates to:
  /// **'В разработке'**
  String get commonSoon;

  /// No description provided for @settingsNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления и звук'**
  String get settingsNotifications;

  /// No description provided for @settingsSecurity.
  ///
  /// In ru, this message translates to:
  /// **'Безопасность'**
  String get settingsSecurity;

  /// No description provided for @settingsSecuritySub.
  ///
  /// In ru, this message translates to:
  /// **'Двухфакторная защита, сессии'**
  String get settingsSecuritySub;

  /// No description provided for @settingsDevices.
  ///
  /// In ru, this message translates to:
  /// **'Устройства'**
  String get settingsDevices;

  /// No description provided for @settingsMessages.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения'**
  String get settingsMessages;

  /// No description provided for @settingsFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get settingsFavorites;

  /// No description provided for @settingsFolders.
  ///
  /// In ru, this message translates to:
  /// **'Папки'**
  String get settingsFolders;

  /// No description provided for @settingsDataSaver.
  ///
  /// In ru, this message translates to:
  /// **'Экономия батареи и сети'**
  String get settingsDataSaver;

  /// No description provided for @settingsStorage.
  ///
  /// In ru, this message translates to:
  /// **'Память'**
  String get settingsStorage;

  /// No description provided for @settingsAppearance.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get settingsAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык приложения'**
  String get settingsLanguage;

  /// No description provided for @settingsAccounts.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунты'**
  String get settingsAccounts;

  /// No description provided for @settingsAccountsSub.
  ///
  /// In ru, this message translates to:
  /// **'Переключить · добавить'**
  String get settingsAccountsSub;

  /// No description provided for @settingsQrLogin.
  ///
  /// In ru, this message translates to:
  /// **'Вход по QR-коду'**
  String get settingsQrLogin;

  /// No description provided for @settingsQrLoginSub.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить вход другого устройства'**
  String get settingsQrLoginSub;

  /// No description provided for @settingsHelp.
  ///
  /// In ru, this message translates to:
  /// **'Помощь'**
  String get settingsHelp;

  /// No description provided for @settingsDiagnostics.
  ///
  /// In ru, this message translates to:
  /// **'Диагностика'**
  String get settingsDiagnostics;

  /// No description provided for @settingsDiagnosticsSub.
  ///
  /// In ru, this message translates to:
  /// **'Логи соединения — для разбора проблем'**
  String get settingsDiagnosticsSub;

  /// No description provided for @settingsAbout.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settingsAbout;

  /// No description provided for @settingsLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта'**
  String get settingsLogout;

  /// No description provided for @themeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get themeSystem;

  /// No description provided for @headerNoName.
  ///
  /// In ru, this message translates to:
  /// **'Без имени'**
  String get headerNoName;

  /// No description provided for @logoutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выйти?'**
  String get logoutTitle;

  /// No description provided for @logoutBody.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт исчезнет из переключателя. Его локальная история, скачанные файлы и сохранённый вход будут удалены с устройства. Другие аккаунты не затрагиваются.'**
  String get logoutBody;

  /// No description provided for @aboutSourceCode.
  ///
  /// In ru, this message translates to:
  /// **'Исходный код:'**
  String get aboutSourceCode;

  /// No description provided for @aboutNotAffiliated.
  ///
  /// In ru, this message translates to:
  /// **'Не связан с VK и разработчиками официального приложения MAX.'**
  String get aboutNotAffiliated;

  /// No description provided for @apprTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get apprTitle;

  /// No description provided for @apprTextSize.
  ///
  /// In ru, this message translates to:
  /// **'Размер текста'**
  String get apprTextSize;

  /// No description provided for @apprSystemSize.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get apprSystemSize;

  /// No description provided for @apprSystemSizeHint.
  ///
  /// In ru, this message translates to:
  /// **'Размер берётся из настроек устройства'**
  String get apprSystemSizeHint;

  /// No description provided for @apprTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get apprTheme;

  /// No description provided for @apprPreviewIncoming1.
  ///
  /// In ru, this message translates to:
  /// **'Выберите тему, чтобы изменить фон и цвет сообщений 🎨'**
  String get apprPreviewIncoming1;

  /// No description provided for @apprPreviewOutgoing.
  ///
  /// In ru, this message translates to:
  /// **'Посмотрите, как с ней будут выглядеть ваши чаты'**
  String get apprPreviewOutgoing;

  /// No description provided for @apprPreviewIncoming2.
  ///
  /// In ru, this message translates to:
  /// **'Меняйте тему в любое время'**
  String get apprPreviewIncoming2;

  /// No description provided for @langTitle.
  ///
  /// In ru, this message translates to:
  /// **'Язык приложения'**
  String get langTitle;

  /// No description provided for @langHintSystem.
  ///
  /// In ru, this message translates to:
  /// **'Изменить можно в системных настройках — найдите там «Язык» и выберите нужный'**
  String get langHintSystem;

  /// No description provided for @langHintDevice.
  ///
  /// In ru, this message translates to:
  /// **'Язык изменится только на этом устройстве'**
  String get langHintDevice;

  /// No description provided for @langOpenSettings.
  ///
  /// In ru, this message translates to:
  /// **'Изменить в настройках'**
  String get langOpenSettings;

  /// No description provided for @secTitle.
  ///
  /// In ru, this message translates to:
  /// **'Безопасность'**
  String get secTitle;

  /// No description provided for @secPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль для входа'**
  String get secPassword;

  /// No description provided for @secPasswordSub.
  ///
  /// In ru, this message translates to:
  /// **'Двухфакторная защита'**
  String get secPasswordSub;

  /// No description provided for @secFamily.
  ///
  /// In ru, this message translates to:
  /// **'Семейная защита'**
  String get secFamily;

  /// No description provided for @secFamilyOff.
  ///
  /// In ru, this message translates to:
  /// **'Отключена'**
  String get secFamilyOff;

  /// No description provided for @secSafeMode.
  ///
  /// In ru, this message translates to:
  /// **'Безопасный режим'**
  String get secSafeMode;

  /// No description provided for @secCall.
  ///
  /// In ru, this message translates to:
  /// **'Позвонить'**
  String get secCall;

  /// No description provided for @secFindByPhone.
  ///
  /// In ru, this message translates to:
  /// **'Найти меня по номеру'**
  String get secFindByPhone;

  /// No description provided for @secShowContent.
  ///
  /// In ru, this message translates to:
  /// **'Показывать контент'**
  String get secShowContent;

  /// No description provided for @secInviteToChat.
  ///
  /// In ru, this message translates to:
  /// **'Пригласить в чат'**
  String get secInviteToChat;

  /// No description provided for @secInfo.
  ///
  /// In ru, this message translates to:
  /// **'Информация'**
  String get secInfo;

  /// No description provided for @secSeeOnline.
  ///
  /// In ru, this message translates to:
  /// **'Видеть статус «в сети»'**
  String get secSeeOnline;

  /// No description provided for @secSeeNumber.
  ///
  /// In ru, this message translates to:
  /// **'Видеть мой номер'**
  String get secSeeNumber;

  /// No description provided for @secBlacklist.
  ///
  /// In ru, this message translates to:
  /// **'Чёрный список'**
  String get secBlacklist;

  /// No description provided for @secBlacklistSub.
  ///
  /// In ru, this message translates to:
  /// **'Кто не может писать, звонить и добавлять в чаты'**
  String get secBlacklistSub;

  /// No description provided for @accessAll.
  ///
  /// In ru, this message translates to:
  /// **'все'**
  String get accessAll;

  /// No description provided for @accessContacts.
  ///
  /// In ru, this message translates to:
  /// **'могут контакты'**
  String get accessContacts;

  /// No description provided for @accessNobody.
  ///
  /// In ru, this message translates to:
  /// **'никто'**
  String get accessNobody;

  /// No description provided for @visibilityAll.
  ///
  /// In ru, this message translates to:
  /// **'все'**
  String get visibilityAll;

  /// No description provided for @visibilityContacts.
  ///
  /// In ru, this message translates to:
  /// **'контакты'**
  String get visibilityContacts;

  /// No description provided for @visibilityNobody.
  ///
  /// In ru, this message translates to:
  /// **'никто'**
  String get visibilityNobody;

  /// No description provided for @dsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Экономия батареи и сети'**
  String get dsTitle;

  /// No description provided for @dsPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get dsPhoto;

  /// No description provided for @dsVideo.
  ///
  /// In ru, this message translates to:
  /// **'Видео'**
  String get dsVideo;

  /// No description provided for @dsGif.
  ///
  /// In ru, this message translates to:
  /// **'Гифки'**
  String get dsGif;

  /// No description provided for @dsAudioMessages.
  ///
  /// In ru, this message translates to:
  /// **'Аудиосообщения'**
  String get dsAudioMessages;

  /// No description provided for @dsAutoload.
  ///
  /// In ru, this message translates to:
  /// **'Автозагрузка'**
  String get dsAutoload;

  /// No description provided for @dsSendQuality.
  ///
  /// In ru, this message translates to:
  /// **'Качество при отправке'**
  String get dsSendQuality;

  /// No description provided for @dsAutoplay.
  ///
  /// In ru, this message translates to:
  /// **'Автовоспроизведение'**
  String get dsAutoplay;

  /// No description provided for @autoAlways.
  ///
  /// In ru, this message translates to:
  /// **'Всегда'**
  String get autoAlways;

  /// No description provided for @autoWifi.
  ///
  /// In ru, this message translates to:
  /// **'По Wi-Fi'**
  String get autoWifi;

  /// No description provided for @autoNever.
  ///
  /// In ru, this message translates to:
  /// **'Никогда'**
  String get autoNever;

  /// No description provided for @stTitle.
  ///
  /// In ru, this message translates to:
  /// **'Память'**
  String get stTitle;

  /// No description provided for @stKeepMedia.
  ///
  /// In ru, this message translates to:
  /// **'Хранить медиа в кэше устройства'**
  String get stKeepMedia;

  /// No description provided for @stKeepMediaSub.
  ///
  /// In ru, this message translates to:
  /// **'После удаления медиа можно загрузить снова'**
  String get stKeepMediaSub;

  /// No description provided for @stData.
  ///
  /// In ru, this message translates to:
  /// **'Данные'**
  String get stData;

  /// No description provided for @stStickers.
  ///
  /// In ru, this message translates to:
  /// **'Стикеры'**
  String get stStickers;

  /// No description provided for @stPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get stPhoto;

  /// No description provided for @stAudioMessages.
  ///
  /// In ru, this message translates to:
  /// **'Аудиосообщения'**
  String get stAudioMessages;

  /// No description provided for @stClearCache.
  ///
  /// In ru, this message translates to:
  /// **'Очистить кэш'**
  String get stClearCache;

  /// No description provided for @keepWeek.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get keepWeek;

  /// No description provided for @keepMonth.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get keepMonth;

  /// No description provided for @keepYear.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get keepYear;

  /// No description provided for @keepForever.
  ///
  /// In ru, this message translates to:
  /// **'Всегда'**
  String get keepForever;

  /// No description provided for @devTitle.
  ///
  /// In ru, this message translates to:
  /// **'Устройства'**
  String get devTitle;

  /// No description provided for @devHeaderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Устройства с MAX'**
  String get devHeaderTitle;

  /// No description provided for @devHeaderSub.
  ///
  /// In ru, this message translates to:
  /// **'Входите на новых устройствах\nи управляйте сессиями'**
  String get devHeaderSub;

  /// No description provided for @devCurrent.
  ///
  /// In ru, this message translates to:
  /// **'текущая'**
  String get devCurrent;

  /// No description provided for @devOnline.
  ///
  /// In ru, this message translates to:
  /// **'В сети'**
  String get devOnline;

  /// No description provided for @devTerminate.
  ///
  /// In ru, this message translates to:
  /// **'Завершить'**
  String get devTerminate;

  /// No description provided for @devTerminateAll.
  ///
  /// In ru, this message translates to:
  /// **'Завершить все сессии, кроме текущей'**
  String get devTerminateAll;

  /// No description provided for @devQrLogin.
  ///
  /// In ru, this message translates to:
  /// **'Войти по QR-коду'**
  String get devQrLogin;

  /// No description provided for @devEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Активных сессий не найдено'**
  String get devEmpty;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'ru':
      return LRu();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

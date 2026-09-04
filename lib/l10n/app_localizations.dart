import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('uk'),
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

  /// No description provided for @navContacts.
  ///
  /// In ru, this message translates to:
  /// **'Контакты'**
  String get navContacts;

  /// No description provided for @navCalls.
  ///
  /// In ru, this message translates to:
  /// **'Звонки'**
  String get navCalls;

  /// No description provided for @navChats.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get navChats;

  /// No description provided for @navSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get navSettings;

  /// No description provided for @loginBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get loginBack;

  /// No description provided for @loginPhoneTitle.
  ///
  /// In ru, this message translates to:
  /// **'Max Vektor'**
  String get loginPhoneTitle;

  /// No description provided for @loginCodeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите код'**
  String get loginCodeTitle;

  /// No description provided for @loginNameTitle.
  ///
  /// In ru, this message translates to:
  /// **'Как вас зовут?'**
  String get loginNameTitle;

  /// No description provided for @login2faTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пароль двухфакторной защиты'**
  String get login2faTitle;

  /// No description provided for @loginTokenTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход по токену'**
  String get loginTokenTitle;

  /// No description provided for @loginPhonePrompt.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер телефона — пришлём код подтверждения.'**
  String get loginPhonePrompt;

  /// No description provided for @loginCodePrompt.
  ///
  /// In ru, this message translates to:
  /// **'Отправили код на {phone}. Он приходит в SMS или в официальное приложение MAX.'**
  String loginCodePrompt(Object phone);

  /// No description provided for @loginNamePrompt.
  ///
  /// In ru, this message translates to:
  /// **'Этого номера ещё нет в MAX. Укажите имя — и аккаунт будет создан.'**
  String get loginNamePrompt;

  /// No description provided for @login2faPrompt.
  ///
  /// In ru, this message translates to:
  /// **'На аккаунте включён пароль. Введите его, чтобы завершить вход.'**
  String get login2faPrompt;

  /// No description provided for @loginPhoneField.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона'**
  String get loginPhoneField;

  /// No description provided for @loginGetCode.
  ///
  /// In ru, this message translates to:
  /// **'Получить код'**
  String get loginGetCode;

  /// No description provided for @loginConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get loginConfirm;

  /// No description provided for @loginResendIn.
  ///
  /// In ru, this message translates to:
  /// **'Запросить код заново через {seconds} с'**
  String loginResendIn(Object seconds);

  /// No description provided for @loginResend.
  ///
  /// In ru, this message translates to:
  /// **'Запросить код заново'**
  String get loginResend;

  /// No description provided for @loginAttemptsLeft.
  ///
  /// In ru, this message translates to:
  /// **'Осталось запросов кода: {count}'**
  String loginAttemptsLeft(Object count);

  /// No description provided for @loginFirstName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get loginFirstName;

  /// No description provided for @loginLastNameOptional.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия (необязательно)'**
  String get loginLastNameOptional;

  /// No description provided for @loginNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Не короче двух символов, только буквы — без цифр, эмодзи и знаков препинания.'**
  String get loginNameHint;

  /// No description provided for @loginCreateAccount.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get loginCreateAccount;

  /// No description provided for @loginNameTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Имя должно быть не короче двух букв'**
  String get loginNameTooShort;

  /// No description provided for @loginPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get loginPassword;

  /// No description provided for @loginHide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get loginHide;

  /// No description provided for @loginShow.
  ///
  /// In ru, this message translates to:
  /// **'Показать'**
  String get loginShow;

  /// No description provided for @loginSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get loginSignIn;

  /// No description provided for @loginTokenHint.
  ///
  /// In ru, this message translates to:
  /// **'Вставьте токен сюда…'**
  String get loginTokenHint;

  /// No description provided for @loginTokenButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти по токену'**
  String get loginTokenButton;

  /// No description provided for @loginChangeNumber.
  ///
  /// In ru, this message translates to:
  /// **'Изменить номер'**
  String get loginChangeNumber;

  /// No description provided for @loginNameVisibleHint.
  ///
  /// In ru, this message translates to:
  /// **'Имя увидят собеседники в MAX. Его можно изменить позже в настройках профиля.'**
  String get loginNameVisibleHint;

  /// No description provided for @loginByPhone.
  ///
  /// In ru, this message translates to:
  /// **'Войти по номеру телефона'**
  String get loginByPhone;

  /// No description provided for @loginHaveToken.
  ///
  /// In ru, this message translates to:
  /// **'У меня есть auth-token'**
  String get loginHaveToken;

  /// No description provided for @loginSearchCountry.
  ///
  /// In ru, this message translates to:
  /// **'Поиск страны или кода'**
  String get loginSearchCountry;

  /// No description provided for @commonSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get commonSearch;

  /// No description provided for @commonContinue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get commonContinue;

  /// No description provided for @commonFind.
  ///
  /// In ru, this message translates to:
  /// **'Найти'**
  String get commonFind;

  /// No description provided for @commonNothingFound.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get commonNothingFound;

  /// No description provided for @commonError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String commonError(Object error);

  /// No description provided for @chatsArchive.
  ///
  /// In ru, this message translates to:
  /// **'Архив'**
  String get chatsArchive;

  /// No description provided for @chatsArchiveEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Архив пока пуст'**
  String get chatsArchiveEmpty;

  /// No description provided for @chatsNewChat.
  ///
  /// In ru, this message translates to:
  /// **'Новый чат'**
  String get chatsNewChat;

  /// No description provided for @chatsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Чатов пока нет'**
  String get chatsEmpty;

  /// No description provided for @chatsEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на кнопку справа внизу,\nчтобы начать новый чат.'**
  String get chatsEmptyHint;

  /// No description provided for @searchTryAnother.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте другой запрос.'**
  String get searchTryAnother;

  /// No description provided for @chatPin.
  ///
  /// In ru, this message translates to:
  /// **'Закрепить'**
  String get chatPin;

  /// No description provided for @chatUnpin.
  ///
  /// In ru, this message translates to:
  /// **'Открепить'**
  String get chatUnpin;

  /// No description provided for @chatEnableNotif.
  ///
  /// In ru, this message translates to:
  /// **'Включить уведомления'**
  String get chatEnableNotif;

  /// No description provided for @chatDisableNotif.
  ///
  /// In ru, this message translates to:
  /// **'Отключить уведомления'**
  String get chatDisableNotif;

  /// No description provided for @chatArchive.
  ///
  /// In ru, this message translates to:
  /// **'Архивировать'**
  String get chatArchive;

  /// No description provided for @chatUnarchive.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть из архива'**
  String get chatUnarchive;

  /// No description provided for @chatMarkRead.
  ///
  /// In ru, this message translates to:
  /// **'Прочитано'**
  String get chatMarkRead;

  /// No description provided for @dateYesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get dateYesterday;

  /// No description provided for @contactsHideSearch.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть поиск'**
  String get contactsHideSearch;

  /// No description provided for @contactsImport.
  ///
  /// In ru, this message translates to:
  /// **'Импорт из адресной книги'**
  String get contactsImport;

  /// No description provided for @contactsAddByNumber.
  ///
  /// In ru, this message translates to:
  /// **'Добавить по номеру'**
  String get contactsAddByNumber;

  /// No description provided for @contactsDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить контакт?'**
  String get contactsDeleteTitle;

  /// No description provided for @contactPlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Контакт {id}'**
  String contactPlaceholder(Object id);

  /// No description provided for @contactDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Контакт удалён'**
  String get contactDeleted;

  /// No description provided for @contactsImportTitle.
  ///
  /// In ru, this message translates to:
  /// **'Импорт контактов'**
  String get contactsImportTitle;

  /// No description provided for @contactsImportWarn.
  ///
  /// In ru, this message translates to:
  /// **'MAX считает массовую проверку номеров подозрительной и может заблокировать номер. Чтобы снизить риск, проверю не больше {cap} номеров, по одному раз в ~1.5 секунды. Это займёт около минуты. Продолжить?'**
  String contactsImportWarn(Object cap);

  /// No description provided for @contactsReadingBook.
  ///
  /// In ru, this message translates to:
  /// **'Чтение адресной книги…'**
  String get contactsReadingBook;

  /// No description provided for @contactsChecking.
  ///
  /// In ru, this message translates to:
  /// **'Проверка: {done} из {total}'**
  String contactsChecking(Object done, Object total);

  /// No description provided for @contactsFoundInMax.
  ///
  /// In ru, this message translates to:
  /// **'Найдено в MAX: {found} из {checked}'**
  String contactsFoundInMax(Object found, Object checked);

  /// No description provided for @contactsFindByNumber.
  ///
  /// In ru, this message translates to:
  /// **'Найти по номеру'**
  String get contactsFindByNumber;

  /// No description provided for @contactsPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get contactsPhone;

  /// No description provided for @contactsFound.
  ///
  /// In ru, this message translates to:
  /// **'Найден: {name}'**
  String contactsFound(Object name);

  /// No description provided for @contactsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Контактов нет. Импортируйте адресную книгу или добавьте номер вручную.'**
  String get contactsEmpty;

  /// No description provided for @callsCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создать звонок'**
  String get callsCreate;

  /// No description provided for @callsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'История звонков пуста'**
  String get callsEmpty;

  /// No description provided for @callsEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Голосовые и видеозвонки появятся в одном из следующих обновлений.'**
  String get callsEmptyHint;

  /// No description provided for @callMissed.
  ///
  /// In ru, this message translates to:
  /// **'Пропущенный'**
  String get callMissed;

  /// No description provided for @callIncoming.
  ///
  /// In ru, this message translates to:
  /// **'Входящий'**
  String get callIncoming;

  /// No description provided for @callOutgoing.
  ///
  /// In ru, this message translates to:
  /// **'Исходящий'**
  String get callOutgoing;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// No description provided for @profileSaved.
  ///
  /// In ru, this message translates to:
  /// **'Профиль сохранён'**
  String get profileSaved;

  /// No description provided for @profileLastName.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get profileLastName;

  /// No description provided for @profileAbout.
  ///
  /// In ru, this message translates to:
  /// **'О себе'**
  String get profileAbout;

  /// No description provided for @profileDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить профиль'**
  String get profileDelete;

  /// No description provided for @profileLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из профиля'**
  String get profileLogout;

  /// No description provided for @profileDeleteInactive.
  ///
  /// In ru, this message translates to:
  /// **'Удалить профиль, если он неактивен'**
  String get profileDeleteInactive;

  /// No description provided for @profileTtlUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Срок обновлён'**
  String get profileTtlUpdated;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из профиля?'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutBody.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт исчезнет из переключателя. Его локальные данные будут удалены с устройства. Другие аккаунты не затрагиваются.'**
  String get profileLogoutBody;

  /// No description provided for @commonRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get commonRefresh;

  /// No description provided for @commonClear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get commonClear;

  /// No description provided for @chatMember.
  ///
  /// In ru, this message translates to:
  /// **'Участник {id}'**
  String chatMember(Object id);

  /// No description provided for @chatLastSeenRecently.
  ///
  /// In ru, this message translates to:
  /// **'был(а) недавно'**
  String get chatLastSeenRecently;

  /// No description provided for @chatMembersCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} участн.'**
  String chatMembersCount(Object count);

  /// No description provided for @chatTitlePlaceholder.
  ///
  /// In ru, this message translates to:
  /// **'Чат {id}'**
  String chatTitlePlaceholder(Object id);

  /// No description provided for @chatEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Сообщений пока нет'**
  String get chatEmpty;

  /// No description provided for @chatVideoCall.
  ///
  /// In ru, this message translates to:
  /// **'Видеозвонок'**
  String get chatVideoCall;

  /// No description provided for @chatCall.
  ///
  /// In ru, this message translates to:
  /// **'Звонок'**
  String get chatCall;

  /// No description provided for @chatMedia.
  ///
  /// In ru, this message translates to:
  /// **'Медиа чата'**
  String get chatMedia;

  /// No description provided for @chatNewMessages.
  ///
  /// In ru, this message translates to:
  /// **'Новые сообщения'**
  String get chatNewMessages;

  /// No description provided for @chatReplyTo.
  ///
  /// In ru, this message translates to:
  /// **'Ответ на:'**
  String get chatReplyTo;

  /// No description provided for @chatReplyCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отменить ответ'**
  String get chatReplyCancel;

  /// No description provided for @forwardUnknownUser.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get forwardUnknownUser;

  /// No description provided for @msgReply.
  ///
  /// In ru, this message translates to:
  /// **'Ответить'**
  String get msgReply;

  /// No description provided for @msgCopy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get msgCopy;

  /// No description provided for @msgForward.
  ///
  /// In ru, this message translates to:
  /// **'Переслать'**
  String get msgForward;

  /// No description provided for @msgEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get msgEdit;

  /// No description provided for @msgEditHint.
  ///
  /// In ru, this message translates to:
  /// **'Новый текст'**
  String get msgEditHint;

  /// No description provided for @msgCopied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано'**
  String get msgCopied;

  /// No description provided for @msgReplyNotConfirmed.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя ответить: сообщение ещё не подтверждено сервером'**
  String get msgReplyNotConfirmed;

  /// No description provided for @msgForwardTextOnly.
  ///
  /// In ru, this message translates to:
  /// **'Пока пересылаются только текстовые сообщения'**
  String get msgForwardTextOnly;

  /// No description provided for @sendAttachFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить вложение'**
  String get sendAttachFailed;

  /// No description provided for @diagHint.
  ///
  /// In ru, this message translates to:
  /// **'Логи соединения и протокола ({count} строк). Токены и коды не записываются. Скопируйте и пришлите для разбора проблемы.'**
  String diagHint(Object count);

  /// No description provided for @diagEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Логов пока нет.'**
  String get diagEmpty;

  /// No description provided for @diagCopyAll.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать всё'**
  String get diagCopyAll;

  /// No description provided for @diagCopied.
  ///
  /// In ru, this message translates to:
  /// **'Логи скопированы'**
  String get diagCopied;

  /// No description provided for @qrConfirming.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждаем вход…'**
  String get qrConfirming;

  /// No description provided for @qrDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово. Вход на другом устройстве подтверждён.'**
  String get qrDone;

  /// No description provided for @qrHint.
  ///
  /// In ru, this message translates to:
  /// **'Наведите камеру на QR-код со страницы входа MAX на другом устройстве (например web.max.ru). Ваш аккаунт подтвердит вход.'**
  String get qrHint;

  /// No description provided for @videoError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось воспроизвести видео'**
  String get videoError;

  /// No description provided for @videoTitle.
  ///
  /// In ru, this message translates to:
  /// **'Видео'**
  String get videoTitle;

  /// No description provided for @connConnecting.
  ///
  /// In ru, this message translates to:
  /// **'Подключение…'**
  String get connConnecting;

  /// No description provided for @connReconnecting.
  ///
  /// In ru, this message translates to:
  /// **'Переподключение…'**
  String get connReconnecting;

  /// No description provided for @connNoConnection.
  ///
  /// In ru, this message translates to:
  /// **'Нет соединения'**
  String get connNoConnection;

  /// No description provided for @inputAttach.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепить'**
  String get inputAttach;

  /// No description provided for @inputMessage.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get inputMessage;

  /// No description provided for @attachPhotoGallery.
  ///
  /// In ru, this message translates to:
  /// **'Фото из галереи'**
  String get attachPhotoGallery;

  /// No description provided for @attachVideoGallery.
  ///
  /// In ru, this message translates to:
  /// **'Видео из галереи'**
  String get attachVideoGallery;

  /// No description provided for @attachTakePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Снять фото'**
  String get attachTakePhoto;

  /// No description provided for @attachTakeVideo.
  ///
  /// In ru, this message translates to:
  /// **'Снять видео'**
  String get attachTakeVideo;

  /// No description provided for @attachFile.
  ///
  /// In ru, this message translates to:
  /// **'Файл'**
  String get attachFile;

  /// No description provided for @devLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить сессии:\n{error}'**
  String devLoadFailed(Object error);

  /// No description provided for @fwdPickTitle.
  ///
  /// In ru, this message translates to:
  /// **'Переслать в'**
  String get fwdPickTitle;

  /// No description provided for @fwdSearchChat.
  ///
  /// In ru, this message translates to:
  /// **'Поиск чата'**
  String get fwdSearchChat;

  /// No description provided for @fwdForwardedTo.
  ///
  /// In ru, this message translates to:
  /// **'Переслано в {target}'**
  String fwdForwardedTo(Object target);

  /// No description provided for @galleryEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Медиа пока нет'**
  String get galleryEmpty;

  /// No description provided for @profChat.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get profChat;

  /// No description provided for @profMediaFilesLinks.
  ///
  /// In ru, this message translates to:
  /// **'Медиа, файлы и ссылки'**
  String get profMediaFilesLinks;

  /// No description provided for @profNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get profNotifications;

  /// No description provided for @profEnabled.
  ///
  /// In ru, this message translates to:
  /// **'Включены'**
  String get profEnabled;

  /// No description provided for @profPinChat.
  ///
  /// In ru, this message translates to:
  /// **'Закрепить чат'**
  String get profPinChat;

  /// No description provided for @profClearHistory.
  ///
  /// In ru, this message translates to:
  /// **'Очистить историю'**
  String get profClearHistory;

  /// No description provided for @profClearHistoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Очистить историю?'**
  String get profClearHistoryTitle;

  /// No description provided for @profHistoryCleared.
  ///
  /// In ru, this message translates to:
  /// **'История очищена локально'**
  String get profHistoryCleared;

  /// No description provided for @accAddAccount.
  ///
  /// In ru, this message translates to:
  /// **'Добавить аккаунт'**
  String get accAddAccount;

  /// No description provided for @accLogoutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из «{name}»?'**
  String accLogoutTitle(Object name);

  /// No description provided for @transcribe.
  ///
  /// In ru, this message translates to:
  /// **'Расшифровать'**
  String get transcribe;

  /// No description provided for @transcribeEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Расшифровка пуста'**
  String get transcribeEmpty;

  /// No description provided for @audioUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Аудио недоступно'**
  String get audioUnavailable;

  /// No description provided for @audioPlayFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось воспроизвести аудио'**
  String get audioPlayFailed;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'pt',
    'ru',
    'tr',
    'uk',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return LDe();
    case 'en':
      return LEn();
    case 'es':
      return LEs();
    case 'fr':
      return LFr();
    case 'it':
      return LIt();
    case 'pt':
      return LPt();
    case 'ru':
      return LRu();
    case 'tr':
      return LTr();
    case 'uk':
      return LUk();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

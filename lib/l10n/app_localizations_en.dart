// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonDone => 'Done';

  @override
  String get commonLogout => 'Log out';

  @override
  String get commonSoon => 'Coming soon';

  @override
  String get settingsNotifications => 'Notifications and sound';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsSecuritySub => 'Two-factor protection, sessions';

  @override
  String get settingsDevices => 'Devices';

  @override
  String get settingsMessages => 'Messages';

  @override
  String get settingsFavorites => 'Favorites';

  @override
  String get settingsFolders => 'Folders';

  @override
  String get settingsDataSaver => 'Battery and network saving';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'App language';

  @override
  String get settingsAccounts => 'Accounts';

  @override
  String get settingsAccountsSub => 'Switch · add';

  @override
  String get settingsQrLogin => 'Log in with QR code';

  @override
  String get settingsQrLoginSub => 'Approve another device\'s login';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsDiagnostics => 'Diagnostics';

  @override
  String get settingsDiagnosticsSub => 'Connection logs — for troubleshooting';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsLogout => 'Log out of account';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get headerNoName => 'No name';

  @override
  String get logoutTitle => 'Log out?';

  @override
  String get logoutBody =>
      'The account will disappear from the switcher. Its local history, downloaded files and saved login will be removed from this device. Other accounts are not affected.';

  @override
  String get aboutSourceCode => 'Source code:';

  @override
  String get aboutNotAffiliated =>
      'Not affiliated with VK or the developers of the official MAX app.';

  @override
  String get apprTitle => 'Appearance';

  @override
  String get apprTextSize => 'Text size';

  @override
  String get apprSystemSize => 'Match system';

  @override
  String get apprSystemSizeHint => 'Size is taken from device settings';

  @override
  String get apprTheme => 'Theme';

  @override
  String get apprPreviewIncoming1 =>
      'Pick a theme to change the background and message colors 🎨';

  @override
  String get apprPreviewOutgoing => 'See how your chats will look with it';

  @override
  String get apprPreviewIncoming2 => 'Change the theme anytime';

  @override
  String get langTitle => 'App language';

  @override
  String get langSystem => 'System language';

  @override
  String get langHintSystem =>
      'You can change it in system settings — find “Language” there and pick one';

  @override
  String get langHintDevice => 'The language changes only on this device';

  @override
  String get langOpenSettings => 'Change in settings';

  @override
  String get secTitle => 'Security';

  @override
  String get secPassword => 'Login password';

  @override
  String get secPasswordSub => 'Two-factor protection';

  @override
  String get pwdTitle => 'Login password';

  @override
  String get pwdStateOn => 'Password set';

  @override
  String get pwdStateOff => 'Not set';

  @override
  String get pwdDesc => 'Required when signing in from a new device.';

  @override
  String get pwdNew => 'New password';

  @override
  String get pwdRepeat => 'Repeat password';

  @override
  String get pwdHintLabel => 'Hint (optional)';

  @override
  String get pwdHintDesc =>
      'The hint appears on the login screen to help you remember the password.';

  @override
  String get pwdSave => 'Save';

  @override
  String get pwdSaving => 'Saving…';

  @override
  String get pwdSaved => 'Password saved';

  @override
  String get pwdMismatch => 'Passwords do not match';

  @override
  String pwdTooShort(int n) {
    return 'At least $n characters';
  }

  @override
  String pwdTooLong(int n) {
    return 'At most $n characters';
  }

  @override
  String pwdHintTooLong(int n) {
    return 'Hint at most $n characters';
  }

  @override
  String get secFamily => 'Family protection';

  @override
  String get secFamilyOff => 'Off';

  @override
  String get secSafeMode => 'Safe mode';

  @override
  String get secCall => 'Call me';

  @override
  String get secFindByPhone => 'Find me by number';

  @override
  String get secShowContent => 'Show content';

  @override
  String get secInviteToChat => 'Invite to chat';

  @override
  String get secInfo => 'Information';

  @override
  String get secSeeOnline => 'See “online” status';

  @override
  String get secSeeNumber => 'See my number';

  @override
  String get secBlacklist => 'Blacklist';

  @override
  String get secBlacklistSub => 'Who can\'t message, call or add to chats';

  @override
  String get blEmpty => 'Blacklist is empty';

  @override
  String get blDesc =>
      'Blocked people can’t message, call or add you to chats.';

  @override
  String get blUnblock => 'Unblock';

  @override
  String get blAdd => 'Block a contact';

  @override
  String get blNoContacts => 'No contacts to block';

  @override
  String get blSearch => 'Search';

  @override
  String get accessAll => 'everyone';

  @override
  String get accessContacts => 'contacts can';

  @override
  String get accessNobody => 'nobody';

  @override
  String get visibilityAll => 'everyone';

  @override
  String get visibilityContacts => 'contacts';

  @override
  String get visibilityNobody => 'nobody';

  @override
  String get dsTitle => 'Battery and network saving';

  @override
  String get dsPhoto => 'Photo';

  @override
  String get dsVideo => 'Video';

  @override
  String get dsGif => 'GIFs';

  @override
  String get dsAudioMessages => 'Voice messages';

  @override
  String get dsAutoload => 'Auto-download';

  @override
  String get dsSendQuality => 'Quality on sending';

  @override
  String get dsAutoplay => 'Autoplay';

  @override
  String get autoAlways => 'Always';

  @override
  String get autoWifi => 'On Wi-Fi';

  @override
  String get autoNever => 'Never';

  @override
  String get stTitle => 'Storage';

  @override
  String get stKeepMedia => 'Keep media in device cache';

  @override
  String get stKeepMediaSub => 'After deletion, media can be downloaded again';

  @override
  String get stData => 'Data';

  @override
  String get stStickers => 'Stickers';

  @override
  String get stPhoto => 'Photo';

  @override
  String get stAudioMessages => 'Voice messages';

  @override
  String get stClearCache => 'Clear cache';

  @override
  String get keepWeek => 'Week';

  @override
  String get keepMonth => 'Month';

  @override
  String get keepYear => 'Year';

  @override
  String get keepForever => 'Forever';

  @override
  String get devTitle => 'Devices';

  @override
  String get devHeaderTitle => 'Devices with MAX';

  @override
  String get devHeaderSub => 'Log in on new devices\nand manage sessions';

  @override
  String get devCurrent => 'current';

  @override
  String get devOnline => 'Online';

  @override
  String get devUnknownDevice => 'Unknown device';

  @override
  String get devTerminate => 'Terminate';

  @override
  String get devTerminateAll => 'Terminate all sessions except the current one';

  @override
  String get devQrLogin => 'Log in with QR code';

  @override
  String get devEmpty => 'No active sessions found';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navCalls => 'Calls';

  @override
  String get navChats => 'Chats';

  @override
  String get navSettings => 'Settings';

  @override
  String get loginBack => 'Back';

  @override
  String get loginPhoneTitle => 'Max Vektor';

  @override
  String get loginCodeTitle => 'Enter the code';

  @override
  String get loginNameTitle => 'What\'s your name?';

  @override
  String get login2faTitle => 'Two-factor password';

  @override
  String get loginTokenTitle => 'Log in with token';

  @override
  String get loginPhonePrompt =>
      'Enter your phone number — we\'ll send a confirmation code.';

  @override
  String loginCodePrompt(Object phone) {
    return 'We sent a code to $phone. It arrives by SMS or in the official MAX app.';
  }

  @override
  String get loginNamePrompt =>
      'This number isn\'t in MAX yet. Enter a name — and an account will be created.';

  @override
  String get login2faPrompt =>
      'This account has a password. Enter it to finish signing in.';

  @override
  String get loginPhoneField => 'Phone number';

  @override
  String get loginGetCode => 'Get the code';

  @override
  String get loginConfirm => 'Confirm';

  @override
  String loginResendIn(Object seconds) {
    return 'Request a new code in ${seconds}s';
  }

  @override
  String get loginResend => 'Request a new code';

  @override
  String loginAttemptsLeft(Object count) {
    return 'Code requests left: $count';
  }

  @override
  String get loginFirstName => 'First name';

  @override
  String get loginLastNameOptional => 'Last name (optional)';

  @override
  String get loginNameHint =>
      'At least two characters, letters only — no digits, emoji or punctuation.';

  @override
  String get loginCreateAccount => 'Create account';

  @override
  String get loginNameTooShort => 'The name must be at least two letters';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginHide => 'Hide';

  @override
  String get loginShow => 'Show';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginTokenHint => 'Paste the token here…';

  @override
  String get loginTokenButton => 'Log in with token';

  @override
  String get loginChangeNumber => 'Change number';

  @override
  String get loginNameVisibleHint =>
      'Others in MAX will see your name. You can change it later in profile settings.';

  @override
  String get loginByPhone => 'Log in with phone number';

  @override
  String get loginHaveToken => 'I have an auth token';

  @override
  String get loginSearchCountry => 'Search country or code';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonFind => 'Find';

  @override
  String get commonNothingFound => 'Nothing found';

  @override
  String commonError(Object error) {
    return 'Error: $error';
  }

  @override
  String get chatsArchive => 'Archive';

  @override
  String get chatsArchiveEmpty => 'The archive is empty';

  @override
  String get chatsNewChat => 'New chat';

  @override
  String get chatsEmpty => 'No chats yet';

  @override
  String get chatsEmptyHint =>
      'Tap the button at the bottom right\nto start a new chat.';

  @override
  String get searchTryAnother => 'Try another query.';

  @override
  String get chatPin => 'Pin';

  @override
  String get chatUnpin => 'Unpin';

  @override
  String get chatEnableNotif => 'Enable notifications';

  @override
  String get chatDisableNotif => 'Mute notifications';

  @override
  String get chatArchive => 'Archive';

  @override
  String get chatUnarchive => 'Unarchive';

  @override
  String get chatMarkRead => 'Mark read';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get contactsHideSearch => 'Hide search';

  @override
  String get contactsImport => 'Import from address book';

  @override
  String get contactsAddByNumber => 'Add by number';

  @override
  String get contactsDeleteTitle => 'Delete contact?';

  @override
  String contactPlaceholder(Object id) {
    return 'Contact $id';
  }

  @override
  String get contactDeleted => 'Contact deleted';

  @override
  String get contactsImportTitle => 'Import contacts';

  @override
  String contactsImportWarn(Object cap) {
    return 'MAX treats bulk number lookups as suspicious and may block the number. To reduce the risk, I\'ll check no more than $cap numbers, one at a time about every ~1.5 seconds. This takes about a minute. Continue?';
  }

  @override
  String get contactsReadingBook => 'Reading address book…';

  @override
  String contactsChecking(Object done, Object total) {
    return 'Checking: $done of $total';
  }

  @override
  String contactsFoundInMax(Object found, Object checked) {
    return 'Found in MAX: $found of $checked';
  }

  @override
  String get contactsFindByNumber => 'Find by number';

  @override
  String get contactsPhone => 'Phone';

  @override
  String contactsFound(Object name) {
    return 'Found: $name';
  }

  @override
  String get contactsEmpty =>
      'No contacts. Import your address book or add a number manually.';

  @override
  String get contactsSectionInMax => 'On MAX';

  @override
  String get contactsSectionInvite => 'Invite to Max Vektor';

  @override
  String get contactsInviteBtn => 'Invite';

  @override
  String get contactsInviteCopied => 'Invitation copied';

  @override
  String get contactsNoAccessTitle => 'No access to contacts';

  @override
  String get contactsNoAccessSub =>
      'Grant access to see which of your contacts are already on MAX.';

  @override
  String get contactsGrantAccess => 'Grant access';

  @override
  String get contactsSyncing => 'Syncing contacts…';

  @override
  String contactsInviteText(String name) {
    return '$name, let’s chat on the MAX messenger!';
  }

  @override
  String get callsCreate => 'Start a call';

  @override
  String get callsEmpty => 'Call history is empty';

  @override
  String get callsEmptyHint =>
      'Voice and video calls will arrive in an upcoming update.';

  @override
  String get callMissed => 'Missed';

  @override
  String get callIncoming => 'Incoming';

  @override
  String get callOutgoing => 'Outgoing';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileLastName => 'Last name';

  @override
  String get profileAbout => 'About';

  @override
  String get profileDelete => 'Delete profile';

  @override
  String get profileLogout => 'Log out of profile';

  @override
  String get profileDeleteInactive => 'Delete profile if inactive';

  @override
  String get profileTtlUpdated => 'Period updated';

  @override
  String get profileLogoutTitle => 'Log out of profile?';

  @override
  String get profileLogoutBody =>
      'The account will disappear from the switcher. Its local data will be removed from this device. Other accounts are not affected.';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonClear => 'Clear';

  @override
  String chatMember(Object id) {
    return 'Member $id';
  }

  @override
  String get chatLastSeenRecently => 'last seen recently';

  @override
  String chatMembersCount(Object count) {
    return '$count members';
  }

  @override
  String chatTitlePlaceholder(Object id) {
    return 'Chat $id';
  }

  @override
  String get chatEmpty => 'No messages yet';

  @override
  String get chatVideoCall => 'Video call';

  @override
  String get chatCall => 'Call';

  @override
  String get chatMedia => 'Chat media';

  @override
  String get chatNewMessages => 'New messages';

  @override
  String get chatReplyTo => 'Reply to:';

  @override
  String get chatReplyCancel => 'Cancel reply';

  @override
  String get forwardUnknownUser => 'User';

  @override
  String get msgReply => 'Reply';

  @override
  String get msgCopy => 'Copy';

  @override
  String get msgForward => 'Forward';

  @override
  String get msgEdit => 'Edit';

  @override
  String get msgEditHint => 'New text';

  @override
  String get msgCopied => 'Copied';

  @override
  String get msgReplyNotConfirmed =>
      'Can\'t reply: the message isn\'t confirmed by the server yet';

  @override
  String get msgForwardTextOnly =>
      'Only text messages can be forwarded for now';

  @override
  String get sendAttachFailed => 'Couldn\'t send the attachment';

  @override
  String diagHint(Object count) {
    return 'Connection and protocol logs ($count lines). Tokens and codes are not recorded. Copy and send them for troubleshooting.';
  }

  @override
  String get diagEmpty => 'No logs yet.';

  @override
  String get diagCopyAll => 'Copy all';

  @override
  String get diagCopied => 'Logs copied';

  @override
  String get qrConfirming => 'Confirming login…';

  @override
  String get qrDone => 'Done. Login on the other device is confirmed.';

  @override
  String get qrHint =>
      'Point the camera at the QR code on the MAX login page on another device (for example web.max.ru). Your account will confirm the login.';

  @override
  String get videoError => 'Couldn\'t play the video';

  @override
  String get videoTitle => 'Video';

  @override
  String get connConnecting => 'Connecting…';

  @override
  String get connReconnecting => 'Reconnecting…';

  @override
  String get connNoConnection => 'No connection';

  @override
  String get inputAttach => 'Attach';

  @override
  String get inputMessage => 'Message';

  @override
  String get attachPhotoGallery => 'Photo from gallery';

  @override
  String get attachVideoGallery => 'Video from gallery';

  @override
  String get attachTakePhoto => 'Take a photo';

  @override
  String get attachTakeVideo => 'Record a video';

  @override
  String get attachFile => 'File';

  @override
  String devLoadFailed(Object error) {
    return 'Couldn\'t load sessions:\n$error';
  }

  @override
  String get fwdPickTitle => 'Forward to';

  @override
  String get fwdSearchChat => 'Search chat';

  @override
  String fwdForwardedTo(Object target) {
    return 'Forwarded to $target';
  }

  @override
  String get galleryEmpty => 'No media yet';

  @override
  String get profChat => 'Chat';

  @override
  String get profMediaFilesLinks => 'Media, files and links';

  @override
  String get profNotifications => 'Notifications';

  @override
  String get profEnabled => 'On';

  @override
  String get profPinChat => 'Pin chat';

  @override
  String get profClearHistory => 'Clear history';

  @override
  String get profClearHistoryTitle => 'Clear history?';

  @override
  String get profHistoryCleared => 'History cleared locally';

  @override
  String get accAddAccount => 'Add account';

  @override
  String accLogoutTitle(Object name) {
    return 'Log out of “$name”?';
  }

  @override
  String get transcribe => 'Transcribe';

  @override
  String get transcribeEmpty => 'Transcript is empty';

  @override
  String get audioUnavailable => 'Audio unavailable';

  @override
  String get audioPlayFailed => 'Couldn\'t play the audio';
}

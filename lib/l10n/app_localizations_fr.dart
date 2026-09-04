// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class LFr extends L {
  LFr([String locale = 'fr']) : super(locale);

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonLogout => 'Se déconnecter';

  @override
  String get commonSoon => 'Bientôt disponible';

  @override
  String get settingsNotifications => 'Notifications et son';

  @override
  String get settingsSecurity => 'Sécurité';

  @override
  String get settingsSecuritySub => 'Protection à deux facteurs, sessions';

  @override
  String get settingsDevices => 'Appareils';

  @override
  String get settingsMessages => 'Messages';

  @override
  String get settingsFavorites => 'Favoris';

  @override
  String get settingsFolders => 'Dossiers';

  @override
  String get settingsDataSaver => 'Économie de batterie et de réseau';

  @override
  String get settingsStorage => 'Stockage';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsLanguage => 'Langue de l\'app';

  @override
  String get settingsAccounts => 'Comptes';

  @override
  String get settingsAccountsSub => 'Changer · ajouter';

  @override
  String get settingsQrLogin => 'Se connecter avec un QR code';

  @override
  String get settingsQrLoginSub =>
      'Approuver la connexion d\'un autre appareil';

  @override
  String get settingsHelp => 'Aide';

  @override
  String get settingsDiagnostics => 'Diagnostic';

  @override
  String get settingsDiagnosticsSub =>
      'Journaux de connexion — pour le dépannage';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsLogout => 'Se déconnecter du compte';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get headerNoName => 'Sans nom';

  @override
  String get logoutTitle => 'Se déconnecter ?';

  @override
  String get logoutBody =>
      'Le compte disparaîtra du sélecteur. Son historique local, les fichiers téléchargés et la connexion enregistrée seront supprimés de cet appareil. Les autres comptes ne sont pas affectés.';

  @override
  String get aboutSourceCode => 'Code source :';

  @override
  String get aboutNotAffiliated =>
      'Sans lien avec VK ni les développeurs de l\'app officielle MAX.';

  @override
  String get apprTitle => 'Apparence';

  @override
  String get apprTextSize => 'Taille du texte';

  @override
  String get apprSystemSize => 'Comme le système';

  @override
  String get apprSystemSizeHint =>
      'La taille provient des réglages de l\'appareil';

  @override
  String get apprTheme => 'Thème';

  @override
  String get apprPreviewIncoming1 =>
      'Choisissez un thème pour changer le fond et la couleur des messages 🎨';

  @override
  String get apprPreviewOutgoing =>
      'Voyez à quoi ressembleront vos discussions';

  @override
  String get apprPreviewIncoming2 => 'Changez de thème à tout moment';

  @override
  String get langTitle => 'Langue de l\'app';

  @override
  String get langSystem => 'Langue du système';

  @override
  String get langHintSystem =>
      'Vous pouvez la changer dans les réglages système — cherchez « Langue » et choisissez-en une';

  @override
  String get langHintDevice => 'La langue change uniquement sur cet appareil';

  @override
  String get langOpenSettings => 'Modifier dans les réglages';

  @override
  String get secTitle => 'Sécurité';

  @override
  String get secPassword => 'Mot de passe de connexion';

  @override
  String get secPasswordSub => 'Protection à deux facteurs';

  @override
  String get pwdTitle => 'Mot de passe de connexion';

  @override
  String get pwdStateOn => 'Mot de passe défini';

  @override
  String get pwdStateOff => 'Non défini';

  @override
  String get pwdDesc =>
      'Demandé lors de la connexion depuis un nouvel appareil.';

  @override
  String get pwdNew => 'Nouveau mot de passe';

  @override
  String get pwdRepeat => 'Répéter le mot de passe';

  @override
  String get pwdHintLabel => 'Indice (facultatif)';

  @override
  String get pwdHintDesc =>
      'L\'indice apparaît sur l\'écran de connexion pour vous aider à retenir le mot de passe.';

  @override
  String get pwdSave => 'Enregistrer';

  @override
  String get pwdSaving => 'Enregistrement…';

  @override
  String get pwdSaved => 'Mot de passe enregistré';

  @override
  String get pwdMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String pwdTooShort(int n) {
    return 'Au moins $n caractères';
  }

  @override
  String pwdTooLong(int n) {
    return 'Au plus $n caractères';
  }

  @override
  String pwdHintTooLong(int n) {
    return 'Indice au plus $n caractères';
  }

  @override
  String get secFamily => 'Protection familiale';

  @override
  String get secFamilyOff => 'Désactivée';

  @override
  String get secSafeMode => 'Mode sécurisé';

  @override
  String get secCall => 'M\'appeler';

  @override
  String get secFindByPhone => 'Me trouver par numéro';

  @override
  String get secShowContent => 'Afficher le contenu';

  @override
  String get secInviteToChat => 'Inviter dans un chat';

  @override
  String get secInfo => 'Informations';

  @override
  String get secSeeOnline => 'Voir le statut « en ligne »';

  @override
  String get secSeeNumber => 'Voir mon numéro';

  @override
  String get secBlacklist => 'Liste noire';

  @override
  String get secBlacklistSub =>
      'Qui ne peut pas écrire, appeler ni ajouter à des chats';

  @override
  String get blEmpty => 'La liste noire est vide';

  @override
  String get blDesc =>
      'Les personnes bloquées ne peuvent pas vous écrire, vous appeler ni vous ajouter à des discussions.';

  @override
  String get blUnblock => 'Débloquer';

  @override
  String get blAdd => 'Bloquer un contact';

  @override
  String get blNoContacts => 'Aucun contact à bloquer';

  @override
  String get blSearch => 'Rechercher';

  @override
  String get accessAll => 'tout le monde';

  @override
  String get accessContacts => 'les contacts';

  @override
  String get accessNobody => 'personne';

  @override
  String get visibilityAll => 'tout le monde';

  @override
  String get visibilityContacts => 'contacts';

  @override
  String get visibilityNobody => 'personne';

  @override
  String get dsTitle => 'Économie de batterie et de réseau';

  @override
  String get dsPhoto => 'Photo';

  @override
  String get dsVideo => 'Vidéo';

  @override
  String get dsGif => 'GIF';

  @override
  String get dsAudioMessages => 'Messages vocaux';

  @override
  String get dsAutoload => 'Téléchargement auto';

  @override
  String get dsSendQuality => 'Qualité à l\'envoi';

  @override
  String get dsAutoplay => 'Lecture auto';

  @override
  String get autoAlways => 'Toujours';

  @override
  String get autoWifi => 'En Wi-Fi';

  @override
  String get autoNever => 'Jamais';

  @override
  String get stTitle => 'Stockage';

  @override
  String get stKeepMedia => 'Garder les médias dans le cache de l\'appareil';

  @override
  String get stKeepMediaSub =>
      'Après suppression, les médias peuvent être retéléchargés';

  @override
  String get stData => 'Données';

  @override
  String get stStickers => 'Stickers';

  @override
  String get stPhoto => 'Photo';

  @override
  String get stAudioMessages => 'Messages vocaux';

  @override
  String get stClearCache => 'Vider le cache';

  @override
  String get keepWeek => 'Une semaine';

  @override
  String get keepMonth => 'Un mois';

  @override
  String get keepYear => 'Un an';

  @override
  String get keepForever => 'Toujours';

  @override
  String get devTitle => 'Appareils';

  @override
  String get devHeaderTitle => 'Appareils avec MAX';

  @override
  String get devHeaderSub =>
      'Connectez-vous sur de nouveaux appareils\net gérez les sessions';

  @override
  String get devCurrent => 'actuelle';

  @override
  String get devOnline => 'En ligne';

  @override
  String get devUnknownDevice => 'Appareil inconnu';

  @override
  String get devTerminate => 'Fermer';

  @override
  String get devTerminateAll => 'Fermer toutes les sessions sauf l\'actuelle';

  @override
  String get devQrLogin => 'Se connecter avec un QR code';

  @override
  String get devEmpty => 'Aucune session active trouvée';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navCalls => 'Appels';

  @override
  String get navChats => 'Discussions';

  @override
  String get navSettings => 'Réglages';

  @override
  String get loginBack => 'Retour';

  @override
  String get loginPhoneTitle => 'Max Vektor';

  @override
  String get loginCodeTitle => 'Saisissez le code';

  @override
  String get loginNameTitle => 'Comment vous appelez-vous ?';

  @override
  String get login2faTitle => 'Mot de passe à deux facteurs';

  @override
  String get loginTokenTitle => 'Connexion par token';

  @override
  String get loginPhonePrompt =>
      'Saisissez votre numéro de téléphone — nous enverrons un code de confirmation.';

  @override
  String loginCodePrompt(Object phone) {
    return 'Code envoyé au $phone. Il arrive par SMS ou dans l\'app officielle MAX.';
  }

  @override
  String get loginNamePrompt =>
      'Ce numéro n\'est pas encore sur MAX. Saisissez un nom — et un compte sera créé.';

  @override
  String get login2faPrompt =>
      'Ce compte a un mot de passe. Saisissez-le pour terminer la connexion.';

  @override
  String get loginPhoneField => 'Numéro de téléphone';

  @override
  String get loginGetCode => 'Obtenir le code';

  @override
  String get loginConfirm => 'Confirmer';

  @override
  String loginResendIn(Object seconds) {
    return 'Redemander un code dans $seconds s';
  }

  @override
  String get loginResend => 'Redemander un code';

  @override
  String loginAttemptsLeft(Object count) {
    return 'Demandes de code restantes : $count';
  }

  @override
  String get loginFirstName => 'Prénom';

  @override
  String get loginLastNameOptional => 'Nom (facultatif)';

  @override
  String get loginNameHint =>
      'Au moins deux caractères, lettres uniquement — sans chiffres, emojis ni ponctuation.';

  @override
  String get loginCreateAccount => 'Créer un compte';

  @override
  String get loginNameTooShort => 'Le nom doit comporter au moins deux lettres';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginHide => 'Masquer';

  @override
  String get loginShow => 'Afficher';

  @override
  String get loginSignIn => 'Se connecter';

  @override
  String get loginTokenHint => 'Collez le token ici…';

  @override
  String get loginTokenButton => 'Connexion par token';

  @override
  String get loginChangeNumber => 'Changer de numéro';

  @override
  String get loginNameVisibleHint =>
      'Les autres sur MAX verront votre nom. Vous pourrez le changer plus tard dans les réglages du profil.';

  @override
  String get loginByPhone => 'Se connecter par numéro de téléphone';

  @override
  String get loginHaveToken => 'J\'ai un auth-token';

  @override
  String get loginSearchCountry => 'Rechercher un pays ou un code';

  @override
  String get commonSearch => 'Rechercher';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonFind => 'Rechercher';

  @override
  String get commonNothingFound => 'Aucun résultat';

  @override
  String commonError(Object error) {
    return 'Erreur : $error';
  }

  @override
  String get chatsArchive => 'Archives';

  @override
  String get chatsArchiveEmpty => 'Les archives sont vides';

  @override
  String get chatsNewChat => 'Nouvelle discussion';

  @override
  String get chatsEmpty => 'Aucune discussion';

  @override
  String get chatsEmptyHint =>
      'Appuyez sur le bouton en bas à droite\npour démarrer une discussion.';

  @override
  String get searchTryAnother => 'Essayez une autre recherche.';

  @override
  String get chatPin => 'Épingler';

  @override
  String get chatUnpin => 'Détacher';

  @override
  String get chatEnableNotif => 'Activer les notifications';

  @override
  String get chatDisableNotif => 'Couper les notifications';

  @override
  String get chatArchive => 'Archiver';

  @override
  String get chatUnarchive => 'Désarchiver';

  @override
  String get chatMarkRead => 'Marquer comme lu';

  @override
  String get dateYesterday => 'Hier';

  @override
  String get contactsHideSearch => 'Masquer la recherche';

  @override
  String get contactsImport => 'Importer du carnet d\'adresses';

  @override
  String get contactsAddByNumber => 'Ajouter par numéro';

  @override
  String get contactsDeleteTitle => 'Supprimer le contact ?';

  @override
  String contactPlaceholder(Object id) {
    return 'Contact $id';
  }

  @override
  String get contactDeleted => 'Contact supprimé';

  @override
  String get contactsImportTitle => 'Importer les contacts';

  @override
  String contactsImportWarn(Object cap) {
    return 'MAX considère la vérification massive de numéros comme suspecte et peut bloquer le numéro. Pour réduire le risque, je vérifierai au plus $cap numéros, un par ~1,5 seconde. Cela prendra environ une minute. Continuer ?';
  }

  @override
  String get contactsReadingBook => 'Lecture du carnet d\'adresses…';

  @override
  String contactsChecking(Object done, Object total) {
    return 'Vérification : $done sur $total';
  }

  @override
  String contactsFoundInMax(Object found, Object checked) {
    return 'Trouvés dans MAX : $found sur $checked';
  }

  @override
  String get contactsFindByNumber => 'Rechercher par numéro';

  @override
  String get contactsPhone => 'Téléphone';

  @override
  String contactsFound(Object name) {
    return 'Trouvé : $name';
  }

  @override
  String get contactsEmpty =>
      'Aucun contact. Importez votre carnet d\'adresses ou ajoutez un numéro manuellement.';

  @override
  String get contactsSectionInMax => 'Sur MAX';

  @override
  String get contactsSectionInvite => 'Inviter sur Max Vektor';

  @override
  String get contactsInviteBtn => 'Inviter';

  @override
  String get contactsInviteCopied => 'Invitation copiée';

  @override
  String get contactsNoAccessTitle => 'Aucun accès aux contacts';

  @override
  String get contactsNoAccessSub =>
      'Autorisez l’accès pour voir lesquels de vos contacts sont déjà sur MAX.';

  @override
  String get contactsGrantAccess => 'Autoriser l’accès';

  @override
  String get contactsSyncing => 'Synchronisation des contacts…';

  @override
  String contactsInviteText(String name) {
    return '$name, discutons sur la messagerie MAX !';
  }

  @override
  String get callsCreate => 'Démarrer un appel';

  @override
  String get callsEmpty => 'L\'historique des appels est vide';

  @override
  String get callsEmptyHint =>
      'Les appels audio et vidéo arriveront dans une prochaine mise à jour.';

  @override
  String get callMissed => 'Manqué';

  @override
  String get callIncoming => 'Entrant';

  @override
  String get callOutgoing => 'Sortant';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSaved => 'Profil enregistré';

  @override
  String get profileLastName => 'Nom';

  @override
  String get profileAbout => 'À propos';

  @override
  String get profileDelete => 'Supprimer le profil';

  @override
  String get profileLogout => 'Quitter le profil';

  @override
  String get profileDeleteInactive => 'Supprimer le profil si inactif';

  @override
  String get profileTtlUpdated => 'Délai mis à jour';

  @override
  String get profileLogoutTitle => 'Quitter le profil ?';

  @override
  String get profileLogoutBody =>
      'Le compte disparaîtra du sélecteur. Ses données locales seront supprimées de cet appareil. Les autres comptes ne sont pas affectés.';

  @override
  String get commonRefresh => 'Actualiser';

  @override
  String get commonClear => 'Effacer';

  @override
  String chatMember(Object id) {
    return 'Participant $id';
  }

  @override
  String get chatLastSeenRecently => 'vu récemment';

  @override
  String chatMembersCount(Object count) {
    return '$count particip.';
  }

  @override
  String chatTitlePlaceholder(Object id) {
    return 'Discussion $id';
  }

  @override
  String get chatEmpty => 'Aucun message';

  @override
  String get chatVideoCall => 'Appel vidéo';

  @override
  String get chatCall => 'Appel';

  @override
  String get chatMedia => 'Médias de la discussion';

  @override
  String get chatNewMessages => 'Nouveaux messages';

  @override
  String get chatReplyTo => 'Répondre à :';

  @override
  String get chatReplyCancel => 'Annuler la réponse';

  @override
  String get forwardUnknownUser => 'Utilisateur';

  @override
  String get msgReply => 'Répondre';

  @override
  String get msgCopy => 'Copier';

  @override
  String get msgForward => 'Transférer';

  @override
  String get msgEdit => 'Modifier';

  @override
  String get msgEditHint => 'Nouveau texte';

  @override
  String get msgCopied => 'Copié';

  @override
  String get msgReplyNotConfirmed =>
      'Impossible de répondre : le message n\'est pas encore confirmé par le serveur';

  @override
  String get msgForwardTextOnly =>
      'Pour l\'instant, seuls les messages texte sont transférés';

  @override
  String get sendAttachFailed => 'Impossible d\'envoyer la pièce jointe';

  @override
  String diagHint(Object count) {
    return 'Journaux de connexion et de protocole ($count lignes). Les jetons et codes ne sont pas enregistrés. Copiez-les et envoyez-les pour le dépannage.';
  }

  @override
  String get diagEmpty => 'Aucun journal pour l\'instant.';

  @override
  String get diagCopyAll => 'Tout copier';

  @override
  String get diagCopied => 'Journaux copiés';

  @override
  String get qrConfirming => 'Confirmation de la connexion…';

  @override
  String get qrDone =>
      'Terminé. La connexion sur l\'autre appareil est confirmée.';

  @override
  String get qrHint =>
      'Pointez la caméra vers le QR code de la page de connexion MAX sur un autre appareil (par exemple web.max.ru). Votre compte confirmera la connexion.';

  @override
  String get videoError => 'Impossible de lire la vidéo';

  @override
  String get videoTitle => 'Vidéo';

  @override
  String get connConnecting => 'Connexion…';

  @override
  String get connReconnecting => 'Reconnexion…';

  @override
  String get connNoConnection => 'Pas de connexion';

  @override
  String get inputAttach => 'Joindre';

  @override
  String get inputMessage => 'Message';

  @override
  String get attachPhotoGallery => 'Photo de la galerie';

  @override
  String get attachVideoGallery => 'Vidéo de la galerie';

  @override
  String get attachTakePhoto => 'Prendre une photo';

  @override
  String get attachTakeVideo => 'Filmer une vidéo';

  @override
  String get attachFile => 'Fichier';

  @override
  String devLoadFailed(Object error) {
    return 'Impossible de charger les sessions :\n$error';
  }

  @override
  String get fwdPickTitle => 'Transférer vers';

  @override
  String get fwdSearchChat => 'Rechercher une discussion';

  @override
  String fwdForwardedTo(Object target) {
    return 'Transféré vers $target';
  }

  @override
  String get galleryEmpty => 'Aucun média pour l\'instant';

  @override
  String get profChat => 'Discussion';

  @override
  String get profMediaFilesLinks => 'Médias, fichiers et liens';

  @override
  String get profNotifications => 'Notifications';

  @override
  String get profEnabled => 'Activées';

  @override
  String get profPinChat => 'Épingler la discussion';

  @override
  String get profClearHistory => 'Effacer l\'historique';

  @override
  String get profClearHistoryTitle => 'Effacer l\'historique ?';

  @override
  String get profHistoryCleared => 'Historique effacé localement';

  @override
  String get accAddAccount => 'Ajouter un compte';

  @override
  String accLogoutTitle(Object name) {
    return 'Quitter « $name » ?';
  }

  @override
  String get transcribe => 'Transcrire';

  @override
  String get transcribeEmpty => 'La transcription est vide';

  @override
  String get audioUnavailable => 'Audio indisponible';

  @override
  String get audioPlayFailed => 'Impossible de lire l\'audio';
}

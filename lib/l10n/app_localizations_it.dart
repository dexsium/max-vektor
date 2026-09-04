// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class LIt extends L {
  LIt([String locale = 'it']) : super(locale);

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonDone => 'Fatto';

  @override
  String get commonLogout => 'Esci';

  @override
  String get commonSoon => 'Prossimamente';

  @override
  String get settingsNotifications => 'Notifiche e suoni';

  @override
  String get settingsSecurity => 'Sicurezza';

  @override
  String get settingsSecuritySub => 'Protezione a due fattori, sessioni';

  @override
  String get settingsDevices => 'Dispositivi';

  @override
  String get settingsMessages => 'Messaggi';

  @override
  String get settingsFavorites => 'Preferiti';

  @override
  String get settingsFolders => 'Cartelle';

  @override
  String get settingsDataSaver => 'Risparmio batteria e rete';

  @override
  String get settingsStorage => 'Archiviazione';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsLanguage => 'Lingua dell\'app';

  @override
  String get settingsAccounts => 'Account';

  @override
  String get settingsAccountsSub => 'Cambia · aggiungi';

  @override
  String get settingsQrLogin => 'Accedi con codice QR';

  @override
  String get settingsQrLoginSub => 'Approva l\'accesso di un altro dispositivo';

  @override
  String get settingsHelp => 'Aiuto';

  @override
  String get settingsDiagnostics => 'Diagnostica';

  @override
  String get settingsDiagnosticsSub =>
      'Log di connessione — per la risoluzione dei problemi';

  @override
  String get settingsAbout => 'Info';

  @override
  String get settingsLogout => 'Esci dall\'account';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeSystem => 'Come il sistema';

  @override
  String get headerNoName => 'Senza nome';

  @override
  String get logoutTitle => 'Uscire?';

  @override
  String get logoutBody =>
      'L\'account scomparirà dal selettore. La cronologia locale, i file scaricati e l\'accesso salvato verranno rimossi da questo dispositivo. Gli altri account non sono interessati.';

  @override
  String get aboutSourceCode => 'Codice sorgente:';

  @override
  String get aboutNotAffiliated =>
      'Non affiliato a VK né agli sviluppatori dell\'app ufficiale MAX.';

  @override
  String get apprTitle => 'Aspetto';

  @override
  String get apprTextSize => 'Dimensione del testo';

  @override
  String get apprSystemSize => 'Come il sistema';

  @override
  String get apprSystemSizeHint =>
      'La dimensione è presa dalle impostazioni del dispositivo';

  @override
  String get apprTheme => 'Tema';

  @override
  String get apprPreviewIncoming1 =>
      'Scegli un tema per cambiare sfondo e colore dei messaggi 🎨';

  @override
  String get apprPreviewOutgoing => 'Guarda come appariranno le tue chat';

  @override
  String get apprPreviewIncoming2 => 'Cambia tema quando vuoi';

  @override
  String get langTitle => 'Lingua dell\'app';

  @override
  String get langSystem => 'Lingua di sistema';

  @override
  String get langHintSystem =>
      'Puoi cambiarla nelle impostazioni di sistema — cerca «Lingua» e scegline una';

  @override
  String get langHintDevice => 'La lingua cambia solo su questo dispositivo';

  @override
  String get langOpenSettings => 'Cambia nelle impostazioni';

  @override
  String get secTitle => 'Sicurezza';

  @override
  String get secPassword => 'Password di accesso';

  @override
  String get secPasswordSub => 'Protezione a due fattori';

  @override
  String get pwdTitle => 'Password di accesso';

  @override
  String get pwdStateOn => 'Password impostata';

  @override
  String get pwdStateOff => 'Non impostata';

  @override
  String get pwdDesc => 'Richiesta all\'accesso da un nuovo dispositivo.';

  @override
  String get pwdNew => 'Nuova password';

  @override
  String get pwdRepeat => 'Ripeti la password';

  @override
  String get pwdHintLabel => 'Suggerimento (facoltativo)';

  @override
  String get pwdHintDesc =>
      'Il suggerimento appare nella schermata di accesso per aiutarti a ricordare la password.';

  @override
  String get pwdSave => 'Salva';

  @override
  String get pwdSaving => 'Salvataggio…';

  @override
  String get pwdSaved => 'Password salvata';

  @override
  String get pwdMismatch => 'Le password non coincidono';

  @override
  String pwdTooShort(int n) {
    return 'Almeno $n caratteri';
  }

  @override
  String pwdTooLong(int n) {
    return 'Al massimo $n caratteri';
  }

  @override
  String pwdHintTooLong(int n) {
    return 'Suggerimento al massimo $n caratteri';
  }

  @override
  String get secFamily => 'Protezione famiglia';

  @override
  String get secFamilyOff => 'Disattivata';

  @override
  String get secSafeMode => 'Modalità sicura';

  @override
  String get secCall => 'Chiamarmi';

  @override
  String get secFindByPhone => 'Trovarmi tramite numero';

  @override
  String get secShowContent => 'Mostrare contenuti';

  @override
  String get secInviteToChat => 'Invitare in chat';

  @override
  String get secInfo => 'Informazioni';

  @override
  String get secSeeOnline => 'Vedere lo stato «online»';

  @override
  String get secSeeNumber => 'Vedere il mio numero';

  @override
  String get secBlacklist => 'Lista nera';

  @override
  String get secBlacklistSub =>
      'Chi non può scrivere, chiamare o aggiungere alle chat';

  @override
  String get blEmpty => 'La lista nera è vuota';

  @override
  String get blDesc =>
      'Le persone bloccate non possono scriverti, chiamarti o aggiungerti alle chat.';

  @override
  String get blUnblock => 'Sblocca';

  @override
  String get blAdd => 'Blocca un contatto';

  @override
  String get blNoContacts => 'Nessun contatto da bloccare';

  @override
  String get blSearch => 'Cerca';

  @override
  String get accessAll => 'tutti';

  @override
  String get accessContacts => 'i contatti';

  @override
  String get accessNobody => 'nessuno';

  @override
  String get visibilityAll => 'tutti';

  @override
  String get visibilityContacts => 'contatti';

  @override
  String get visibilityNobody => 'nessuno';

  @override
  String get dsTitle => 'Risparmio batteria e rete';

  @override
  String get dsPhoto => 'Foto';

  @override
  String get dsVideo => 'Video';

  @override
  String get dsGif => 'GIF';

  @override
  String get dsAudioMessages => 'Messaggi vocali';

  @override
  String get dsAutoload => 'Download automatico';

  @override
  String get dsSendQuality => 'Qualità all\'invio';

  @override
  String get dsAutoplay => 'Riproduzione automatica';

  @override
  String get autoAlways => 'Sempre';

  @override
  String get autoWifi => 'Con Wi-Fi';

  @override
  String get autoNever => 'Mai';

  @override
  String get stTitle => 'Archiviazione';

  @override
  String get stKeepMedia => 'Conserva i media nella cache del dispositivo';

  @override
  String get stKeepMediaSub =>
      'Dopo l\'eliminazione, i media possono essere scaricati di nuovo';

  @override
  String get stData => 'Dati';

  @override
  String get stStickers => 'Sticker';

  @override
  String get stPhoto => 'Foto';

  @override
  String get stAudioMessages => 'Messaggi vocali';

  @override
  String get stClearCache => 'Svuota cache';

  @override
  String get keepWeek => 'Una settimana';

  @override
  String get keepMonth => 'Un mese';

  @override
  String get keepYear => 'Un anno';

  @override
  String get keepForever => 'Sempre';

  @override
  String get devTitle => 'Dispositivi';

  @override
  String get devHeaderTitle => 'Dispositivi con MAX';

  @override
  String get devHeaderSub =>
      'Accedi su nuovi dispositivi\ne gestisci le sessioni';

  @override
  String get devCurrent => 'attuale';

  @override
  String get devOnline => 'Online';

  @override
  String get devUnknownDevice => 'Dispositivo sconosciuto';

  @override
  String get devTerminate => 'Termina';

  @override
  String get devTerminateAll =>
      'Termina tutte le sessioni tranne quella attuale';

  @override
  String get devQrLogin => 'Accedi con codice QR';

  @override
  String get devEmpty => 'Nessuna sessione attiva trovata';

  @override
  String get navContacts => 'Contatti';

  @override
  String get navCalls => 'Chiamate';

  @override
  String get navChats => 'Chat';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get loginBack => 'Indietro';

  @override
  String get loginPhoneTitle => 'Max Vektor';

  @override
  String get loginCodeTitle => 'Inserisci il codice';

  @override
  String get loginNameTitle => 'Come ti chiami?';

  @override
  String get login2faTitle => 'Password a due fattori';

  @override
  String get loginTokenTitle => 'Accesso con token';

  @override
  String get loginPhonePrompt =>
      'Inserisci il tuo numero di telefono — invieremo un codice di conferma.';

  @override
  String loginCodePrompt(Object phone) {
    return 'Codice inviato a $phone. Arriva via SMS o nell\'app ufficiale MAX.';
  }

  @override
  String get loginNamePrompt =>
      'Questo numero non è ancora su MAX. Inserisci un nome — e verrà creato un account.';

  @override
  String get login2faPrompt =>
      'Questo account ha una password. Inseriscila per completare l\'accesso.';

  @override
  String get loginPhoneField => 'Numero di telefono';

  @override
  String get loginGetCode => 'Ottieni il codice';

  @override
  String get loginConfirm => 'Conferma';

  @override
  String loginResendIn(Object seconds) {
    return 'Richiedi un nuovo codice tra $seconds s';
  }

  @override
  String get loginResend => 'Richiedi un nuovo codice';

  @override
  String loginAttemptsLeft(Object count) {
    return 'Richieste di codice rimaste: $count';
  }

  @override
  String get loginFirstName => 'Nome';

  @override
  String get loginLastNameOptional => 'Cognome (facoltativo)';

  @override
  String get loginNameHint =>
      'Almeno due caratteri, solo lettere — senza cifre, emoji o punteggiatura.';

  @override
  String get loginCreateAccount => 'Crea account';

  @override
  String get loginNameTooShort => 'Il nome deve avere almeno due lettere';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginHide => 'Nascondi';

  @override
  String get loginShow => 'Mostra';

  @override
  String get loginSignIn => 'Accedi';

  @override
  String get loginTokenHint => 'Incolla qui il token…';

  @override
  String get loginTokenButton => 'Accesso con token';

  @override
  String get loginChangeNumber => 'Cambia numero';

  @override
  String get loginNameVisibleHint =>
      'Gli altri su MAX vedranno il tuo nome. Puoi cambiarlo in seguito nelle impostazioni del profilo.';

  @override
  String get loginByPhone => 'Accedi con numero di telefono';

  @override
  String get loginHaveToken => 'Ho un auth-token';

  @override
  String get loginSearchCountry => 'Cerca paese o prefisso';

  @override
  String get commonSearch => 'Cerca';

  @override
  String get commonContinue => 'Continua';

  @override
  String get commonFind => 'Trova';

  @override
  String get commonNothingFound => 'Nessun risultato';

  @override
  String commonError(Object error) {
    return 'Errore: $error';
  }

  @override
  String get chatsArchive => 'Archivio';

  @override
  String get chatsArchiveEmpty => 'L\'archivio è vuoto';

  @override
  String get chatsNewChat => 'Nuova chat';

  @override
  String get chatsEmpty => 'Ancora nessuna chat';

  @override
  String get chatsEmptyHint =>
      'Tocca il pulsante in basso a destra\nper iniziare una nuova chat.';

  @override
  String get searchTryAnother => 'Prova un\'altra ricerca.';

  @override
  String get chatPin => 'Fissa';

  @override
  String get chatUnpin => 'Rimuovi';

  @override
  String get chatEnableNotif => 'Attiva notifiche';

  @override
  String get chatDisableNotif => 'Silenzia notifiche';

  @override
  String get chatArchive => 'Archivia';

  @override
  String get chatUnarchive => 'Rimuovi dall\'archivio';

  @override
  String get chatMarkRead => 'Segna come letto';

  @override
  String get dateYesterday => 'Ieri';

  @override
  String get contactsHideSearch => 'Nascondi ricerca';

  @override
  String get contactsImport => 'Importa dalla rubrica';

  @override
  String get contactsAddByNumber => 'Aggiungi per numero';

  @override
  String get contactsDeleteTitle => 'Eliminare il contatto?';

  @override
  String contactPlaceholder(Object id) {
    return 'Contatto $id';
  }

  @override
  String get contactDeleted => 'Contatto eliminato';

  @override
  String get contactsImportTitle => 'Importa contatti';

  @override
  String contactsImportWarn(Object cap) {
    return 'MAX considera sospetto il controllo massivo dei numeri e può bloccare il numero. Per ridurre il rischio, controllerò al massimo $cap numeri, uno ogni ~1,5 secondi. Ci vorrà circa un minuto. Continuare?';
  }

  @override
  String get contactsReadingBook => 'Lettura della rubrica…';

  @override
  String contactsChecking(Object done, Object total) {
    return 'Controllo: $done di $total';
  }

  @override
  String contactsFoundInMax(Object found, Object checked) {
    return 'Trovati in MAX: $found di $checked';
  }

  @override
  String get contactsFindByNumber => 'Trova per numero';

  @override
  String get contactsPhone => 'Telefono';

  @override
  String contactsFound(Object name) {
    return 'Trovato: $name';
  }

  @override
  String get contactsEmpty =>
      'Nessun contatto. Importa la rubrica o aggiungi un numero manualmente.';

  @override
  String get contactsSectionInMax => 'Su MAX';

  @override
  String get contactsSectionInvite => 'Invita su Max Vektor';

  @override
  String get contactsInviteBtn => 'Invita';

  @override
  String get contactsInviteCopied => 'Invito copiato';

  @override
  String get contactsNoAccessTitle => 'Nessun accesso ai contatti';

  @override
  String get contactsNoAccessSub =>
      'Concedi l’accesso per vedere quali dei tuoi contatti sono già su MAX.';

  @override
  String get contactsGrantAccess => 'Concedi accesso';

  @override
  String get contactsSyncing => 'Sincronizzazione contatti…';

  @override
  String contactsInviteText(String name) {
    return '$name, chattiamo sul messenger MAX!';
  }

  @override
  String get callsCreate => 'Avvia chiamata';

  @override
  String get callsEmpty => 'La cronologia chiamate è vuota';

  @override
  String get callsEmptyHint =>
      'Le chiamate vocali e video arriveranno in un prossimo aggiornamento.';

  @override
  String get callMissed => 'Persa';

  @override
  String get callIncoming => 'In arrivo';

  @override
  String get callOutgoing => 'In uscita';

  @override
  String get profileTitle => 'Profilo';

  @override
  String get profileSaved => 'Profilo salvato';

  @override
  String get profileLastName => 'Cognome';

  @override
  String get profileAbout => 'Chi sono';

  @override
  String get profileDelete => 'Elimina profilo';

  @override
  String get profileLogout => 'Esci dal profilo';

  @override
  String get profileDeleteInactive => 'Elimina profilo se inattivo';

  @override
  String get profileTtlUpdated => 'Periodo aggiornato';

  @override
  String get profileLogoutTitle => 'Uscire dal profilo?';

  @override
  String get profileLogoutBody =>
      'L\'account scomparirà dal selettore. I suoi dati locali verranno rimossi da questo dispositivo. Gli altri account non sono interessati.';

  @override
  String get commonRefresh => 'Aggiorna';

  @override
  String get commonClear => 'Cancella';

  @override
  String chatMember(Object id) {
    return 'Partecipante $id';
  }

  @override
  String get chatLastSeenRecently => 'visto di recente';

  @override
  String chatMembersCount(Object count) {
    return '$count partecip.';
  }

  @override
  String chatTitlePlaceholder(Object id) {
    return 'Chat $id';
  }

  @override
  String get chatEmpty => 'Ancora nessun messaggio';

  @override
  String get chatVideoCall => 'Videochiamata';

  @override
  String get chatCall => 'Chiamata';

  @override
  String get chatMedia => 'Media della chat';

  @override
  String get chatNewMessages => 'Nuovi messaggi';

  @override
  String get chatReplyTo => 'Rispondi a:';

  @override
  String get chatReplyCancel => 'Annulla risposta';

  @override
  String get forwardUnknownUser => 'Utente';

  @override
  String get msgReply => 'Rispondi';

  @override
  String get msgCopy => 'Copia';

  @override
  String get msgForward => 'Inoltra';

  @override
  String get msgEdit => 'Modifica';

  @override
  String get msgEditHint => 'Nuovo testo';

  @override
  String get msgCopied => 'Copiato';

  @override
  String get msgReplyNotConfirmed =>
      'Impossibile rispondere: il messaggio non è ancora confermato dal server';

  @override
  String get msgForwardTextOnly =>
      'Per ora si inoltrano solo messaggi di testo';

  @override
  String get sendAttachFailed => 'Impossibile inviare l\'allegato';

  @override
  String diagHint(Object count) {
    return 'Log di connessione e protocollo ($count righe). Token e codici non vengono registrati. Copiali e inviali per la risoluzione dei problemi.';
  }

  @override
  String get diagEmpty => 'Ancora nessun log.';

  @override
  String get diagCopyAll => 'Copia tutto';

  @override
  String get diagCopied => 'Log copiati';

  @override
  String get qrConfirming => 'Conferma dell\'accesso…';

  @override
  String get qrDone =>
      'Fatto. L\'accesso sull\'altro dispositivo è confermato.';

  @override
  String get qrHint =>
      'Inquadra il codice QR della pagina di accesso MAX su un altro dispositivo (ad esempio web.max.ru). Il tuo account confermerà l\'accesso.';

  @override
  String get videoError => 'Impossibile riprodurre il video';

  @override
  String get videoTitle => 'Video';

  @override
  String get connConnecting => 'Connessione…';

  @override
  String get connReconnecting => 'Riconnessione…';

  @override
  String get connNoConnection => 'Nessuna connessione';

  @override
  String get inputAttach => 'Allega';

  @override
  String get inputMessage => 'Messaggio';

  @override
  String get attachPhotoGallery => 'Foto dalla galleria';

  @override
  String get attachVideoGallery => 'Video dalla galleria';

  @override
  String get attachTakePhoto => 'Scatta una foto';

  @override
  String get attachTakeVideo => 'Registra un video';

  @override
  String get attachFile => 'File';

  @override
  String devLoadFailed(Object error) {
    return 'Impossibile caricare le sessioni:\n$error';
  }

  @override
  String get fwdPickTitle => 'Inoltra a';

  @override
  String get fwdSearchChat => 'Cerca chat';

  @override
  String fwdForwardedTo(Object target) {
    return 'Inoltrato a $target';
  }

  @override
  String get galleryEmpty => 'Ancora nessun media';

  @override
  String get profChat => 'Chat';

  @override
  String get profMediaFilesLinks => 'Media, file e link';

  @override
  String get profNotifications => 'Notifiche';

  @override
  String get profEnabled => 'Attive';

  @override
  String get profPinChat => 'Fissa chat';

  @override
  String get profClearHistory => 'Cancella cronologia';

  @override
  String get profClearHistoryTitle => 'Cancellare la cronologia?';

  @override
  String get profHistoryCleared => 'Cronologia cancellata localmente';

  @override
  String get accAddAccount => 'Aggiungi account';

  @override
  String accLogoutTitle(Object name) {
    return 'Uscire da «$name»?';
  }

  @override
  String get transcribe => 'Trascrivi';

  @override
  String get transcribeEmpty => 'La trascrizione è vuota';

  @override
  String get audioUnavailable => 'Audio non disponibile';

  @override
  String get audioPlayFailed => 'Impossibile riprodurre l\'audio';
}

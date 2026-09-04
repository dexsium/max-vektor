// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class LEs extends L {
  LEs([String locale = 'es']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonLogout => 'Cerrar sesión';

  @override
  String get commonSoon => 'Próximamente';

  @override
  String get settingsNotifications => 'Notificaciones y sonido';

  @override
  String get settingsSecurity => 'Seguridad';

  @override
  String get settingsSecuritySub => 'Protección de dos factores, sesiones';

  @override
  String get settingsDevices => 'Dispositivos';

  @override
  String get settingsMessages => 'Mensajes';

  @override
  String get settingsFavorites => 'Favoritos';

  @override
  String get settingsFolders => 'Carpetas';

  @override
  String get settingsDataSaver => 'Ahorro de batería y red';

  @override
  String get settingsStorage => 'Almacenamiento';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsLanguage => 'Idioma de la app';

  @override
  String get settingsAccounts => 'Cuentas';

  @override
  String get settingsAccountsSub => 'Cambiar · añadir';

  @override
  String get settingsQrLogin => 'Iniciar sesión con código QR';

  @override
  String get settingsQrLoginSub =>
      'Aprobar el inicio de sesión de otro dispositivo';

  @override
  String get settingsHelp => 'Ayuda';

  @override
  String get settingsDiagnostics => 'Diagnóstico';

  @override
  String get settingsDiagnosticsSub =>
      'Registros de conexión — para solucionar problemas';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsLogout => 'Cerrar sesión de la cuenta';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Del sistema';

  @override
  String get headerNoName => 'Sin nombre';

  @override
  String get logoutTitle => '¿Cerrar sesión?';

  @override
  String get logoutBody =>
      'La cuenta desaparecerá del selector. Su historial local, los archivos descargados y el inicio de sesión guardado se eliminarán de este dispositivo. Otras cuentas no se ven afectadas.';

  @override
  String get aboutSourceCode => 'Código fuente:';

  @override
  String get aboutNotAffiliated =>
      'Sin afiliación con VK ni con los desarrolladores de la app oficial MAX.';

  @override
  String get apprTitle => 'Apariencia';

  @override
  String get apprTextSize => 'Tamaño del texto';

  @override
  String get apprSystemSize => 'Como el sistema';

  @override
  String get apprSystemSizeHint =>
      'El tamaño se toma de los ajustes del dispositivo';

  @override
  String get apprTheme => 'Tema';

  @override
  String get apprPreviewIncoming1 =>
      'Elige un tema para cambiar el fondo y el color de los mensajes 🎨';

  @override
  String get apprPreviewOutgoing => 'Mira cómo se verán tus chats con él';

  @override
  String get apprPreviewIncoming2 => 'Cambia el tema cuando quieras';

  @override
  String get langTitle => 'Idioma de la app';

  @override
  String get langSystem => 'Idioma del sistema';

  @override
  String get langHintSystem =>
      'Puedes cambiarlo en los ajustes del sistema — busca «Idioma» y elige uno';

  @override
  String get langHintDevice => 'El idioma cambia solo en este dispositivo';

  @override
  String get langOpenSettings => 'Cambiar en ajustes';

  @override
  String get secTitle => 'Seguridad';

  @override
  String get secPassword => 'Contraseña de acceso';

  @override
  String get secPasswordSub => 'Protección de dos factores';

  @override
  String get pwdTitle => 'Contraseña de acceso';

  @override
  String get pwdStateOn => 'Contraseña establecida';

  @override
  String get pwdStateOff => 'Sin establecer';

  @override
  String get pwdDesc =>
      'Se solicita al iniciar sesión en un dispositivo nuevo.';

  @override
  String get pwdNew => 'Nueva contraseña';

  @override
  String get pwdRepeat => 'Repetir contraseña';

  @override
  String get pwdHintLabel => 'Pista (opcional)';

  @override
  String get pwdHintDesc =>
      'La pista aparece en la pantalla de acceso para ayudarte a recordar la contraseña.';

  @override
  String get pwdSave => 'Guardar';

  @override
  String get pwdSaving => 'Guardando…';

  @override
  String get pwdSaved => 'Contraseña guardada';

  @override
  String get pwdMismatch => 'Las contraseñas no coinciden';

  @override
  String pwdTooShort(int n) {
    return 'Mínimo $n caracteres';
  }

  @override
  String pwdTooLong(int n) {
    return 'Máximo $n caracteres';
  }

  @override
  String pwdHintTooLong(int n) {
    return 'Pista máximo $n caracteres';
  }

  @override
  String get secFamily => 'Protección familiar';

  @override
  String get secFamilyOff => 'Desactivada';

  @override
  String get secSafeMode => 'Modo seguro';

  @override
  String get secCall => 'Llamarme';

  @override
  String get secFindByPhone => 'Encontrarme por número';

  @override
  String get secShowContent => 'Mostrar contenido';

  @override
  String get secInviteToChat => 'Invitar al chat';

  @override
  String get secInfo => 'Información';

  @override
  String get secSeeOnline => 'Ver el estado «en línea»';

  @override
  String get secSeeNumber => 'Ver mi número';

  @override
  String get secBlacklist => 'Lista negra';

  @override
  String get secBlacklistSub =>
      'Quién no puede escribir, llamar ni añadir a chats';

  @override
  String get blEmpty => 'La lista negra está vacía';

  @override
  String get blDesc =>
      'Las personas bloqueadas no pueden escribirte, llamarte ni añadirte a chats.';

  @override
  String get blUnblock => 'Desbloquear';

  @override
  String get blAdd => 'Bloquear un contacto';

  @override
  String get blNoContacts => 'No hay contactos para bloquear';

  @override
  String get blSearch => 'Buscar';

  @override
  String get accessAll => 'todos';

  @override
  String get accessContacts => 'los contactos';

  @override
  String get accessNobody => 'nadie';

  @override
  String get visibilityAll => 'todos';

  @override
  String get visibilityContacts => 'contactos';

  @override
  String get visibilityNobody => 'nadie';

  @override
  String get dsTitle => 'Ahorro de batería y red';

  @override
  String get dsPhoto => 'Foto';

  @override
  String get dsVideo => 'Vídeo';

  @override
  String get dsGif => 'GIF';

  @override
  String get dsAudioMessages => 'Mensajes de voz';

  @override
  String get dsAutoload => 'Descarga automática';

  @override
  String get dsSendQuality => 'Calidad al enviar';

  @override
  String get dsAutoplay => 'Reproducción automática';

  @override
  String get autoAlways => 'Siempre';

  @override
  String get autoWifi => 'Con Wi-Fi';

  @override
  String get autoNever => 'Nunca';

  @override
  String get stTitle => 'Almacenamiento';

  @override
  String get stKeepMedia => 'Guardar multimedia en la caché del dispositivo';

  @override
  String get stKeepMediaSub =>
      'Tras eliminarlos, los archivos pueden descargarse de nuevo';

  @override
  String get stData => 'Datos';

  @override
  String get stStickers => 'Stickers';

  @override
  String get stPhoto => 'Foto';

  @override
  String get stAudioMessages => 'Mensajes de voz';

  @override
  String get stClearCache => 'Vaciar caché';

  @override
  String get keepWeek => 'Una semana';

  @override
  String get keepMonth => 'Un mes';

  @override
  String get keepYear => 'Un año';

  @override
  String get keepForever => 'Siempre';

  @override
  String get devTitle => 'Dispositivos';

  @override
  String get devHeaderTitle => 'Dispositivos con MAX';

  @override
  String get devHeaderSub =>
      'Inicia sesión en dispositivos nuevos\ny gestiona las sesiones';

  @override
  String get devCurrent => 'actual';

  @override
  String get devOnline => 'En línea';

  @override
  String get devUnknownDevice => 'Dispositivo desconocido';

  @override
  String get devTerminate => 'Cerrar';

  @override
  String get devTerminateAll => 'Cerrar todas las sesiones excepto la actual';

  @override
  String get devQrLogin => 'Iniciar sesión con código QR';

  @override
  String get devEmpty => 'No se encontraron sesiones activas';

  @override
  String get navContacts => 'Contactos';

  @override
  String get navCalls => 'Llamadas';

  @override
  String get navChats => 'Chats';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get loginBack => 'Atrás';

  @override
  String get loginPhoneTitle => 'Max Vektor';

  @override
  String get loginCodeTitle => 'Introduce el código';

  @override
  String get loginNameTitle => '¿Cómo te llamas?';

  @override
  String get login2faTitle => 'Contraseña de dos factores';

  @override
  String get loginTokenTitle => 'Iniciar sesión con token';

  @override
  String get loginPhonePrompt =>
      'Introduce tu número de teléfono — te enviaremos un código de confirmación.';

  @override
  String loginCodePrompt(Object phone) {
    return 'Enviamos un código a $phone. Llega por SMS o a la app oficial MAX.';
  }

  @override
  String get loginNamePrompt =>
      'Este número aún no está en MAX. Escribe un nombre — y se creará una cuenta.';

  @override
  String get login2faPrompt =>
      'Esta cuenta tiene contraseña. Introdúcela para terminar de iniciar sesión.';

  @override
  String get loginPhoneField => 'Número de teléfono';

  @override
  String get loginGetCode => 'Obtener el código';

  @override
  String get loginConfirm => 'Confirmar';

  @override
  String loginResendIn(Object seconds) {
    return 'Pedir un código nuevo en $seconds s';
  }

  @override
  String get loginResend => 'Pedir un código nuevo';

  @override
  String loginAttemptsLeft(Object count) {
    return 'Intentos de código restantes: $count';
  }

  @override
  String get loginFirstName => 'Nombre';

  @override
  String get loginLastNameOptional => 'Apellido (opcional)';

  @override
  String get loginNameHint =>
      'Mínimo dos caracteres, solo letras — sin dígitos, emojis ni signos de puntuación.';

  @override
  String get loginCreateAccount => 'Crear cuenta';

  @override
  String get loginNameTooShort => 'El nombre debe tener al menos dos letras';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginHide => 'Ocultar';

  @override
  String get loginShow => 'Mostrar';

  @override
  String get loginSignIn => 'Entrar';

  @override
  String get loginTokenHint => 'Pega el token aquí…';

  @override
  String get loginTokenButton => 'Iniciar sesión con token';

  @override
  String get loginChangeNumber => 'Cambiar número';

  @override
  String get loginNameVisibleHint =>
      'Otros en MAX verán tu nombre. Puedes cambiarlo luego en los ajustes del perfil.';

  @override
  String get loginByPhone => 'Iniciar sesión con número de teléfono';

  @override
  String get loginHaveToken => 'Tengo un auth-token';

  @override
  String get loginSearchCountry => 'Buscar país o código';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonFind => 'Buscar';

  @override
  String get commonNothingFound => 'Nada encontrado';

  @override
  String commonError(Object error) {
    return 'Error: $error';
  }

  @override
  String get chatsArchive => 'Archivo';

  @override
  String get chatsArchiveEmpty => 'El archivo está vacío';

  @override
  String get chatsNewChat => 'Nuevo chat';

  @override
  String get chatsEmpty => 'Aún no hay chats';

  @override
  String get chatsEmptyHint =>
      'Toca el botón de abajo a la derecha\npara iniciar un nuevo chat.';

  @override
  String get searchTryAnother => 'Prueba otra búsqueda.';

  @override
  String get chatPin => 'Fijar';

  @override
  String get chatUnpin => 'Desfijar';

  @override
  String get chatEnableNotif => 'Activar notificaciones';

  @override
  String get chatDisableNotif => 'Silenciar notificaciones';

  @override
  String get chatArchive => 'Archivar';

  @override
  String get chatUnarchive => 'Desarchivar';

  @override
  String get chatMarkRead => 'Marcar leído';

  @override
  String get dateYesterday => 'Ayer';

  @override
  String get contactsHideSearch => 'Ocultar búsqueda';

  @override
  String get contactsImport => 'Importar de la agenda';

  @override
  String get contactsAddByNumber => 'Añadir por número';

  @override
  String get contactsDeleteTitle => '¿Eliminar contacto?';

  @override
  String contactPlaceholder(Object id) {
    return 'Contacto $id';
  }

  @override
  String get contactDeleted => 'Contacto eliminado';

  @override
  String get contactsImportTitle => 'Importar contactos';

  @override
  String contactsImportWarn(Object cap) {
    return 'MAX considera sospechosa la comprobación masiva de números y puede bloquear el número. Para reducir el riesgo, comprobaré como máximo $cap números, uno cada ~1,5 segundos. Tardará alrededor de un minuto. ¿Continuar?';
  }

  @override
  String get contactsReadingBook => 'Leyendo la agenda…';

  @override
  String contactsChecking(Object done, Object total) {
    return 'Comprobando: $done de $total';
  }

  @override
  String contactsFoundInMax(Object found, Object checked) {
    return 'Encontrados en MAX: $found de $checked';
  }

  @override
  String get contactsFindByNumber => 'Buscar por número';

  @override
  String get contactsPhone => 'Teléfono';

  @override
  String contactsFound(Object name) {
    return 'Encontrado: $name';
  }

  @override
  String get contactsEmpty =>
      'No hay contactos. Importa tu agenda o añade un número manualmente.';

  @override
  String get contactsSectionInMax => 'En MAX';

  @override
  String get contactsSectionInvite => 'Invitar a Max Vektor';

  @override
  String get contactsInviteBtn => 'Invitar';

  @override
  String get contactsInviteCopied => 'Invitación copiada';

  @override
  String get contactsNoAccessTitle => 'Sin acceso a los contactos';

  @override
  String get contactsNoAccessSub =>
      'Concede acceso para ver cuáles de tus contactos ya están en MAX.';

  @override
  String get contactsGrantAccess => 'Conceder acceso';

  @override
  String get contactsSyncing => 'Sincronizando contactos…';

  @override
  String contactsInviteText(String name) {
    return '$name, ¡hablemos en el mensajero MAX!';
  }

  @override
  String get callsCreate => 'Iniciar llamada';

  @override
  String get callsEmpty => 'El historial de llamadas está vacío';

  @override
  String get callsEmptyHint =>
      'Las llamadas de voz y vídeo llegarán en una próxima actualización.';

  @override
  String get callMissed => 'Perdida';

  @override
  String get callIncoming => 'Entrante';

  @override
  String get callOutgoing => 'Saliente';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileSaved => 'Perfil guardado';

  @override
  String get profileLastName => 'Apellido';

  @override
  String get profileAbout => 'Acerca de mí';

  @override
  String get profileDelete => 'Eliminar perfil';

  @override
  String get profileLogout => 'Salir del perfil';

  @override
  String get profileDeleteInactive => 'Eliminar perfil si está inactivo';

  @override
  String get profileTtlUpdated => 'Plazo actualizado';

  @override
  String get profileLogoutTitle => '¿Salir del perfil?';

  @override
  String get profileLogoutBody =>
      'La cuenta desaparecerá del selector. Sus datos locales se eliminarán de este dispositivo. Otras cuentas no se ven afectadas.';

  @override
  String get commonRefresh => 'Actualizar';

  @override
  String get commonClear => 'Borrar';

  @override
  String chatMember(Object id) {
    return 'Participante $id';
  }

  @override
  String get chatLastSeenRecently => 'visto hace poco';

  @override
  String chatMembersCount(Object count) {
    return '$count part.';
  }

  @override
  String chatTitlePlaceholder(Object id) {
    return 'Chat $id';
  }

  @override
  String get chatEmpty => 'Aún no hay mensajes';

  @override
  String get chatVideoCall => 'Videollamada';

  @override
  String get chatCall => 'Llamada';

  @override
  String get chatMedia => 'Multimedia del chat';

  @override
  String get chatNewMessages => 'Mensajes nuevos';

  @override
  String get chatReplyTo => 'Responder a:';

  @override
  String get chatReplyCancel => 'Cancelar respuesta';

  @override
  String get forwardUnknownUser => 'Usuario';

  @override
  String get msgReply => 'Responder';

  @override
  String get msgCopy => 'Copiar';

  @override
  String get msgForward => 'Reenviar';

  @override
  String get msgEdit => 'Editar';

  @override
  String get msgEditHint => 'Nuevo texto';

  @override
  String get msgCopied => 'Copiado';

  @override
  String get msgReplyNotConfirmed =>
      'No se puede responder: el servidor aún no confirmó el mensaje';

  @override
  String get msgForwardTextOnly =>
      'Por ahora solo se reenvían mensajes de texto';

  @override
  String get sendAttachFailed => 'No se pudo enviar el archivo';

  @override
  String diagHint(Object count) {
    return 'Registros de conexión y protocolo ($count líneas). No se registran tokens ni códigos. Cópialos y envíalos para solucionar el problema.';
  }

  @override
  String get diagEmpty => 'Aún no hay registros.';

  @override
  String get diagCopyAll => 'Copiar todo';

  @override
  String get diagCopied => 'Registros copiados';

  @override
  String get qrConfirming => 'Confirmando el inicio de sesión…';

  @override
  String get qrDone =>
      'Listo. El inicio de sesión en el otro dispositivo está confirmado.';

  @override
  String get qrHint =>
      'Apunta la cámara al código QR de la página de inicio de sesión de MAX en otro dispositivo (por ejemplo web.max.ru). Tu cuenta confirmará el inicio de sesión.';

  @override
  String get videoError => 'No se pudo reproducir el vídeo';

  @override
  String get videoTitle => 'Vídeo';

  @override
  String get connConnecting => 'Conectando…';

  @override
  String get connReconnecting => 'Reconectando…';

  @override
  String get connNoConnection => 'Sin conexión';

  @override
  String get inputAttach => 'Adjuntar';

  @override
  String get inputMessage => 'Mensaje';

  @override
  String get attachPhotoGallery => 'Foto de la galería';

  @override
  String get attachVideoGallery => 'Vídeo de la galería';

  @override
  String get attachTakePhoto => 'Tomar una foto';

  @override
  String get attachTakeVideo => 'Grabar un vídeo';

  @override
  String get attachFile => 'Archivo';

  @override
  String devLoadFailed(Object error) {
    return 'No se pudieron cargar las sesiones:\n$error';
  }

  @override
  String get fwdPickTitle => 'Reenviar a';

  @override
  String get fwdSearchChat => 'Buscar chat';

  @override
  String fwdForwardedTo(Object target) {
    return 'Reenviado a $target';
  }

  @override
  String get galleryEmpty => 'Aún no hay multimedia';

  @override
  String get profChat => 'Chat';

  @override
  String get profMediaFilesLinks => 'Multimedia, archivos y enlaces';

  @override
  String get profNotifications => 'Notificaciones';

  @override
  String get profEnabled => 'Activadas';

  @override
  String get profPinChat => 'Fijar chat';

  @override
  String get profClearHistory => 'Vaciar historial';

  @override
  String get profClearHistoryTitle => '¿Vaciar historial?';

  @override
  String get profHistoryCleared => 'Historial vaciado localmente';

  @override
  String get accAddAccount => 'Añadir cuenta';

  @override
  String accLogoutTitle(Object name) {
    return '¿Salir de «$name»?';
  }

  @override
  String get transcribe => 'Transcribir';

  @override
  String get transcribeEmpty => 'La transcripción está vacía';

  @override
  String get audioUnavailable => 'Audio no disponible';

  @override
  String get audioPlayFailed => 'No se pudo reproducir el audio';
}

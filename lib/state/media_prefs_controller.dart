import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Режим автозагрузки/автовоспроизведения медиа.
///
/// Значения совпадают с официальным приложением MAX (izi.java / s33.java):
/// в SharedPreferences хранится `int`, где `1` — всегда, `0` — по Wi-Fi,
/// `-1` — никогда (`i != -1` = «включено в каком-то виде»).
enum MediaAuto {
  always(1, 'Всегда'),
  wifi(0, 'По Wi-Fi'),
  never(-1, 'Никогда');

  const MediaAuto(this.raw, this.label);
  final int raw;
  final String label;

  static MediaAuto fromRaw(int v) =>
      switch (v) { 1 => always, -1 => never, _ => wifi };
}

/// Срок хранения медиа в кэше устройства («Память» → «Хранить медиа…»).
/// Хранится как число дней под ключом `app.media.caching.time`
/// (`-1` — хранить всегда).
enum CacheKeep {
  week(7, 'Неделя'),
  month(30, 'Месяц'),
  year(365, 'Год'),
  forever(-1, 'Всегда');

  const CacheKeep(this.days, this.label);
  final int days;
  final String label;

  static CacheKeep fromRaw(int v) => switch (v) {
        7 => week,
        365 => year,
        -1 => forever,
        _ => month,
      };
}

/// Настройки раздела «Экономия батареи и сети».
///
/// Это клиентские префы (в оригинале — локальный SharedPreferences, не
/// серверная синхронизация op 22). Ключи повторяют официальные, чтобы
/// поведение и семантика совпадали:
/// `app.media.load.photo`, `app.video.auto.play`, `app.media.video.compress`,
/// `app.media.autoplay.gif`, `app.media.load.audio_messages`.
class MediaPrefs {
  const MediaPrefs({
    this.photoAutoload = MediaAuto.wifi,
    this.videoAutoplay = MediaAuto.always,
    this.videoSendQuality = '720',
    this.gifAutoplay = true,
    this.audioAutoload = MediaAuto.wifi,
    this.cacheKeep = CacheKeep.month,
  });

  final MediaAuto photoAutoload;
  final MediaAuto videoAutoplay;

  /// Качество при отправке видео: '480' | '720' | '1080'.
  final String videoSendQuality;
  final bool gifAutoplay;
  final MediaAuto audioAutoload;
  final CacheKeep cacheKeep;

  MediaPrefs copyWith({
    MediaAuto? photoAutoload,
    MediaAuto? videoAutoplay,
    String? videoSendQuality,
    bool? gifAutoplay,
    MediaAuto? audioAutoload,
    CacheKeep? cacheKeep,
  }) =>
      MediaPrefs(
        photoAutoload: photoAutoload ?? this.photoAutoload,
        videoAutoplay: videoAutoplay ?? this.videoAutoplay,
        videoSendQuality: videoSendQuality ?? this.videoSendQuality,
        gifAutoplay: gifAutoplay ?? this.gifAutoplay,
        audioAutoload: audioAutoload ?? this.audioAutoload,
        cacheKeep: cacheKeep ?? this.cacheKeep,
      );
}

/// Хранит [MediaPrefs] в защищённом хранилище (глобально, как тема).
class MediaPrefsController extends Notifier<MediaPrefs> {
  // Официальные ключи MAX — сохраняем совместимую семантику.
  static const _kPhoto = 'app.media.load.photo';
  static const _kVideoPlay = 'app.video.auto.play';
  static const _kVideoCompress = 'app.media.video.compress';
  static const _kGif = 'app.media.autoplay.gif';
  static const _kAudio = 'app.media.load.audio_messages';
  static const _kCacheKeep = 'app.media.caching.time';

  static const _backend = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  MediaPrefs build() {
    _load();
    return const MediaPrefs();
  }

  Future<void> _load() async {
    try {
      final all = await _backend.readAll();
      MediaAuto auto(String k, MediaAuto def) {
        final v = all[k];
        return v == null ? def : MediaAuto.fromRaw(int.tryParse(v) ?? def.raw);
      }

      final loaded = MediaPrefs(
        photoAutoload: auto(_kPhoto, MediaAuto.wifi),
        videoAutoplay: auto(_kVideoPlay, MediaAuto.always),
        videoSendQuality: all[_kVideoCompress] ?? '720',
        gifAutoplay: (all[_kGif] ?? 'true') != 'false',
        audioAutoload: auto(_kAudio, MediaAuto.wifi),
        cacheKeep: CacheKeep.fromRaw(
            int.tryParse(all[_kCacheKeep] ?? '') ?? CacheKeep.month.days),
      );
      state = loaded;
    } catch (_) {
      // Нет доступа к хранилищу — остаются значения по умолчанию.
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _backend.write(key: key, value: value);
    } catch (_) {}
  }

  Future<void> setPhotoAutoload(MediaAuto v) async {
    state = state.copyWith(photoAutoload: v);
    await _write(_kPhoto, '${v.raw}');
  }

  Future<void> setVideoAutoplay(MediaAuto v) async {
    state = state.copyWith(videoAutoplay: v);
    await _write(_kVideoPlay, '${v.raw}');
  }

  Future<void> setVideoSendQuality(String q) async {
    state = state.copyWith(videoSendQuality: q);
    await _write(_kVideoCompress, q);
  }

  Future<void> setGifAutoplay(bool v) async {
    state = state.copyWith(gifAutoplay: v);
    await _write(_kGif, '$v');
  }

  Future<void> setAudioAutoload(MediaAuto v) async {
    state = state.copyWith(audioAutoload: v);
    await _write(_kAudio, '${v.raw}');
  }

  Future<void> setCacheKeep(CacheKeep v) async {
    state = state.copyWith(cacheKeep: v);
    await _write(_kCacheKeep, '${v.days}');
  }
}

final mediaPrefsProvider =
    NotifierProvider<MediaPrefsController, MediaPrefs>(MediaPrefsController.new);

/// Текущий тип подключения. Обновляется системным потоком connectivity.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final c = Connectivity();
  // Отдаём сначала текущее состояние, затем изменения.
  return c.onConnectivityChanged.asBroadcastStream();
});

/// Устройство сейчас на Wi-Fi (или Ethernet — тоже безлимитная сеть).
Future<bool> isOnWifi() async {
  try {
    final r = await Connectivity().checkConnectivity();
    return r.contains(ConnectivityResult.wifi) ||
        r.contains(ConnectivityResult.ethernet);
  } catch (_) {
    // Не смогли определить — считаем, что не Wi-Fi (экономим трафик).
    return false;
  }
}

/// Нужно ли авто-грузить/запускать медиа при режиме [mode] и текущей сети.
///
/// `Всегда` → да; `Никогда` → нет; `По Wi-Fi` → только если [onWifi].
bool shouldAutoLoad(MediaAuto mode, {required bool onWifi}) => switch (mode) {
      MediaAuto.always => true,
      MediaAuto.never => false,
      MediaAuto.wifi => onWifi,
    };

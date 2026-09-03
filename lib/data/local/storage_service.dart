import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import 'cache_managers.dart';

/// Категории кэша, показываемые в разделе «Память».
enum StorageCategory { stickers, photos, audio }

/// Размеры кэша по категориям (байты).
class StorageUsage {
  const StorageUsage({
    this.stickers = 0,
    this.photos = 0,
    this.audio = 0,
    this.other = 0,
  });

  final int stickers;
  final int photos;
  final int audio;

  /// Прочие скачанные медиа (видео/файлы) — в очистку входят, но отдельной
  /// строкой в UI не показываются (как в оригинале — три категории).
  final int other;

  int get total => stickers + photos + audio + other;
}

/// Реальный подсчёт и очистка кэша устройства для раздела «Память».
///
/// Изображения кешируются flutter_cache_manager во временной директории:
/// стикеры — в подпапке [MvCache.stickerKey], фото — в 'libCachedImageData'
/// (ключ [DefaultCacheManager]). Скачанные медиа лежат в
/// ApplicationDocuments/[AppMeta.mediaDirFor].
class StorageService {
  const StorageService._();

  static const _defaultImageKey = 'libCachedImageData';
  static const _audioExt = {
    '.ogg', '.opus', '.m4a', '.aac', '.mp3', '.wav', '.amr',
  };

  static Future<int> _dirSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    try {
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (e is File) {
          try {
            total += await e.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }

  /// Подсчитать использование по категориям для аккаунта [accountId].
  static Future<StorageUsage> usage(String accountId) async {
    final tmp = await getTemporaryDirectory();
    final stickers = await _dirSize(Directory(p.join(tmp.path, MvCache.stickerKey)));
    final photos = await _dirSize(Directory(p.join(tmp.path, _defaultImageKey)));

    var audio = 0;
    var other = 0;
    final docs = await getApplicationDocumentsDirectory();
    final media = Directory(p.join(docs.path, AppMeta.mediaDirFor(accountId)));
    if (await media.exists()) {
      try {
        await for (final e in media.list(recursive: true, followLinks: false)) {
          if (e is File) {
            int len;
            try {
              len = await e.length();
            } catch (_) {
              continue;
            }
            final ext = p.extension(e.path).toLowerCase();
            if (_audioExt.contains(ext)) {
              audio += len;
            } else {
              other += len;
            }
          }
        }
      } catch (_) {}
    }

    return StorageUsage(
      stickers: stickers,
      photos: photos,
      audio: audio,
      other: other,
    );
  }

  /// Очистить весь медиа-кэш: стикеры, фото и скачанные медиа аккаунта.
  static Future<void> clearAll(String accountId) async {
    try {
      await MvCache.stickers.emptyCache();
    } catch (_) {}
    try {
      await MvCache.photos.emptyCache();
    } catch (_) {}
    final docs = await getApplicationDocumentsDirectory();
    final media = Directory(p.join(docs.path, AppMeta.mediaDirFor(accountId)));
    if (await media.exists()) {
      try {
        await for (final e in media.list(followLinks: false)) {
          try {
            await e.delete(recursive: true);
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

  /// Очистить одну категорию.
  static Future<void> clearCategory(
      StorageCategory cat, String accountId) async {
    switch (cat) {
      case StorageCategory.stickers:
        try {
          await MvCache.stickers.emptyCache();
        } catch (_) {}
      case StorageCategory.photos:
        try {
          await MvCache.photos.emptyCache();
        } catch (_) {}
      case StorageCategory.audio:
        await _deleteMediaWhere(accountId, (ext) => _audioExt.contains(ext));
    }
  }

  static Future<void> _deleteMediaWhere(
      String accountId, bool Function(String ext) match) async {
    final docs = await getApplicationDocumentsDirectory();
    final media = Directory(p.join(docs.path, AppMeta.mediaDirFor(accountId)));
    if (!await media.exists()) return;
    try {
      await for (final e in media.list(recursive: true, followLinks: false)) {
        if (e is File && match(p.extension(e.path).toLowerCase())) {
          try {
            await e.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Удалить скачанные медиа старше срока [keepDays] (для авто-очистки по
  /// сроку хранения). `keepDays <= 0` — не удалять ничего (хранить всегда).
  static Future<void> pruneOlderThan(String accountId, int keepDays) async {
    if (keepDays <= 0) return;
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    final docs = await getApplicationDocumentsDirectory();
    final media = Directory(p.join(docs.path, AppMeta.mediaDirFor(accountId)));
    if (!await media.exists()) return;
    try {
      await for (final e in media.list(recursive: true, followLinks: false)) {
        if (e is File) {
          try {
            if ((await e.stat()).modified.isBefore(cutoff)) await e.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Человекочитаемый размер: «4,2 МБ», «107,3 МБ», «1,1 ГБ».
  static String humanSize(int bytes) {
    if (bytes <= 0) return '0 Б';
    const units = ['Б', 'КБ', 'МБ', 'ГБ', 'ТБ'];
    var size = bytes.toDouble();
    var i = 0;
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    // Одна цифра после запятой для КБ и выше; для байт — целое.
    final s = i == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
    return '${s.replaceAll('.', ',')} ${units[i]}';
  }
}

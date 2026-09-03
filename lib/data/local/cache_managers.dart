import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Отдельные менеджеры кэша изображений, чтобы раздел «Память» мог считать
/// и чистить категории по-отдельности (как в официальном приложении).
///
/// * [stickerCacheManager] — стикеры (обычно самый объёмный кэш);
/// * фото и прочие сетевые картинки идут через [DefaultCacheManager].
class MvCache {
  const MvCache._();

  /// Ключ = имя подпапки во временной директории (getTemporaryDirectory).
  static const stickerKey = 'mv_stickers_cache';

  static final CacheManager stickers = CacheManager(
    Config(
      stickerKey,
      // Стикеры живут долго и переиспользуются — держим щедрый лимит.
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 4000,
    ),
  );

  /// Фото и остальные сетевые изображения.
  static final CacheManager photos = DefaultCacheManager();
}

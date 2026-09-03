import 'dart:convert';

/// Один аккаунт MAX внутри Max Vektor.
///
/// [id] — локальный идентификатор, он же namespace ВСЕХ данных аккаунта:
/// ключей Keychain, файла SQLite, каталога медиа и, что важнее всего,
/// собственного `deviceId` для INIT. Никогда не меняется и не переиспользуется
/// после удаления аккаунта.
class MvAccount {
  const MvAccount({
    required this.id,
    this.userId,
    this.phone,
    this.displayName,
  });

  final String id;

  /// userId в MAX. Известен только после успешного входа.
  final int? userId;

  /// Номер телефона, под которым вошли. Нужен, чтобы человек различал
  /// аккаунты в переключателе.
  final String? phone;

  /// Имя из профиля MAX, если удалось загрузить.
  final String? displayName;

  bool get isSignedIn => userId != null;

  /// Подпись для списка аккаунтов: имя, иначе номер, иначе «не выполнен вход».
  String get label {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (phone != null && phone!.isNotEmpty) return phone!;
    return 'Вход не выполнен';
  }

  /// Вторая строка списка: номер, если он не ушёл в [label].
  String? get subtitle {
    if (displayName != null && displayName!.isNotEmpty) return phone;
    return null;
  }

  MvAccount copyWith({
    int? userId,
    String? phone,
    String? displayName,
  }) {
    return MvAccount(
      id: id,
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'userId': userId,
        'phone': phone,
        'displayName': displayName,
      };

  static MvAccount? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    if (id is! String || id.isEmpty) return null;
    return MvAccount(
      id: id,
      userId: (raw['userId'] as num?)?.toInt(),
      phone: raw['phone'] as String?,
      displayName: raw['displayName'] as String?,
    );
  }

  static String encodeList(List<MvAccount> accounts) =>
      jsonEncode(accounts.map((a) => a.toJson()).toList());

  static List<MvAccount> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(MvAccount.fromJson)
          .whereType<MvAccount>()
          .toList(growable: false);
    } catch (_) {
      // Повреждённый реестр не должен ронять запуск: считаем, что аккаунтов
      // нет, дальше создастся первый.
      return const [];
    }
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _backend = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

/// Размер текста в приложении. `system` — использовать системный масштаб
/// (как «Как в системе» в оригинале, где fontScale=0), иначе один из [steps].
class TextSizeState {
  const TextSizeState({this.system = true, this.step = 2});

  final bool system;
  final int step;

  /// Множители на 6 делений шкалы (как в официальном приложении A···A).
  static const steps = <double>[0.85, 0.92, 1.0, 1.1, 1.2, 1.3];

  double get scale => steps[step.clamp(0, steps.length - 1)];

  TextSizeState copyWith({bool? system, int? step}) =>
      TextSizeState(system: system ?? this.system, step: step ?? this.step);
}

class TextSizeController extends Notifier<TextSizeState> {
  static const _kSystem = 'mv_textsize_system';
  static const _kStep = 'mv_textsize_step';

  @override
  TextSizeState build() {
    _load();
    return const TextSizeState();
  }

  Future<void> _load() async {
    try {
      final all = await _backend.readAll();
      state = TextSizeState(
        system: (all[_kSystem] ?? 'true') != 'false',
        step: int.tryParse(all[_kStep] ?? '') ?? 2,
      );
    } catch (_) {}
  }

  Future<void> setSystem(bool v) async {
    state = state.copyWith(system: v);
    try {
      await _backend.write(key: _kSystem, value: '$v');
    } catch (_) {}
  }

  Future<void> setStep(int step) async {
    final s = step.clamp(0, TextSizeState.steps.length - 1);
    state = state.copyWith(step: s);
    try {
      await _backend.write(key: _kStep, value: '$s');
    } catch (_) {}
  }
}

final textSizeProvider =
    NotifierProvider<TextSizeController, TextSizeState>(TextSizeController.new);

/// Итоговый TextScaler для MaterialApp: системный или фиксированный масштаб.
TextScaler textScalerFor(TextSizeState s, BuildContext context) => s.system
    ? MediaQuery.textScalerOf(context)
    : TextScaler.linear(s.scale);

/// Выбранные обои чата (id из [kChatWallpapers]). Хранится глобально.
class ChatWallpaperController extends Notifier<String> {
  static const _key = 'mv_chat_wallpaper';

  @override
  String build() {
    _load();
    return 'cosmos_blue';
  }

  Future<void> _load() async {
    try {
      final v = await _backend.read(key: _key);
      if (v != null && v.isNotEmpty) state = v;
    } catch (_) {}
  }

  Future<void> set(String id) async {
    state = id;
    try {
      await _backend.write(key: _key, value: id);
    } catch (_) {}
  }
}

final chatWallpaperProvider =
    NotifierProvider<ChatWallpaperController, String>(
        ChatWallpaperController.new);

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../state/providers.dart';
import '../../state/session_controller.dart';
import '../widgets/app_snack.dart';

/// Редактирование своего профиля MAX: имя, фамилия, «о себе», аватар.
///
/// Открывается по карандашу в шапке настроек. Сохранение — op 16
/// (updateProfile), аватар грузится отдельно и подкладывается как
/// photoToken. Поля и опкоды сверены с официальным APK (o8b.java).
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();

  bool _busy = false;
  bool _loaded = false;
  String? _avatarUrl;
  String? _pickedAvatarPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final me = await ref.read(maxClientProvider).currentProfile();
      final contact = me['contact'];
      final map = contact is Map ? contact : me;
      String? s(String k) {
        final v = map[k];
        return v is String && v.isNotEmpty ? v : null;
      }

      // Имя MAX часто в names[].firstName/lastName; берём оттуда, если есть.
      final names = map['names'];
      String? first = s('firstName');
      String? last = s('lastName');
      if (names is List && names.isNotEmpty && names.first is Map) {
        final n = (names.first as Map);
        first ??= (n['firstName'] as String?);
        last ??= (n['lastName'] as String?);
      }
      _firstCtrl.text = first ?? '';
      _lastCtrl.text = last ?? '';
      _aboutCtrl.text = s('description') ?? '';
      _avatarUrl = s('baseUrl') ?? s('photoUrl') ?? s('baseRawIconUrl');
    } catch (_) {
      // Профиль не загрузился — поля останутся пустыми, можно заполнить.
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null && mounted) {
      setState(() => _pickedAvatarPath = picked.path);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      String? photoToken;
      if (_pickedAvatarPath != null) {
        final uploader = await ref.read(uploadRepositoryProvider.future);
        photoToken = await uploader.uploadProfilePhoto(_pickedAvatarPath!);
      }
      await ref.read(maxClientProvider).updateProfile(
            firstName: _firstCtrl.text.trim(),
            lastName: _lastCtrl.text.trim(),
            description: _aboutCtrl.text.trim(),
            photoToken: photoToken,
          );
      // Обновляем подпись аккаунта в переключателе.
      final accounts = ref.read(accountsProvider.notifier);
      final current = ref.read(activeAccountProvider);
      final name = [_firstCtrl.text.trim(), _lastCtrl.text.trim()]
          .where((e) => e.isNotEmpty)
          .join(' ');
      await accounts.update(
        current.copyWith(displayName: name.isEmpty ? null : name),
      );
      if (mounted) {
        AppSnack.show(context, 'Профиль сохранён', icon: Icons.check);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnack.show(context, 'Не удалось сохранить: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(child: _avatar(scheme)),
                const SizedBox(height: 24),
                _field(_firstCtrl, 'Имя'),
                const SizedBox(height: 12),
                _field(_lastCtrl, 'Фамилия'),
                const SizedBox(height: 12),
                _field(_aboutCtrl, 'О себе', maxLines: 3),
                const SizedBox(height: 24),
                _dangerTile(
                  icon: Icons.logout,
                  title: 'Выйти из профиля',
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
      bottomNavigationBar: !_loaded
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('Сохранить',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _avatar(ColorScheme scheme) {
    final initial = _firstCtrl.text.isNotEmpty
        ? _firstCtrl.text.characters.first.toUpperCase()
        : '?';
    Widget inner;
    if (_pickedAvatarPath != null) {
      inner = ClipOval(
        child: Image.file(File(_pickedAvatarPath!),
            width: 96, height: 96, fit: BoxFit.cover),
      );
    } else if (_avatarUrl != null) {
      inner = ClipOval(
        child: Image.network(_avatarUrl!,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _avatarInitial(initial)),
      );
    } else {
      inner = _avatarInitial(initial);
    }
    return GestureDetector(
      onTap: _pickAvatar,
      child: Stack(
        children: [
          inner,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: const Icon(Icons.photo_camera,
                  size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarInitial(String initial) => Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF56CDFF), Color(0xFF2563EB)],
          ),
        ),
        child: Text(initial,
            style: const TextStyle(
                fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white)),
      );

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _dangerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: scheme.error),
        title: Text(title, style: TextStyle(color: scheme.error)),
        onTap: onTap,
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из профиля?'),
        content: const Text(
          'Аккаунт исчезнет из переключателя. Его локальные данные будут '
          'удалены с устройства. Другие аккаунты не затрагиваются.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(sessionProvider.notifier).logout();
    if (context.mounted) Navigator.of(context).pop();
  }
}

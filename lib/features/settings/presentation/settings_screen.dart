import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/push/push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../../auth/application/auth_controller.dart';
import '../data/account_repository.dart';

/// Configuración: datos de la cuenta, contraseña, avisos del teléfono y cierre de sesión.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _notificationsOn;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final push = ref.read(pushServiceProvider);
    final on = push == null ? false : await push.notificationsAllowed();
    if (mounted) setState(() => _notificationsOn = on);
  }

  Future<void> _enableNotifications() async {
    final push = ref.read(pushServiceProvider);
    if (push == null) {
      showAgroSnack(context, 'Los avisos no están disponibles en esta instalación', emoji: '⚠️');
      return;
    }
    final on = await push.enableNotifications();
    if (!mounted) return;
    setState(() => _notificationsOn = on);
    showAgroSnack(
      context,
      on ? 'Avisos activados en este teléfono' : 'Actívalos en Ajustes del teléfono → Aplicaciones → AgroLink → Notificaciones',
      emoji: on ? '✅' : '⚠️',
    );
  }

  Future<void> _editProfile() async {
    final user = ref.read(authProvider);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(21))),
      builder: (_) => _ProfileForm(name: user?.name ?? '', phone: user?.phone ?? ''),
    );
    if (saved == true && mounted) showAgroSnack(context, 'Perfil actualizado', emoji: '✅');
  }

  Future<void> _changePassword() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(21))),
      builder: (_) => const _PasswordForm(),
    );
    if (saved == true && mounted) {
      showAgroSnack(context, 'Contraseña actualizada. Se cerró tu sesión en otros dispositivos.', emoji: '✅');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Row(
              children: [
                CircleIconButton(icon: Icons.arrow_back_rounded, background: AppColors.cream, onTap: () => context.pop()),
                const SizedBox(width: 12),
                const Text('Configuración', style: AppText.h1),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Cuenta', style: AppText.h3),
            const SizedBox(height: 10),
            _Tile(
              icon: Icons.person_outline_rounded,
              label: 'Editar perfil',
              detail: [user?.name, user?.email].whereType<String>().join(' · '),
              onTap: _editProfile,
            ),
            _Tile(icon: Icons.password_rounded, label: 'Cambiar contraseña', onTap: _changePassword),
            _Tile(icon: Icons.lock_outline_rounded, label: 'Seguridad (verificación en dos pasos)', onTap: () => context.push('/security')),
            const SizedBox(height: 18),
            const Text('Avisos', style: AppText.h3),
            const SizedBox(height: 10),
            _Tile(
              icon: Icons.notifications_active_outlined,
              label: 'Avisos en este teléfono',
              detail: switch (_notificationsOn) {
                null => 'Revisando…',
                true => 'Activados',
                false => 'Desactivados · toca para activar',
              },
              onTap: _notificationsOn == true ? null : _enableNotifications,
            ),
            _Tile(icon: Icons.notifications_none_rounded, label: 'Ver mis notificaciones', onTap: () => context.push('/notifications')),
            const SizedBox(height: 18),
            const Text('Acerca de', style: AppText.h3),
            const SizedBox(height: 10),
            _Tile(
              icon: Icons.info_outline_rounded,
              label: 'AgroLink',
              detail: 'El mercado del campo · versión 0.1.0',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'AgroLink',
                applicationVersion: '0.1.0',
                children: const [Text('Compra, vende y negocia productos del campo en México.')],
              ),
            ),
            _Tile(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesión',
              danger: true,
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, this.detail, this.onTap, this.danger = false});

  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.ink;
    return Pressable(
      scale: 0.98,
      onTap: onTap ?? () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.bodyStrong.copyWith(color: color)),
                  if (detail != null && detail!.isNotEmpty) Text(detail!, style: AppText.muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.name, required this.phone});
  final String name;
  final String phone;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final _name = TextEditingController(text: widget.name);
  late final _phone = TextEditingController(text: widget.phone);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      showAgroSnack(context, 'Escribe tu nombre', emoji: '⚠️');
      return;
    }
    setState(() => _saving = true);
    try {
      final fresh = await ref.read(accountRepositoryProvider).updateProfile(
            ProfileEdit(name: _name.text.trim(), phone: _phone.text.trim()),
          );
      ref.read(authProvider.notifier).setUser(fresh);
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Editar perfil', style: AppText.h2),
          const SizedBox(height: 16),
          AgroTextField(label: 'Nombre', icon: Icons.person_outline_rounded, controller: _name),
          const SizedBox(height: 12),
          AgroTextField(
            label: 'Teléfono (opcional)',
            icon: Icons.phone_outlined,
            controller: _phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),
          AgroButton(label: 'Guardar', icon: Icons.check_rounded, loading: _saving, onTap: _save),
        ],
      ),
    );
  }
}

class _PasswordForm extends ConsumerStatefulWidget {
  const _PasswordForm();

  @override
  ConsumerState<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends ConsumerState<_PasswordForm> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final n = _next.text;
    if (n.length < 8 || !RegExp('[a-z]').hasMatch(n) || !RegExp('[A-Z]').hasMatch(n) || !RegExp('[0-9]').hasMatch(n)) {
      showAgroSnack(context, 'Mínimo 8 caracteres con mayúscula, minúscula y número', emoji: '⚠️');
      return;
    }
    if (n != _repeat.text) {
      showAgroSnack(context, 'Las contraseñas nuevas no coinciden', emoji: '⚠️');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(accountRepositoryProvider).changePassword(current: _current.text, next: n);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cambiar contraseña', style: AppText.h2),
            const SizedBox(height: 16),
            AgroTextField(label: 'Contraseña actual', icon: Icons.lock_outline_rounded, controller: _current, obscure: true),
            const SizedBox(height: 12),
            AgroTextField(label: 'Contraseña nueva', icon: Icons.lock_reset_rounded, controller: _next, obscure: true),
            const SizedBox(height: 12),
            AgroTextField(label: 'Repite la contraseña nueva', icon: Icons.lock_reset_rounded, controller: _repeat, obscure: true),
            const SizedBox(height: 18),
            AgroButton(label: 'Cambiar contraseña', icon: Icons.check_rounded, loading: _saving, onTap: _save),
          ],
        ),
      ),
    );
  }
}

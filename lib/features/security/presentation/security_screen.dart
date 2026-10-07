import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../data/two_factor_repository.dart';
import 'two_factor_challenge_screen.dart' show copyToClipboard;

/// Perfil → Seguridad: activar o desactivar la verificación en dos pasos (TOTP).
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  TwoFactorSetup? _setup;
  List<String>? _recoveryCodes;
  bool _busy = false;
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() => _guard(() async {
        final setup = await ref.read(twoFactorRepositoryProvider).setup();
        if (mounted) setState(() => _setup = setup);
      });

  Future<void> _confirm() => _guard(() async {
        final codes = await ref.read(twoFactorRepositoryProvider).confirm(_code.text.trim());
        await ref.read(authProvider.notifier).refreshUser();
        if (!mounted) return;
        setState(() {
          _recoveryCodes = codes;
          _setup = null;
          _code.clear();
        });
      });

  Future<void> _disable() async {
    final result = await showDialog<({String password, String code})>(
      context: context,
      builder: (_) => const _DisableDialog(),
    );
    if (result == null) return;
    await _guard(() async {
      await ref.read(twoFactorRepositoryProvider).disable(password: result.password, code: result.code);
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) showAgroSnack(context, 'Verificación en dos pasos desactivada', emoji: '🔓');
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final enabled = user?.twoFactorEnabled ?? false;
    final required = user?.twoFactorRequired ?? false;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Row(
              children: [
                CircleIconButton(icon: Icons.arrow_back_rounded, background: AppColors.cream, onTap: () => context.pop()),
                const SizedBox(width: 12),
                const Text('Seguridad', style: AppText.h1),
              ],
            ),
            const SizedBox(height: 20),
            if (_recoveryCodes != null)
              _RecoveryCodes(codes: _recoveryCodes!, onDone: () => setState(() => _recoveryCodes = null))
            else if (_setup != null)
              _SetupCard(
                setup: _setup!,
                codeController: _code,
                busy: _busy,
                onConfirm: _confirm,
                onCancel: () => setState(() => _setup = null),
              )
            else
              _StatusCard(
                enabled: enabled,
                required: required,
                busy: _busy,
                onEnable: _start,
                onDisable: _disable,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.enabled,
    required this.required,
    required this.busy,
    required this.onEnable,
    required this.onDisable,
  });

  final bool enabled;
  final bool required;
  final bool busy;
  final VoidCallback onEnable;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Verificación en dos pasos', style: AppText.h3)),
              StatusPill(
                label: enabled ? 'Activa' : 'Desactivada',
                color: enabled ? AppColors.success : AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Además de tu contraseña, se pedirá un código de 6 dígitos que genera una app '
            'autenticadora (Google Authenticator, Microsoft Authenticator, Authy…).',
            style: AppText.muted,
          ),
          if (required) ...[
            const SizedBox(height: 10),
            Text(
              enabled
                  ? 'Tu cuenta tiene permisos administrativos: esta protección es obligatoria y no se puede desactivar.'
                  : 'Tu cuenta tiene permisos administrativos: debes activarla para usar la moderación.',
              style: AppText.label.copyWith(color: AppColors.clay),
            ),
          ],
          const SizedBox(height: 16),
          if (!enabled)
            AgroButton(label: 'Activar', icon: Icons.shield_outlined, loading: busy, onTap: onEnable)
          else if (!required)
            AgroButton(label: 'Desactivar', tone: ButtonTone.light, loading: busy, onTap: onDisable),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.setup,
    required this.codeController,
    required this.busy,
    required this.onConfirm,
    required this.onCancel,
  });

  final TwoFactorSetup setup;
  final TextEditingController codeController;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. Agrega AgroLink a tu app autenticadora', style: AppText.h3),
        const SizedBox(height: 6),
        const Text(
          'En la app elige "Agregar cuenta" → "Ingresar clave de configuración" y escribe esta clave '
          '(tipo: basada en tiempo).',
          style: AppText.muted,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  _grouped(setup.secret),
                  style: AppText.bodyStrong.copyWith(color: AppColors.lime, letterSpacing: 2, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: AppColors.bone),
                onPressed: () => copyToClipboard(context, setup.secret, 'Clave'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('2. Escribe el código que muestra la app', style: AppText.h3),
        const SizedBox(height: 12),
        AgroTextField(
          label: 'Código de 6 dígitos',
          icon: Icons.pin_outlined,
          hint: '123456',
          controller: codeController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        AgroButton(label: 'Confirmar y activar', icon: Icons.check_rounded, loading: busy, onTap: onConfirm),
        const SizedBox(height: 8),
        Center(child: TextButton(onPressed: onCancel, child: const Text('Cancelar'))),
      ],
    );
  }

  /// "ABCDEFGH…" → "ABCD EFGH …" para que sea fácil de teclear.
  static String _grouped(String s) {
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }
}

class _RecoveryCodes extends StatelessWidget {
  const _RecoveryCodes({required this.codes, required this.onDone});

  final List<String> codes;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Expanded(child: Text('Verificación activada', style: AppText.h3)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Guarda estos códigos de recuperación en un lugar seguro. Sirven si pierdes tu teléfono; '
          'cada uno funciona una sola vez y no volverán a mostrarse.',
          style: AppText.muted,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              for (final c in codes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SelectableText(
                    c,
                    style: AppText.bodyStrong.copyWith(color: AppColors.lime, letterSpacing: 2, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AgroButton(
          label: 'Copiar códigos',
          icon: Icons.copy_rounded,
          tone: ButtonTone.light,
          onTap: () => copyToClipboard(context, codes.join('\n'), 'Códigos'),
        ),
        const SizedBox(height: 10),
        AgroButton(label: 'Ya los guardé', onTap: onDone),
      ],
    );
  }
}

class _DisableDialog extends StatefulWidget {
  const _DisableDialog();

  @override
  State<_DisableDialog> createState() => _DisableDialogState();
}

class _DisableDialogState extends State<_DisableDialog> {
  final _password = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Desactivar verificación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Código de 6 dígitos'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.of(context).pop((password: _password.text, code: _code.text.trim())),
          child: const Text('Desactivar'),
        ),
      ],
    );
  }
}

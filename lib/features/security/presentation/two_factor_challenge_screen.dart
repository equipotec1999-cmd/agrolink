import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../auth/application/auth_controller.dart';

/// Segundo paso del inicio de sesión: código de 6 dígitos de la app autenticadora
/// (o un código de recuperación si se perdió el teléfono).
class TwoFactorChallengeScreen extends ConsumerStatefulWidget {
  const TwoFactorChallengeScreen({super.key, required this.challengeToken});

  final String challengeToken;

  @override
  ConsumerState<TwoFactorChallengeScreen> createState() => _TwoFactorChallengeScreenState();
}

class _TwoFactorChallengeScreenState extends ConsumerState<TwoFactorChallengeScreen> {
  final _input = TextEditingController();
  bool _recovery = false;
  bool _loading = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _input.text.trim();
    if (value.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).completeTwoFactor(
            widget.challengeToken,
            code: _recovery ? null : value,
            recoveryCode: _recovery ? value : null,
          );
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      // El token pendiente dura 10 min: si venció hay que volver a escribir la contraseña.
      if (e.isUnauthorized) {
        showAgroSnack(context, 'La sesión de verificación venció. Inicia sesión de nuevo.', emoji: '⏱️');
        context.go('/login');
        return;
      }
      showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleIconButton(icon: Icons.arrow_back_rounded, background: AppColors.cream, onTap: () => context.go('/login')),
              const SizedBox(height: 28),
              const Icon(Icons.shield_outlined, size: 44, color: AppColors.forest),
              const SizedBox(height: 14),
              const Text('Verificación en dos pasos', style: AppText.h2),
              const SizedBox(height: 6),
              Text(
                _recovery
                    ? 'Escribe uno de tus códigos de recuperación. Cada uno sirve una sola vez.'
                    : 'Abre tu app autenticadora y escribe el código de 6 dígitos de AgroLink.',
                style: AppText.muted,
              ),
              const SizedBox(height: 24),
              AgroTextField(
                key: ValueKey(_recovery),
                label: _recovery ? 'Código de recuperación' : 'Código de 6 dígitos',
                icon: Icons.pin_outlined,
                hint: _recovery ? 'XXXXX-XXXXX' : '123456',
                controller: _input,
                keyboardType: _recovery ? TextInputType.text : TextInputType.number,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              AgroButton(label: 'Verificar', icon: Icons.check_rounded, loading: _loading, onTap: _submit),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _recovery = !_recovery;
                    _input.clear();
                  }),
                  child: Text(
                    _recovery ? 'Usar el código de la app' : 'Usar un código de recuperación',
                    style: AppText.label.copyWith(color: AppColors.forest),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Código pegable: copia al portapapeles con aviso.
Future<void> copyToClipboard(BuildContext context, String text, String what) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showAgroSnack(context, '$what copiado', emoji: '📋');
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../data/auth_repository.dart';

/// Flujo: pedir correo → mandar código → paso 2 (código + contraseña nueva).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (Validators.email(_email.text) != null) {
      showAgroSnack(context, 'Correo inválido', emoji: '⚠️');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim().toLowerCase());
      if (!mounted) return;
      setState(() => _sent = true);
      showAgroSnack(context, 'Si el correo existe, te enviamos un código', emoji: '📬');
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (_code.text.trim().length != 6) {
      showAgroSnack(context, 'El código tiene 6 dígitos', emoji: '🔢');
      return;
    }
    if (Validators.newPassword(_password.text) != null) {
      showAgroSnack(context, 'Mínimo 8, con mayúscula, minúscula y número', emoji: '🔐');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            _email.text.trim().toLowerCase(),
            _code.text.trim(),
            _password.text,
          );
      if (!mounted) return;
      showAgroSnack(context, 'Contraseña actualizada. Inicia sesión.', emoji: '✅');
      context.go('/login');
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
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
              CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
              const SizedBox(height: 22),
              const FadeSlideIn(child: Text('Recuperar contraseña', style: AppText.h1)),
              const SizedBox(height: 6),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Text(
                  _sent
                      ? 'Escribe el código de 6 dígitos que te enviamos y una contraseña nueva.'
                      : 'Te mandamos un código al correo para cambiar la contraseña.',
                  style: AppText.muted,
                ),
              ),
              const SizedBox(height: 24),
              AgroTextField(
                label: 'Correo electrónico',
                icon: Icons.alternate_email_rounded,
                hint: 'tu@correo.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              if (!_sent) ...[
                const SizedBox(height: 20),
                AgroButton(label: 'Enviar código', icon: Icons.send_rounded, loading: _loading, onTap: _send),
              ] else ...[
                const SizedBox(height: 16),
                AgroTextField(
                  label: 'Código',
                  icon: Icons.pin_outlined,
                  hint: '6 dígitos',
                  controller: _code,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                AgroTextField(
                  label: 'Contraseña nueva',
                  icon: Icons.lock_outline_rounded,
                  hint: 'Mínimo 8, con mayúscula, minúscula y número',
                  controller: _password,
                  obscure: true,
                ),
                const SizedBox(height: 20),
                AgroButton(label: 'Cambiar contraseña', icon: Icons.check_rounded, loading: _loading, onTap: _reset),
                const SizedBox(height: 10),
                AgroButton(
                  label: 'Reenviar código',
                  tone: ButtonTone.light,
                  onTap: _loading ? null : _send,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

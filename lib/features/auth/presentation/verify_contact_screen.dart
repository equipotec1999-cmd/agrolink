import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';

/// Pantalla de confirmación de cuenta: pide el código de 6 dígitos enviado al
/// correo o al teléfono, y lo canjea por un token de sesión.
class VerifyContactScreen extends ConsumerStatefulWidget {
  const VerifyContactScreen({super.key, required this.destination, required this.channel});

  final String destination;
  final String channel;

  @override
  ConsumerState<VerifyContactScreen> createState() => _VerifyContactScreenState();
}

class _VerifyContactScreenState extends ConsumerState<VerifyContactScreen> {
  final _code = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  int _resendIn = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _code.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn <= 0) {
        t.cancel();
      } else {
        setState(() => _resendIn--);
      }
    });
  }

  Future<void> _verify() async {
    if (_code.text.length < 6) {
      showAgroSnack(context, 'Escribe los 6 dígitos del código', emoji: '⚠️');
      return;
    }
    setState(() => _verifying = true);
    try {
      await ref
          .read(authProvider.notifier)
          .completeContactVerification(destination: widget.destination, code: _code.text);
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).resendVerification(widget.destination);
      if (!mounted) return;
      showAgroSnack(context, 'Código enviado otra vez', emoji: '📬');
      _startResendTimer();
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _resending = false);
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
              const FadeSlideIn(child: Text('Confirma tu cuenta', style: AppText.h1)),
              const SizedBox(height: 6),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Text(
                  'Te mandamos un código de 6 dígitos al correo ${widget.destination}. Revisa también la carpeta de spam.',
                  style: AppText.muted,
                ),
              ),
              const SizedBox(height: 28),
              AgroTextField(
                label: 'Código',
                icon: Icons.email_outlined,
                hint: '______',
                controller: _code,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('¿No llega?  ', style: AppText.muted.copyWith(fontSize: 12.5)),
                  if (_resendIn > 0)
                    Text('Reenviar en ${_resendIn}s', style: AppText.muted.copyWith(fontSize: 12.5))
                  else
                    Pressable(
                      scale: 0.96,
                      onTap: _resending ? () {} : _resend,
                      child: Text(
                        _resending ? 'Enviando…' : 'Reenviar código',
                        style: AppText.bodyStrong.copyWith(color: AppColors.forest, fontSize: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              AgroButton(
                label: _verifying ? 'Verificando…' : 'Confirmar',
                tone: ButtonTone.lime,
                height: 52,
                onTap: _verifying ? () {} : _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

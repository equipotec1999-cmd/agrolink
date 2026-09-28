import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/agrolink_logo.dart';
import '../../../shared/widgets/motion.dart';
import '../application/auth_controller.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  // ── Easter egg "Don Destilado" ──────────────────────────────────────────
  // 7 toques seguidos al logo (máx. 2 s entre uno y otro) cambian el logo y el
  // nombre por los de Don Destilado durante 15 s; luego vuelve solo.
  static const _eggTaps = 7;
  static const _eggMaxGap = Duration(seconds: 2);
  static const _eggDuration = Duration(seconds: 15);
  int _taps = 0;
  DateTime? _lastTap;
  bool _eggActive = false;
  Timer? _eggTimer;

  void _onLogoTap() {
    if (_eggActive) return;
    final now = DateTime.now();
    if (_lastTap == null || now.difference(_lastTap!) > _eggMaxGap) _taps = 0;
    _lastTap = now;
    _taps++;
    if (_taps < _eggTaps) {
      HapticFeedback.selectionClick();
      return;
    }
    _taps = 0;
    HapticFeedback.heavyImpact();
    setState(() => _eggActive = true);
    _eggTimer?.cancel();
    _eggTimer = Timer(_eggDuration, () {
      if (mounted) setState(() => _eggActive = false);
    });
  }

  @override
  void dispose() {
    _eggTimer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(_email.text.trim(), _password.text);
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _recover() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(21))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(9)),
              ),
            ),
            const SizedBox(height: 22),
            const Text('Recuperar contraseña', style: AppText.h2),
            const SizedBox(height: 6),
            const Text('Te enviaremos un enlace seguro que vence en 60 minutos.', style: AppText.muted),
            const SizedBox(height: 20),
            const AgroTextField(label: 'Correo electrónico', icon: Icons.alternate_email_rounded, hint: 'tu@correo.com'),
            const SizedBox(height: 20),
            AgroButton(
              label: 'Enviar enlace',
              icon: Icons.send_rounded,
              onTap: () {
                Navigator.of(sheetContext).pop();
                showAgroSnack(context, 'Si el correo existe, recibirás un enlace', emoji: '📬');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        child: Column(
          children: [
            FloatingProduceHeader(
              height: h * 0.36,
              // La caja tiene altura fija a propósito (es puro decorado, no debe
              // scrollear); si el teléfono tiene la fuente del sistema más grande
              // que el default, este texto crece y desborda la caja por unos
              // pixeles. Al ser decorativo, fijamos su escala en 1.0 y dejamos
              // que el resto de la app siga respetando el tamaño de letra del
              // usuario con normalidad.
              child: MediaQuery.withNoTextScaling(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                    // FittedBox: en teléfonos bajitos el bloque se encoge en vez de
                    // desbordar la caja de altura fija.
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _onLogoTap,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 450),
                                transitionBuilder: (child, a) => FadeTransition(
                                  opacity: a,
                                  child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(a), child: child),
                                ),
                                child: _eggActive
                                    ? Image.asset(
                                        'assets/brand/easter_dd.png',
                                        key: const ValueKey('dd'),
                                        height: 118,
                                        filterQuality: FilterQuality.medium,
                                      )
                                    : const AgroLinkMark(key: ValueKey('agro'), size: 118, color: AppColors.bone),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 34,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 450),
                                child: _eggActive
                                    ? const _GoldText('Don Destilado', key: ValueKey('dd-name'))
                                    : const Center(
                                        key: ValueKey('agro-name'),
                                        child: AgroLinkWordmark(size: 30, color: AppColors.bone),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            RusticDivider(
                              color: AppColors.bone.withValues(alpha: 0.5),
                              label: 'El mercado del campo',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: AuthSheet(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FadeSlideIn(child: Text('Bienvenido de vuelta', style: AppText.h2)),
                      const SizedBox(height: 4),
                      const FadeSlideIn(
                        delay: Duration(milliseconds: 80),
                        child: Text('Entra para comprar, vender y negociar.', style: AppText.muted),
                      ),
                      const SizedBox(height: 26),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 140),
                        child: AgroTextField(
                          label: 'Correo electrónico',
                          icon: Icons.alternate_email_rounded,
                          hint: 'tu@correo.com',
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: Validators.email,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: AgroTextField(
                          label: 'Contraseña',
                          icon: Icons.lock_outline_rounded,
                          hint: '••••••••',
                          controller: _password,
                          obscure: true,
                          validator: Validators.password,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _recover,
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: AppText.label.copyWith(color: AppColors.forest),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 260),
                        child: AgroButton(
                          label: 'Entrar',
                          icon: Icons.arrow_forward_rounded,
                          loading: _loading,
                          onTap: _submit,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 320),
                        child: AgroButton(
                          label: 'Crear cuenta nueva',
                          tone: ButtonTone.light,
                          onTap: () => context.push('/register'),
                        ),
                      ),
                    ],
                  ),
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

/// Texto dorado del easter egg (degradado metálico como el logo DD).
class _GoldText extends StatelessWidget {
  const _GoldText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3DC9A), Color(0xFFC9A24B), Color(0xFF8E6A28)],
        ).createShader(bounds),
        child: Text(
          text,
          style: AppText.h1.copyWith(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: Colors.white),
        ),
      ),
    );
  }
}

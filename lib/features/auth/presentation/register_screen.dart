import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../application/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserIntent _intent = UserIntent.both;
  bool _terms = false;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_terms) {
      showAgroSnack(context, 'Acepta los términos para continuar', emoji: '📄');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .register(_name.text.trim(), _email.text.trim(), _password.text, _intent);
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
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
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                const SizedBox(height: 22),
                const FadeSlideIn(child: Text('Crea tu cuenta', style: AppText.h1)),
                const SizedBox(height: 6),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 60),
                  child: Text('Compra directo al productor o vende sin intermediarios.', style: AppText.muted),
                ),
                const SizedBox(height: 26),
                const Text('¿Qué quieres hacer?', style: AppText.label),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final (intent, emoji, label) in const [
                      (UserIntent.buy, '🛒', 'Comprar'),
                      (UserIntent.sell, '🌾', 'Vender'),
                      (UserIntent.both, '🤝', 'Ambos'),
                    ]) ...[
                      Expanded(
                        child: _IntentCard(
                          emoji: emoji,
                          label: label,
                          selected: _intent == intent,
                          onTap: () => setState(() => _intent = intent),
                        ),
                      ),
                      if (intent != UserIntent.both) const SizedBox(width: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                AgroTextField(
                  label: 'Nombre o razón social',
                  icon: Icons.person_outline_rounded,
                  hint: 'Rancho, apiario o tu nombre',
                  controller: _name,
                  validator: Validators.notEmpty,
                ),
                const SizedBox(height: 16),
                AgroTextField(
                  label: 'Correo electrónico',
                  icon: Icons.alternate_email_rounded,
                  hint: 'tu@correo.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AgroTextField(
                  label: 'Contraseña',
                  icon: Icons.lock_outline_rounded,
                  hint: 'Mínimo 8, con mayúscula, minúscula y número',
                  controller: _password,
                  obscure: true,
                  validator: Validators.newPassword,
                ),
                const SizedBox(height: 16),
                Pressable(
                  scale: 0.99,
                  onTap: () => setState(() => _terms = !_terms),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _terms ? AppColors.forest : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _terms ? AppColors.forest : AppColors.line, width: 1.6),
                        ),
                        child: _terms ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Acepto los términos de uso y el aviso de privacidad.',
                          style: AppText.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                AgroButton(label: 'Crear cuenta', icon: Icons.eco_rounded, loading: _loading, onTap: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntentCard extends StatelessWidget {
  const _IntentCard({required this.emoji, required this.label, required this.selected, required this.onTap});

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.ink : AppColors.line, width: 1.4),
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppText.label.copyWith(color: selected ? AppColors.lime : AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

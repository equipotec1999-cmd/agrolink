import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/agrolink_logo.dart';
import '../application/auth_controller.dart';
import '../../../core/push/push_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      // El usuario ya viene resuelto desde main.dart (token válido restaurado o no);
      // aquí solo decidimos a dónde navegar, sin ninguna llamada de red nueva.
      final loggedIn = ref.read(authProvider) != null;
      context.go(loggedIn ? '/home' : '/login');
      // App abierta tocando una notificación push: se va directo a esa conversación.
      if (loggedIn) {
        final route = await ref.read(pushServiceProvider)?.takePendingRoute();
        if (route != null && mounted) context.push(route);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Entrada sobria (sin rebote): el emblema aparece y crece un poco, luego el
    // nombre sube suave. Nada de ondas de colores.
    final mark = CurvedAnimation(parent: _c, curve: const Interval(0, 0.55, curve: Curves.easeOutCubic));
    final text = CurvedAnimation(parent: _c, curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic));

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: mark.value,
                  child: Transform.scale(
                    scale: 0.9 + mark.value * 0.1,
                    child: const AgroLinkMark(size: 170, color: AppColors.bone),
                  ),
                ),
                const SizedBox(height: 26),
                Opacity(
                  opacity: text.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - text.value) * 14),
                    child: Column(
                      children: [
                        const AgroLinkWordmark(size: 38, color: AppColors.bone),
                        const SizedBox(height: 14),
                        RusticDivider(
                          color: AppColors.bone.withValues(alpha: 0.45),
                          // Corto a propósito: el rótulo va en versalitas espaciadas
                          // y una frase larga no cabe en una línea en celulares chicos.
                          label: 'El campo, conectado',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

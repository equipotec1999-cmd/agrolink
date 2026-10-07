import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../features/chat/application/chat_controller.dart';
import '../../features/my_listings/data/my_listings_repository.dart';
import '../../features/settings/data/account_repository.dart';
import 'motion.dart';

/// Contenedor con barra de navegación flotante y botón central "Publicar".
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: _AgroNavBar(
        index: shell.currentIndex,
        onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        onPublish: () => context.push('/create'),
      ),
    );
  }
}

class _AgroNavBar extends ConsumerWidget {
  const _AgroNavBar({required this.index, required this.onSelect, required this.onPublish});

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onPublish;

  static const _items = [
    (Icons.home_outlined, 'Inicio'),
    (Icons.search_rounded, 'Buscar'),
    (Icons.chat_bubble_outline_rounded, 'Mensajes'),
    (Icons.person_outline_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    Widget item(int i) {
      final (icon, label) = _items[i];
      final active = i == index;
      return Expanded(
        child: Pressable(
          scale: 0.9,
          onTap: () {
            // Al entrar a Perfil se vuelven a pedir sus cifras y sus publicaciones (pudieron cambiar).
            if (i == 3) {
              ref.invalidate(profileStatsProvider);
              ref.invalidate(myListingsProvider);
            }
            onSelect(i);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(
                      icon,
                      size: 23,
                      color: active ? AppColors.lime : AppColors.bone.withValues(alpha: 0.45),
                    ),
                  ),
                  if (i == 2 && unread > 0)
                    Positioned(
                      right: -2,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.clay,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: Text(
                          '$unread',
                          style: AppText.label.copyWith(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: AppText.label.copyWith(
                  fontSize: 10.5,
                  color: active ? AppColors.bone : AppColors.bone.withValues(alpha: 0.45),
                ),
                child: Text(label),
              ),
              const SizedBox(height: 4),
              // Rombito bajo la pestaña activa (motivo ◇ del logo).
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: active ? 1 : 0,
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Container(width: 5, height: 5, color: AppColors.lime),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(20),
            // Sombra corta y tenue: solo separa la barra del contenido que pasa por debajo.
            boxShadow: [
              BoxShadow(color: AppColors.ink.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              item(0),
              item(1),
              _PublishButton(onTap: onPublish),
              item(2),
              item(3),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  const _PublishButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Pressable(
        scale: 0.88,
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.bone,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.add_rounded, color: AppColors.ink, size: 30),
        ),
      ),
    );
  }
}

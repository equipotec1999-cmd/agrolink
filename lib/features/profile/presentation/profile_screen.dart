import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../../auth/application/auth_controller.dart';
import '../../my_listings/data/my_listings_repository.dart';
import '../../my_listings/presentation/my_listings_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final name = user?.name ?? 'Productor Demo';

    void soon(String what, String phase) => showAgroSnack(context, '$what: llega en $phase', emoji: '🚧');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
          children: [
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(21)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.lime,
                          child: Text(name.substring(0, 1).toUpperCase(), style: AppText.h1.copyWith(fontSize: 26)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: AppText.h3.copyWith(color: Colors.white), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(user?.email ?? 'demo@agrolink.mx', style: AppText.muted.copyWith(color: Colors.white54)),
                              const SizedBox(height: 8),
                              const StatusPill(label: 'Correo sin verificar', color: AppColors.honey, icon: Icons.mail_outline_rounded),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _Stat(
                          value: ref.watch(myListingsProvider).maybeWhen(data: (l) => '${l.length}', orElse: () => '–'),
                          label: 'Publicaciones',
                        ),
                        const _Stat(value: '12', label: 'Ventas'),
                        const _Stat(value: '4', label: 'Compras'),
                        const _Stat(value: '4.8', label: 'Reputación'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Pressable(
                scale: 0.98,
                onTap: () => soon('Verificación de vendedor', 'Fase 6'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: AppColors.ink, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Conviértete en vendedor verificado', style: AppText.title),
                            Text('Más confianza = más ventas', style: TextStyle(fontFamily: AppText.body, fontSize: 12, color: AppColors.ink)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: AppColors.ink),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: 'Mis publicaciones', action: 'Nueva', onAction: () => context.push('/create')),
            const SizedBox(height: 12),
            const MyListingsSection(),
            const SizedBox(height: 24),
            const Text('Mi cuenta', style: AppText.h3),
            const SizedBox(height: 12),
            _MenuTile(icon: Icons.shopping_bag_outlined, label: 'Mis compras', onTap: () => context.push('/purchases')),
            _MenuTile(icon: Icons.storefront_outlined, label: 'Mis ventas', onTap: () => context.push('/sales')),
            if (user?.canModerate ?? false)
              _MenuTile(icon: Icons.shield_outlined, label: 'Moderación', onTap: () => context.push('/moderation')),
            if (user?.canManageRules ?? false)
              _MenuTile(icon: Icons.gavel_rounded, label: 'Reglas de cumplimiento', onTap: () => context.push('/compliance-rules')),
            _MenuTile(icon: Icons.lock_outline_rounded, label: 'Seguridad', onTap: () => context.push('/security')),
            _MenuTile(icon: Icons.favorite_border_rounded, label: 'Favoritos', onTap: () => context.push('/favorites')),
            _MenuTile(icon: Icons.notifications_none_rounded, label: 'Notificaciones', onTap: () => context.push('/notifications')),
            _MenuTile(icon: Icons.saved_search_rounded, label: 'Búsquedas guardadas', onTap: () => context.push('/saved-searches')),
            _MenuTile(icon: Icons.settings_outlined, label: 'Configuración', onTap: () => context.push('/settings')),
            _MenuTile(
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppText.price.copyWith(color: AppColors.lime, fontSize: 21)),
          const SizedBox(height: 2),
          Text(label, style: AppText.muted.copyWith(color: Colors.white54, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.danger = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.ink;
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.line, width: 1.2)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppText.bodyStrong.copyWith(color: color))),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

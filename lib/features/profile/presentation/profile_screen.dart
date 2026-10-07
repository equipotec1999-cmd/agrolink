import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../../auth/application/auth_controller.dart';
import '../../my_listings/data/my_listings_repository.dart';
import '../../settings/data/account_repository.dart';
import '../../verification/data/verification_repository.dart';
import '../../my_listings/presentation/my_listings_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final name = user?.name.isNotEmpty == true ? user!.fullName : 'Productor Demo';
    final avatar = user?.avatarUrl;
    final place = [user?.municipality, user?.state].where((p) => p != null && p.trim().isNotEmpty).join(', ');


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
                        Pressable(
                          onTap: () => context.push('/profile/edit'),
                          scale: 0.95,
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.lime,
                            backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                            child: avatar == null || avatar.isEmpty
                                ? Text(name.substring(0, 1).toUpperCase(), style: AppText.h1.copyWith(fontSize: 26))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: AppText.h3.copyWith(color: Colors.white), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(user?.email ?? 'demo@agrolink.mx', style: AppText.muted.copyWith(color: Colors.white54)),
                              if (place.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(place, style: AppText.muted.copyWith(color: Colors.white54, fontSize: 12)),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Pressable(
                                    onTap: () => context.push('/profile/edit'),
                                    scale: 0.95,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text('Editar', style: AppText.label.copyWith(color: Colors.white, fontSize: 11.5)),
                                      ]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (user?.bio != null && user!.bio!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(user.bio!, style: AppText.muted.copyWith(color: Colors.white70)),
                    ],
                    const SizedBox(height: 20),
                    Builder(builder: (context) {
                      final stats = ref.watch(profileStatsProvider).asData?.value;
                      String n(int? v) => v == null ? '–' : '$v';
                      return Row(
                        children: [
                          _Stat(value: n(stats?.listings), label: 'Publicaciones'),
                          _Stat(value: n(stats?.sales), label: 'Ventas'),
                          _Stat(value: n(stats?.purchases), label: 'Compras'),
                          _Stat(value: stats?.rating == null ? '–' : stats!.rating!.toStringAsFixed(1), label: 'Reputación'),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Builder(builder: (context) {
                final v = ref.watch(verificationStatusProvider).asData?.value;
                final verified = (user?.sellerVerified ?? false) || (v?.isVerified ?? false);
                final pending = !verified && (v?.isPending ?? false);
                final title = verified
                    ? 'Vendedor verificado'
                    : pending
                        ? 'Solicitud de verificación en revisión'
                        : 'Conviértete en vendedor verificado';
                final subtitle = verified
                    ? 'Tus publicaciones muestran la insignia'
                    : pending
                        ? 'Te avisaremos cuando haya respuesta'
                        : 'Más confianza = más ventas';
                return Pressable(
                  scale: 0.98,
                  onTap: () => context.push('/verification'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Icon(verified ? Icons.verified_rounded : Icons.verified_user_rounded, color: AppColors.ink, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppText.title),
                              Text(subtitle, style: const TextStyle(fontFamily: AppText.body, fontSize: 12, color: AppColors.ink)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.ink),
                      ],
                    ),
                  ),
                );
              }),
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
            if ((user?.canModerate ?? false) || (user?.canReviewDocuments ?? false))
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

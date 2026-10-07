import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/product_art.dart';
import '../data/my_listings_repository.dart';

Color _statusColor(String status) => switch (status) {
      'publicada' => AppColors.success,
      'en_revision' => AppColors.honey,
      'borrador' || 'archivada' || 'sold' || 'vencida' => AppColors.muted,
      _ => AppColors.danger,
    };

/// Sección "Mis publicaciones" del perfil: lista real con estado, motivo de moderación y acciones.
class MyListingsSection extends ConsumerWidget {
  const MyListingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(myListingsProvider);

    return listings.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text('No pudimos cargar tus publicaciones', style: AppText.muted.copyWith(color: AppColors.danger))),
            TextButton(onPressed: () => ref.invalidate(myListingsProvider), child: const Text('Reintentar')),
          ],
        ),
      ),
      data: (items) => items.isEmpty
          ? Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line, width: 1.2),
              ),
              child: const Text('Todavía no publicas nada. Toca "Nueva" para empezar.', style: AppText.muted),
            )
          : Column(children: [for (final it in items) _MyListingCard(item: it)]),
    );
  }
}

class _MyListingCard extends ConsumerWidget {
  const _MyListingCard({required this.item});

  final MyListing item;

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action, String okMessage) async {
    try {
      await action();
      ref.invalidate(myListingsProvider);
      if (context.mounted) showAgroSnack(context, okMessage, emoji: '✅');
    } on ApiException catch (e) {
      if (context.mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('¿Eliminar publicación?'),
        content: Text('"${item.title}" dejará de mostrarse.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(dialog).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(context, ref, () => ref.read(myListingsRepositoryProvider).delete(item.id), 'Publicación eliminada');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(myListingsRepositoryProvider);
    final color = _statusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/listing/${item.id}'),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: ProductArt(emoji: '📦', colorKey: '', imageUrl: item.coverUrl, radius: 14, emojiSize: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: AppText.bodyStrong, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(formatMoney(item.price), style: AppText.muted),
                      const SizedBox(height: 6),
                      StatusPill(label: item.statusLabel, color: color),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'edit':
                        await context.push('/listing/${item.id}/edit', extra: item);
                        ref.invalidate(myListingsProvider);
                      case 'archive':
                        await _run(context, ref, () => repo.archive(item.id), 'Publicación archivada');
                      case 'delete':
                        await _confirmDelete(context, ref);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    if (item.canArchive) const PopupMenuItem(value: 'archive', child: Text('Archivar')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
          ),
          if (item.moderationNote != null && (item.canResubmit || item.status == 'en_revision')) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Motivo de moderación: ${item.moderationNote}',
                style: AppText.label.copyWith(color: AppColors.danger, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          if (item.canResubmit) ...[
            const SizedBox(height: 10),
            AgroButton(
              label: 'Corregir y reenviar a revisión',
              icon: Icons.send_rounded,
              height: 44,
              tone: ButtonTone.lime,
              onTap: () => _run(context, ref, () => repo.resubmit(item.id), 'Enviada a revisión'),
            ),
          ],
          if (item.canPublish) ...[
            const SizedBox(height: 10),
            AgroButton(
              label: 'Publicar',
              icon: Icons.rocket_launch_outlined,
              height: 44,
              tone: ButtonTone.lime,
              onTap: () => _run(context, ref, () => repo.publish(item.id), 'Publicación enviada'),
            ),
          ],
        ],
      ),
    );
  }
}

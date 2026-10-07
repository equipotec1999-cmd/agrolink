import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/product_art.dart';
import '../data/operations_repository.dart';
import '../domain/operation.dart';

/// Mis compras (rol comprador) o mis ventas (rol vendedor).
class OperationsScreen extends ConsumerWidget {
  const OperationsScreen({super.key, required this.role});
  final OperationRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buying = role == OperationRole.buyer;
    final ops = ref.watch(operationsProvider(role));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
              child: Row(
                children: [
                  CircleIconButton(icon: Icons.arrow_back_rounded, background: AppColors.cream, onTap: () => context.pop()),
                  const SizedBox(width: 12),
                  Text(buying ? 'Mis compras' : 'Mis ventas', style: AppText.h1),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                buying ? 'Ofertas tuyas que el vendedor aceptó.' : 'Ofertas que aceptaste como vendedor.',
                style: AppText.muted,
              ),
            ),
            Expanded(
              child: ops.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'No pudimos cargar',
                  message: '$e',
                ),
                data: (list) => list.isEmpty
                    ? EmptyState(
                        icon: buying ? Icons.shopping_bag_outlined : Icons.storefront_outlined,
                        title: buying ? 'Aún no tienes compras' : 'Aún no tienes ventas',
                        message: 'Cuando se acepte una oferta, la operación aparecerá aquí.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(operationsProvider(role).future),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                          itemCount: list.length,
                          separatorBuilder: (context, i) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _OperationTile(operation: list[i]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  const _OperationTile({required this.operation});
  final Operation operation;

  Color get _color => switch (operation.status) {
        OperationStatus.cancelled || OperationStatus.dispute => AppColors.danger,
        OperationStatus.completed || OperationStatus.confirmed => AppColors.success,
        _ => AppColors.sky,
      };

  @override
  Widget build(BuildContext context) {
    final o = operation;
    final who = o.role == OperationRole.buyer ? 'Vendedor' : 'Comprador';
    return Pressable(
      scale: 0.98,
      // Por ahora el seguimiento de la operación se hace en la conversación.
      onTap: () => context.push('/chat/${o.conversationId}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: ProductArt(emoji: '📦', colorKey: '', imageUrl: o.coverUrl, radius: 18, emojiSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(o.listingTitle, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('#${o.id}', style: AppText.muted.copyWith(fontSize: 11)),
                    ],
                  ),
                  Text('$who: ${o.counterpart}', style: AppText.muted.copyWith(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${o.quantity.toStringAsFixed(o.quantity == o.quantity.roundToDouble() ? 0 : 2)} ${o.unit} · ${formatMoney(o.total)}',
                    style: AppText.bodyStrong.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusPill(label: o.status.label, color: _color),
                      const Spacer(),
                      Text(timeAgo(o.createdAt), style: AppText.muted.copyWith(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

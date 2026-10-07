import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../application/notifications_controller.dart';
import '../domain/app_notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationsProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final ctrl = ref.read(notificationsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
              child: Row(
                children: [
                  CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                  const SizedBox(width: 14),
                  const Expanded(child: Text('Notificaciones', style: AppText.h1)),
                  if (state.unread > 0)
                    TextButton(onPressed: ctrl.markAllRead, child: const Text('Marcar todas')),
                ],
              ),
            ),
            Expanded(
              child: state.items.isEmpty && state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty && state.error != null
                      ? EmptyState(icon: Icons.wifi_off_rounded, title: 'No pudimos cargar', message: state.error!)
                      : state.items.isEmpty
                          ? const EmptyState(
                              icon: Icons.notifications_none_rounded,
                              title: 'Sin notificaciones',
                              message: 'Aquí verás mensajes y ofertas nuevas.',
                            )
                          : RefreshIndicator(
                              onRefresh: ctrl.refresh,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 0, 20, 40),
                                itemCount: state.items.length,
                                itemBuilder: (context, i) => FadeSlideIn(
                                  delay: Duration(milliseconds: 40 * (i > 10 ? 10 : i)),
                                  child: _Tile(
                                    notification: state.items[i],
                                    onTap: () {
                                      final n = state.items[i];
                                      ctrl.markRead(n.id);
                                      final route = n.route;
                                      if (route != null) context.push(route);
                                    },
                                  ),
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

class _Tile extends StatelessWidget {
  const _Tile({required this.notification, required this.onTap});
  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.read ? AppColors.cream : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: n.read ? AppColors.line : Colors.white),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(16)),
              child: Text(n.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(n.title, style: AppText.title)),
                      if (!n.read)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(color: AppColors.clay, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(n.body, style: AppText.muted, maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(timeAgo(n.createdAt), style: AppText.muted.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

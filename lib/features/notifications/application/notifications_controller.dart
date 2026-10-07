import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';

class NotificationsState {
  const NotificationsState({this.items = const [], this.unread = 0, this.loading = false, this.error});

  final List<AppNotification> items;
  final int unread;
  final bool loading;
  final String? error;
}

/// Notificaciones dentro de la app. Se refrescan cada 30 s mientras hay sesión
/// (polling, igual que el chat) y al abrir la pantalla.
class NotificationsController extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    if (ref.watch(authProvider) == null) return const NotificationsState();
    final timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    ref.onDispose(timer.cancel);
    Future.microtask(() => refresh(initial: true));
    return const NotificationsState(loading: true);
  }

  Future<void> refresh({bool initial = false}) async {
    if (ref.read(authProvider) == null) return;
    try {
      final page = await ref.read(notificationsRepositoryProvider).list();
      if (ref.mounted) state = NotificationsState(items: page.items, unread: page.unread);
    } catch (e) {
      if (!ref.mounted) return;
      state = NotificationsState(items: state.items, unread: state.unread, error: '$e');
    }
  }

  /// Optimista: se marca al instante y se avisa al servidor; si falla, el próximo
  /// refresco la vuelve a mostrar como no leída.
  Future<void> markRead(String id) async {
    final target = state.items.where((n) => n.id == id).firstOrNull;
    if (target == null || target.read) return;
    state = NotificationsState(
      items: [for (final n in state.items) n.id == id ? n.asRead() : n],
      unread: state.unread > 0 ? state.unread - 1 : 0,
    );
    try {
      await ref.read(notificationsRepositoryProvider).markRead(id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    state = NotificationsState(items: [for (final n in state.items) n.asRead()], unread: 0);
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
    } catch (_) {}
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsController, NotificationsState>(NotificationsController.new);

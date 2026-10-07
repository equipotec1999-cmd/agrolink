import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<({List<AppNotification> items, int unread})> list();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => throw UnimplementedError('notificationsRepositoryProvider debe sobreescribirse en main.dart'),
);

class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository(this._client);

  final ApiClient _client;

  @override
  Future<({List<AppNotification> items, int unread})> list() async {
    final response = await _client.get('/notifications') as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>).map((raw) {
      final json = raw as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? const {};
      return AppNotification(
        id: '${json['id']}',
        type: '${json['type']}',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ?? DateTime.now(),
        conversationId: data['conversation_id'] == null ? null : '${data['conversation_id']}',
        read: json['read_at'] != null,
      );
    }).toList();
    return (items: items, unread: int.tryParse('${response['unread_count']}') ?? 0);
  }

  // Idempotentes en el backend.
  @override
  Future<void> markRead(String id) => _client.post('/notifications/$id/read');

  @override
  Future<void> markAllRead() => _client.post('/notifications/read-all');
}

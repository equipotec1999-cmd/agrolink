class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.conversationId,
    this.operationId,
    this.read = false,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? conversationId;
  final String? operationId;
  final bool read;

  String get emoji => switch (type) {
        'new_message' => '💬',
        'offer_received' || 'offer_countered' => '🏷️',
        'offer_accepted' => '🤝',
        'operation_updated' => '📦',
        'review_received' => '⭐',
        'offer_rejected' || 'offer_cancelled' => '🚫',
        'listing_rejected' || 'listing_suspended' => '🛡️',
        'verification_approved' => '✅',
        'verification_rejected' => '🛡️',
        _ => '🔔',
      };

  /// A dónde lleva al tocarla (hoy todas las notificaciones son de una conversación).
  String? get route => type.startsWith('verification_')
      ? '/verification'
      : (operationId != null && (type == 'operation_updated' || type == 'review_received')
          ? '/operations/$operationId'
          : (conversationId == null ? null : '/chat/$conversationId'));

  AppNotification asRead() => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        conversationId: conversationId,
        operationId: operationId,
        read: true,
      );
}

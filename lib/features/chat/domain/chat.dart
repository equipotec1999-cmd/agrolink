/// Mensaje de texto de una conversación.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.mine,
    required this.at,
    required this.text,
    this.pending = false,
    this.failed = false,
  });

  /// Id del servidor (numérico, como texto). Los mensajes aún sin confirmar
  /// llevan un id local que empieza con `tmp-`.
  final String id;
  final bool mine;
  final DateTime at;
  final String text;

  /// Enviado en la UI pero sin respuesta del servidor todavía.
  final bool pending;

  /// El servidor lo rechazó o no hubo red; se puede reintentar.
  final bool failed;

  bool get isLocal => id.startsWith('tmp-');

  ChatMessage copyWith({bool? pending, bool? failed}) => ChatMessage(
        id: id,
        mine: mine,
        at: at,
        text: text,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
      );
}

/// Cada conversación pertenece a UNA publicación (requisito del negocio) y a un
/// par comprador-vendedor. Los mensajes se cargan al abrirla; la bandeja solo
/// trae el resumen (último mensaje y no leídos).
class Conversation {
  const Conversation({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingEmoji,
    required this.listingColorKey,
    required this.listingPrice,
    required this.priceSuffix,
    required this.counterpart,
    this.listingCoverUrl,
    this.messages = const [],
    this.messagesLoaded = false,
    this.unread = 0,
    this.lastText,
    this.lastMine = false,
    this.lastAt,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String listingEmoji;
  final String listingColorKey;
  final String? listingCoverUrl;
  final double listingPrice;
  final String priceSuffix;
  final String counterpart;
  final List<ChatMessage> messages;
  final bool messagesLoaded;
  final int unread;
  final String? lastText;
  final bool lastMine;
  final DateTime? lastAt;

  /// Mayor id de servidor ya descargado (para pedir solo los nuevos con `after_id`).
  int? get lastServerId {
    int? max;
    for (final m in messages) {
      if (m.isLocal) continue;
      final v = int.tryParse(m.id);
      if (v != null && (max == null || v > max)) max = v;
    }
    return max;
  }

  Conversation copyWith({
    List<ChatMessage>? messages,
    bool? messagesLoaded,
    int? unread,
    String? lastText,
    bool? lastMine,
    DateTime? lastAt,
  }) =>
      Conversation(
        id: id,
        listingId: listingId,
        listingTitle: listingTitle,
        listingEmoji: listingEmoji,
        listingColorKey: listingColorKey,
        listingCoverUrl: listingCoverUrl,
        listingPrice: listingPrice,
        priceSuffix: priceSuffix,
        counterpart: counterpart,
        messages: messages ?? this.messages,
        messagesLoaded: messagesLoaded ?? this.messagesLoaded,
        unread: unread ?? this.unread,
        lastText: lastText ?? this.lastText,
        lastMine: lastMine ?? this.lastMine,
        lastAt: lastAt ?? this.lastAt,
      );
}

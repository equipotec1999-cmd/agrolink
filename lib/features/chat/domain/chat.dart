enum OfferStatus { sent, accepted, rejected, countered, cancelled, expired }

extension OfferStatusX on OfferStatus {
  String get label => switch (this) {
        OfferStatus.sent => 'Enviada',
        OfferStatus.accepted => 'Aceptada',
        OfferStatus.rejected => 'Rechazada',
        OfferStatus.countered => 'Contraofertada',
        OfferStatus.cancelled => 'Cancelada',
        OfferStatus.expired => 'Expirada',
      };

  bool get isOpen => this == OfferStatus.sent;

  static OfferStatus fromWire(String v) => switch (v) {
        'accepted' => OfferStatus.accepted,
        'rejected' => OfferStatus.rejected,
        'countered' => OfferStatus.countered,
        'cancelled' => OfferStatus.cancelled,
        'expired' => OfferStatus.expired,
        _ => OfferStatus.sent,
      };
}

class Offer {
  const Offer({
    required this.id,
    required this.amount,
    required this.quantity,
    required this.status,
    this.expiresAt,
    this.operationId,
  });

  final String id;
  final double amount; // precio POR UNIDAD (según el tipo de precio de la publicación)
  final double quantity;
  final OfferStatus status;
  final DateTime? expiresAt;

  /// Presente cuando la oferta fue aceptada: la operación que se creó.
  final String? operationId;

  double get total => amount * quantity;

  Offer copyWith({OfferStatus? status, String? operationId}) => Offer(
        id: id,
        amount: amount,
        quantity: quantity,
        status: status ?? this.status,
        expiresAt: expiresAt,
        operationId: operationId ?? this.operationId,
      );
}

/// Mensaje de una conversación: texto, u oferta (entonces `offer` no es null).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.mine,
    required this.at,
    this.text = '',
    this.offer,
    this.pending = false,
    this.failed = false,
  });

  /// Id del servidor (numérico, como texto). Los mensajes aún sin confirmar
  /// llevan un id local que empieza con `tmp-`.
  final String id;
  final bool mine;
  final DateTime at;
  final String text;
  final Offer? offer;

  /// Enviado en la UI pero sin respuesta del servidor todavía.
  final bool pending;

  /// El servidor lo rechazó o no hubo red; se puede reintentar.
  final bool failed;

  bool get isLocal => id.startsWith('tmp-');

  ChatMessage copyWith({bool? pending, bool? failed, Offer? offer}) => ChatMessage(
        id: id,
        mine: mine,
        at: at,
        text: text,
        offer: offer ?? this.offer,
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

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
}

class Offer {
  const Offer({required this.id, required this.amount, required this.quantity, required this.status});

  final String id;
  final double amount; // precio unitario ofrecido (según el tipo de precio de la publicación)
  final double quantity;
  final OfferStatus status;

  Offer copyWith({OfferStatus? status}) =>
      Offer(id: id, amount: amount, quantity: quantity, status: status ?? this.status);
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.mine,
    required this.at,
    this.text,
    this.offer,
    this.system = false,
  });

  final String id;
  final bool mine;
  final DateTime at;
  final String? text;
  final Offer? offer;
  final bool system;

  ChatMessage withOffer(Offer o) =>
      ChatMessage(id: id, mine: mine, at: at, text: text, offer: o, system: system);
}

/// Cada conversación pertenece a UNA publicación (requisito del negocio).
/// Guarda un resumen de la publicación tal como lo devolvería la API.
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
    required this.messages,
    this.unread = 0,
    this.typing = false,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String listingEmoji;
  final String listingColorKey;
  final double listingPrice;
  final String priceSuffix;
  final String counterpart;
  final List<ChatMessage> messages;
  final int unread;
  final bool typing;

  bool get hasOffers => messages.any((m) => m.offer != null);

  Conversation copyWith({List<ChatMessage>? messages, int? unread, bool? typing}) => Conversation(
        id: id,
        listingId: listingId,
        listingTitle: listingTitle,
        listingEmoji: listingEmoji,
        listingColorKey: listingColorKey,
        listingPrice: listingPrice,
        priceSuffix: priceSuffix,
        counterpart: counterpart,
        messages: messages ?? this.messages,
        unread: unread ?? this.unread,
        typing: typing ?? this.typing,
      );
}

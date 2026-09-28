import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/domain/catalog.dart';
import '../../listings/domain/listing.dart';
import '../domain/chat.dart';

/// ⚠️ MOCK: conversación simulada en memoria con respuestas automáticas del vendedor.
/// Fase 5: ChatRepository (REST para historial + WebSockets/Laravel Reverb en tiempo real).
class ChatController extends Notifier<List<Conversation>> {
  int _seq = 100;
  String _id() => 'm${_seq++}';

  @override
  List<Conversation> build() {
    final now = DateTime.now();
    return [
      Conversation(
        id: 'c1',
        listingId: 'l4',
        listingTitle: 'Miel multifloral de tajonal — mayoreo',
        listingEmoji: '🍯',
        listingColorKey: 'apicultura',
        listingPrice: 78,
        priceSuffix: '/kg',
        counterpart: 'Apiarios Kaab',
        unread: 2,
        messages: [
          ChatMessage(id: 'm1', mine: true, at: now.subtract(const Duration(hours: 3)), text: 'Buen día, ¿la miel se puede ver antes de comprar?'),
          ChatMessage(id: 'm2', mine: false, at: now.subtract(const Duration(hours: 2)), text: '¡Claro! Tenemos muestra y el análisis del lote AK-2604.'),
          ChatMessage(id: 'm3', mine: false, at: now.subtract(const Duration(minutes: 50)), text: 'Si se lleva más de 500 kg le hacemos precio especial.'),
        ],
      ),
      Conversation(
        id: 'c2',
        listingId: 'l3',
        listingTitle: 'Borregos Pelibuey de engorda',
        listingEmoji: '🐑',
        listingColorKey: 'animales',
        listingPrice: 2800,
        priceSuffix: '/animal',
        counterpart: 'Marisol Chan',
        unread: 1,
        messages: [
          ChatMessage(
            id: 'm4',
            mine: true,
            at: now.subtract(const Duration(days: 1, hours: 2)),
            offer: const Offer(id: 'o1', amount: 2400, quantity: 10, status: OfferStatus.countered),
          ),
          ChatMessage(
            id: 'm5',
            mine: false,
            at: now.subtract(const Duration(days: 1)),
            offer: const Offer(id: 'o2', amount: 2650, quantity: 10, status: OfferStatus.sent),
          ),
        ],
      ),
    ];
  }

  Conversation? byId(String id) {
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _update(String id, Conversation Function(Conversation c) fn) {
    state = [for (final c in state) c.id == id ? fn(c) : c];
  }

  void _append(String id, ChatMessage m) =>
      _update(id, (c) => c.copyWith(messages: [...c.messages, m]));

  /// Abre (o crea) la conversación ligada a una publicación.
  String openFor(Listing l) {
    for (final c in state) {
      if (c.listingId == l.id) return c.id;
    }
    final c = Conversation(
      id: 'c${_seq++}',
      listingId: l.id,
      listingTitle: l.title,
      // placeholderEmoji, no `cover`: con datos reales `cover` es la URL de la
      // foto y la miniatura del chat la dibujaría como texto.
      listingEmoji: l.placeholderEmoji,
      listingColorKey: l.categoryId,
      listingPrice: l.price,
      priceSuffix: l.priceType.suffix,
      counterpart: l.seller.name,
      messages: const [],
    );
    state = [c, ...state];
    return c.id;
  }

  void markRead(String id) => _update(id, (c) => c.copyWith(unread: 0));

  Future<void> sendText(String convId, String text) async {
    _append(convId, ChatMessage(id: _id(), mine: true, at: DateTime.now(), text: text));
    await _sellerTyping(convId);
    _append(
      convId,
      ChatMessage(
        id: _id(),
        mine: false,
        at: DateTime.now(),
        text: 'Gracias por escribir 🙌 Le confirmo disponibilidad en un momento.',
      ),
    );
  }

  Future<void> sendOffer(String convId, double amount, double quantity) async {
    _append(
      convId,
      ChatMessage(
        id: _id(),
        mine: true,
        at: DateTime.now(),
        offer: Offer(id: _id(), amount: amount, quantity: quantity, status: OfferStatus.sent),
      ),
    );
    await _sellerTyping(convId);

    // El vendedor (simulado) responde con contraoferta a mitad de camino.
    final c = byId(convId);
    if (c == null) return;
    final counter = ((amount + c.listingPrice) / 2 / 10).round() * 10.0;
    _setLastOpenOffer(convId, mine: true, status: OfferStatus.countered);
    _append(
      convId,
      ChatMessage(
        id: _id(),
        mine: false,
        at: DateTime.now(),
        offer: Offer(id: _id(), amount: counter, quantity: quantity, status: OfferStatus.sent),
      ),
    );
  }

  void respond(String convId, String messageId, OfferStatus status) {
    _update(convId, (c) {
      final msgs = [
        for (final m in c.messages)
          m.id == messageId && m.offer != null ? m.withOffer(m.offer!.copyWith(status: status)) : m,
      ];
      return c.copyWith(messages: msgs);
    });
    if (status == OfferStatus.accepted) {
      _append(
        convId,
        ChatMessage(
          id: _id(),
          mine: false,
          system: true,
          at: DateTime.now(),
          text: 'Oferta aceptada · Se creó la operación #OP-${1000 + _seq} (OFERTA_ACEPTADA)',
        ),
      );
    }
  }

  void _setLastOpenOffer(String convId, {required bool mine, required OfferStatus status}) {
    _update(convId, (c) {
      final idx = c.messages.lastIndexWhere((m) => m.mine == mine && (m.offer?.status.isOpen ?? false));
      if (idx < 0) return c;
      final msgs = [...c.messages];
      msgs[idx] = msgs[idx].withOffer(msgs[idx].offer!.copyWith(status: status));
      return c.copyWith(messages: msgs);
    });
  }

  Future<void> _sellerTyping(String convId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _update(convId, (c) => c.copyWith(typing: true));
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    _update(convId, (c) => c.copyWith(typing: false));
  }
}

final chatProvider = NotifierProvider<ChatController, List<Conversation>>(ChatController.new);

final conversationProvider = Provider.family<Conversation?, String>((ref, id) {
  final list = ref.watch(chatProvider);
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});

final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(chatProvider).fold(0, (sum, c) => sum + c.unread),
);

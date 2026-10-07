import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../catalog/domain/catalog.dart';
import '../../listings/data/api_listing_repository.dart' show priceTypeFromWire;
import '../domain/chat.dart';

/// Contrato del chat. La UI solo conoce esta interfaz.
abstract interface class ChatRepository {
  /// Bandeja: mis conversaciones (solo resumen, sin mensajes).
  Future<List<Conversation>> conversations();

  /// Abre (o recupera) mi conversación con el vendedor de una publicación.
  Future<Conversation> open(String listingId);

  /// Mensajes en orden cronológico. Con [afterId] solo los posteriores (polling).
  /// Al pedirlos, el servidor marca como leídos los de la otra persona.
  ///
  /// `offers` trae el estado ACTUAL de todas las ofertas de la conversación: una
  /// oferta vieja pudo ser aceptada/rechazada después y el polling con `afterId`
  /// no vuelve a traer su mensaje.
  Future<({List<ChatMessage> messages, List<Offer> offers})> messages(String conversationId, {int? afterId});

  Future<ChatMessage> send(String conversationId, String text);

  /// Envía una oferta (o contraoferta si hay una abierta de la otra persona).
  /// `amount` es el precio por unidad.
  Future<ChatMessage> sendOffer(String conversationId, {required double amount, required double quantity});

  /// action: 'accept' | 'reject' | 'cancel'. Devuelve la oferta ya actualizada.
  Future<Offer> respondOffer(String offerId, String action);
}

/// Se sobreescribe en main.dart con la implementación real; este default solo
/// aplica si algo corre sin pasar por main.dart (tests).
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => throw UnimplementedError('chatRepositoryProvider debe sobreescribirse en main.dart'),
);

/// Chat contra Laravel (/api/conversations). El catálogo traduce el
/// `product_type_id` numérico del servidor al emoji/categoría de la app.
class ApiChatRepository implements ChatRepository {
  ApiChatRepository(this._client, this._catalog, {required this.myId});

  final ApiClient _client;
  final Catalog _catalog;

  /// Id del usuario con sesión: define cuáles mensajes son "míos".
  final int Function() myId;

  @override
  Future<List<Conversation>> conversations() async {
    final response = await _client.get('/conversations') as Map<String, dynamic>;
    return (response['data'] as List<dynamic>)
        .map((raw) => _conversation(raw as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Conversation> open(String listingId) async {
    final response = await _client.post('/listings/$listingId/conversation') as Map<String, dynamic>;
    return _conversation(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<({List<ChatMessage> messages, List<Offer> offers})> messages(String conversationId, {int? afterId}) async {
    final response = await _client.get(
      '/conversations/$conversationId/messages',
      query: afterId == null ? null : {'after_id': afterId},
    ) as Map<String, dynamic>;
    return (
      messages: (response['data'] as List<dynamic>).map((raw) => _message(raw as Map<String, dynamic>)).toList(),
      offers: (response['offers'] as List<dynamic>? ?? const [])
          .map((raw) => _offer(raw as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<ChatMessage> sendOffer(String conversationId, {required double amount, required double quantity}) async {
    final response = await _client.post(
      '/conversations/$conversationId/offers',
      body: {'amount': amount, 'quantity': quantity},
    ) as Map<String, dynamic>;
    return _message(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<Offer> respondOffer(String offerId, String action) async {
    final response = await _client.post('/offers/$offerId/$action') as Map<String, dynamic>;
    return _offer(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<ChatMessage> send(String conversationId, String text) async {
    final response = await _client.post(
      '/conversations/$conversationId/messages',
      body: {'body': text},
    ) as Map<String, dynamic>;
    return _message(response['data'] as Map<String, dynamic>);
  }

  ChatMessage _message(Map<String, dynamic> json) {
    final offer = json['offer'] as Map<String, dynamic>?;
    return ChatMessage(
      id: '${json['id']}',
      mine: '${json['sender_id']}' == '${myId()}',
      at: DateTime.tryParse('${json['created_at']}')?.toLocal() ?? DateTime.now(),
      text: json['body'] as String? ?? '',
      offer: offer == null ? null : _offer(offer),
    );
  }

  // Laravel manda los decimales como número o como texto según el campo; se parsean
  // de forma tolerante.
  Offer _offer(Map<String, dynamic> json) => Offer(
        id: '${json['id']}',
        amount: double.tryParse('${json['amount']}') ?? 0,
        quantity: double.tryParse('${json['quantity']}') ?? 0,
        status: OfferStatusX.fromWire('${json['status']}'),
        expiresAt: DateTime.tryParse('${json['expires_at'] ?? ''}')?.toLocal(),
        operationId: json['operation_id'] == null ? null : '${json['operation_id']}',
      );

  Conversation _conversation(Map<String, dynamic> json) {
    final listing = json['listing'] as Map<String, dynamic>;
    final other = json['other_user'] as Map<String, dynamic>;
    final last = json['last_message'] as Map<String, dynamic>?;

    // Si el tipo de producto ya no está en el catálogo cargado, se usa un
    // marcador genérico en vez de tronar toda la bandeja.
    ProductType? type;
    final typeId = int.tryParse('${listing['product_type_id']}');
    for (final t in _catalog.productTypes) {
      if (t.backendId == typeId) type = t;
    }

    return Conversation(
      id: '${json['id']}',
      listingId: '${listing['id']}',
      listingTitle: listing['title'] as String? ?? '',
      listingEmoji: type?.emoji ?? '📦',
      listingColorKey: type?.categoryId ?? '',
      listingCoverUrl: listing['cover_url'] as String?,
      listingPrice: double.tryParse('${listing['price'] ?? 0}') ?? 0,
      priceSuffix: priceTypeFromWire('${listing['price_type'] ?? 'fixed'}').suffix,
      counterpart: other['name'] as String? ?? '',
      counterpartId: other['id'] == null ? null : '${other['id']}',
      unread: int.tryParse('${json['unread_count']}') ?? 0,
      lastText: last == null ? null : (last['has_offer'] == true ? '🏷️ Oferta' : last['body'] as String?),
      lastMine: last != null && '${last['sender_id']}' == '${myId()}',
      lastAt: DateTime.tryParse('${last?['created_at'] ?? json['last_message_at'] ?? ''}')?.toLocal(),
    );
  }
}

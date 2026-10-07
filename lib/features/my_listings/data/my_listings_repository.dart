import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/application/auth_controller.dart';

/// Una publicación propia, con lo necesario para gestionarla (estado, motivo de moderación…).
class MyListing {
  const MyListing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.negotiable,
    required this.status,
    this.moderationNote,
    this.coverUrl,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final double quantity;
  final String unit;
  final bool negotiable;

  /// Valor del backend: draft, pending_review, published, rejected, suspended, sold, expired, archived.
  final String status;
  final String? moderationNote;
  final String? coverUrl;

  bool get canResubmit => status == 'rejected' || status == 'suspended';
  bool get canPublish => status == 'draft';
  bool get canArchive => const {'published', 'pending_review', 'rejected', 'suspended', 'expired'}.contains(status);

  String get statusLabel => switch (status) {
        'draft' => 'Borrador',
        'pending_review' => 'En revisión',
        'published' => 'Publicado',
        'rejected' => 'Rechazado',
        'suspended' => 'Suspendido',
        'sold' => 'Vendido',
        'expired' => 'Vencido',
        'archived' => 'Archivado',
        _ => status,
      };

  factory MyListing.fromJson(Map<String, dynamic> json) {
    final media = json['media'] as List<dynamic>? ?? const [];
    final note = json['moderation_note'] as String?;
    return MyListing(
      id: '${json['id']}',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      quantity: double.tryParse('${json['quantity'] ?? 1}') ?? 1,
      unit: json['unit'] as String? ?? '',
      negotiable: json['negotiable'] == true,
      status: json['status'] as String? ?? '',
      moderationNote: note == null || note.trim().isEmpty ? null : note.trim(),
      coverUrl: media.isEmpty ? null : (media.first as Map<String, dynamic>)['url'] as String?,
    );
  }
}

abstract interface class MyListingsRepository {
  Future<List<MyListing>> list();
  Future<void> resubmit(String id);
  Future<void> publish(String id);
  Future<void> archive(String id);
  Future<void> delete(String id);
  Future<void> update(String id, {String? title, String? description, double? price, double? quantity, bool? negotiable});
}

final myListingsRepositoryProvider = Provider<MyListingsRepository>(
  (ref) => throw UnimplementedError('myListingsRepositoryProvider debe sobreescribirse en main.dart'),
);

final myListingsProvider = FutureProvider.autoDispose<List<MyListing>>((ref) {
  // Depende de la sesión: al cambiar de usuario se vuelve a pedir (no se ven las del anterior).
  if (ref.watch(authProvider) == null) return const <MyListing>[];
  return ref.watch(myListingsRepositoryProvider).list();
});

class ApiMyListingsRepository implements MyListingsRepository {
  ApiMyListingsRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<MyListing>> list() async {
    final response = await _client.get('/my/listings') as Map<String, dynamic>;
    return (response['data'] as List<dynamic>).map((e) => MyListing.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> resubmit(String id) async => _client.post('/listings/$id/resubmit');

  @override
  Future<void> publish(String id) async => _client.post('/listings/$id/publish');

  @override
  Future<void> archive(String id) async => _client.post('/listings/$id/archive');

  @override
  Future<void> delete(String id) async => _client.delete('/listings/$id');

  @override
  Future<void> update(String id,
      {String? title, String? description, double? price, double? quantity, bool? negotiable}) async {
    await _client.patch('/listings/$id', body: {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (quantity != null) 'quantity': quantity,
      if (negotiable != null) 'negotiable': negotiable,
    });
  }
}

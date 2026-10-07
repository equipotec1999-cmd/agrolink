import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Favoritos del usuario en el backend (Laravel: /api/favorites).
abstract interface class FavoritesRepository {
  Future<Set<String>> ids();
  Future<void> add(String listingId);
  Future<void> remove(String listingId);
}

class ApiFavoritesRepository implements FavoritesRepository {
  ApiFavoritesRepository(this._client);

  final ApiClient _client;

  @override
  Future<Set<String>> ids() async {
    final response = await _client.get('/favorites/ids') as Map<String, dynamic>;
    return (response['data'] as List<dynamic>).map((id) => '$id').toSet();
  }

  // PUT/DELETE son idempotentes en el backend: repetirlos no hace daño.
  @override
  Future<void> add(String listingId) => _client.put('/favorites/$listingId');

  @override
  Future<void> remove(String listingId) => _client.delete('/favorites/$listingId');
}

/// Se sobreescribe en main.dart con la implementación real. Es nullable a
/// propósito: sin override (tests) los favoritos funcionan solo en memoria.
final favoritesRepositoryProvider = Provider<FavoritesRepository?>((ref) => null);

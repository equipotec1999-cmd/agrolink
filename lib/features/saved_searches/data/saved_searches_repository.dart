import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/application/auth_controller.dart';
import '../../search/domain/search_filters.dart';

class SavedSearch {
  const SavedSearch({required this.id, required this.name, required this.filters});
  final String id;
  final String name;
  final SearchFilters filters;
}

abstract interface class SavedSearchesRepository {
  Future<List<SavedSearch>> list();
  Future<void> save(String name, SearchFilters filters);
  Future<void> delete(String id);
}

final savedSearchesRepositoryProvider = Provider<SavedSearchesRepository>(
  (ref) => throw UnimplementedError('savedSearchesRepositoryProvider debe sobreescribirse en main.dart'),
);

final savedSearchesProvider = FutureProvider.autoDispose<List<SavedSearch>>((ref) {
  if (ref.watch(authProvider) == null) return const <SavedSearch>[];
  return ref.watch(savedSearchesRepositoryProvider).list();
});

class ApiSavedSearchesRepository implements SavedSearchesRepository {
  ApiSavedSearchesRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<SavedSearch>> list() async {
    final r = await _client.get('/saved-searches') as Map<String, dynamic>;
    return (r['data'] as List<dynamic>).map((raw) {
      final j = raw as Map<String, dynamic>;
      final f = j['filters'];
      return SavedSearch(
        id: '${j['id']}',
        name: j['name'] as String? ?? '',
        filters: SearchFilters.fromJson(f is Map<String, dynamic> ? f : const {}),
      );
    }).toList();
  }

  @override
  Future<void> save(String name, SearchFilters filters) async =>
      _client.post('/saved-searches', body: {'name': name, 'filters': filters.toJson()});

  @override
  Future<void> delete(String id) async => _client.delete('/saved-searches/$id');
}

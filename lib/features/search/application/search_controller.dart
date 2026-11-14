import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../listings/data/listing_repository.dart';
import '../../listings/domain/listing.dart';
import '../domain/query_parser.dart';
import '../domain/search_filters.dart';

class SearchFiltersController extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  void setQuery(String q) => state = state.copyWith(query: q);

  void setCategory(String? id) => state = id == null
      ? state.copyWith(clearCategory: true, clearType: true, attributeValues: const {})
      : state.copyWith(categoryId: id, clearType: true, attributeValues: const {});

  void setSort(SortOption s) => state = state.copyWith(sort: s);

  void apply(SearchFilters f) => state = f;

  void reset() => state = SearchFilters(query: state.query, categoryId: state.categoryId);
}

final searchFiltersProvider = NotifierProvider<SearchFiltersController, SearchFilters>(
  SearchFiltersController.new,
);

final searchResultsProvider = FutureProvider<List<Listing>>((ref) async {
  final filters = ref.watch(searchFiltersProvider);
  final repo = ref.watch(listingRepositoryProvider);

  // Debounce: mientras se escribe, cada letra reconstruye este provider; esperar un momento
  // evita una petición HTTP por tecla (la anterior queda descartada). Los chips y filtros
  // (sin texto) responden al instante.
  if (filters.query.trim().isNotEmpty) {
    var cancelled = false;
    ref.onDispose(() => cancelled = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (cancelled) return const <Listing>[];
  }
  return repo.search(filters);
});

final parsedQueryProvider = Provider<ParsedQuery>(
  (ref) => parseQuery(ref.watch(searchFiltersProvider.select((f) => f.query))),
);

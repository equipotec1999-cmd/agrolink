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

final searchResultsProvider = FutureProvider<List<Listing>>((ref) {
  final filters = ref.watch(searchFiltersProvider);
  return ref.watch(listingRepositoryProvider).search(filters);
});

final parsedQueryProvider = Provider<ParsedQuery>(
  (ref) => parseQuery(ref.watch(searchFiltersProvider.select((f) => f.query))),
);

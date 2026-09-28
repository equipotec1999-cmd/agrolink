class NumRange {
  const NumRange({this.min, this.max});
  final double? min;
  final double? max;

  bool contains(double v) => (min == null || v >= min!) && (max == null || v <= max!);
}

enum SortOption { nearest, priceAsc, priceDesc, newest }

extension SortOptionLabel on SortOption {
  String get label => switch (this) {
        SortOption.nearest => 'Más cercanos',
        SortOption.priceAsc => 'Precio: menor a mayor',
        SortOption.priceDesc => 'Precio: mayor a menor',
        SortOption.newest => 'Más recientes',
      };
}

/// Filtros combinables. Se serializan tal cual como query params hacia la API
/// (GET /api/v1/listings?q=&category=&type=&attr[raza]=&range[peso]=35,50...).
class SearchFilters {
  const SearchFilters({
    this.query = '',
    this.categoryId,
    this.productTypeId,
    this.maxDistanceKm,
    this.verifiedOnly = false,
    this.negotiableOnly = false,
    this.lotsOnly = false,
    this.attributeValues = const {},
    this.sort = SortOption.nearest,
  });

  final String query;
  final String? categoryId;
  final String? productTypeId;
  final int? maxDistanceKm;
  final bool verifiedOnly;
  final bool negotiableOnly;
  final bool lotsOnly;
  final Map<String, Set<String>> attributeValues;
  final SortOption sort;

  int get activeCount =>
      (productTypeId != null ? 1 : 0) +
      (maxDistanceKm != null ? 1 : 0) +
      (verifiedOnly ? 1 : 0) +
      (negotiableOnly ? 1 : 0) +
      (lotsOnly ? 1 : 0) +
      attributeValues.values.where((s) => s.isNotEmpty).length;

  SearchFilters copyWith({
    String? query,
    String? categoryId,
    bool clearCategory = false,
    String? productTypeId,
    bool clearType = false,
    int? maxDistanceKm,
    bool clearDistance = false,
    bool? verifiedOnly,
    bool? negotiableOnly,
    bool? lotsOnly,
    Map<String, Set<String>>? attributeValues,
    SortOption? sort,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      productTypeId: clearType ? null : (productTypeId ?? this.productTypeId),
      maxDistanceKm: clearDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      negotiableOnly: negotiableOnly ?? this.negotiableOnly,
      lotsOnly: lotsOnly ?? this.lotsOnly,
      attributeValues: attributeValues ?? this.attributeValues,
      sort: sort ?? this.sort,
    );
  }
}

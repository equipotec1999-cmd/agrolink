import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/domain/catalog.dart';
import '../../search/domain/search_filters.dart';
import '../domain/listing.dart';
import '../domain/listing_draft.dart';

/// Contrato de publicaciones. La UI solo conoce esta interfaz.
abstract interface class ListingRepository {
  Future<List<Listing>> feed();
  Future<Listing?> byId(String id);
  Future<List<Listing>> search(SearchFilters filters);
  Future<List<Listing>> byIds(Set<String> ids);

  /// Publicaciones guardadas por el usuario con sesión iniciada.
  Future<List<Listing>> favorites();

  /// Crea el listing (draft), sube sus fotos en orden y lo publica.
  /// `lat`/`lng` son la ubicación real del dispositivo (Fase 1 §6: el punto
  /// exacto nunca sale de aquí hacia la UI; el backend le aplica el jitter).
  Future<Listing> publishDraft(ListingDraft draft, ProductType type, {required double lat, required double lng});
}

/// Se sobreescribe en main.dart con la implementación real (ApiListingRepository);
/// este default solo aplica si algo corre sin pasar por main.dart (tests).
final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => throw UnimplementedError('listingRepositoryProvider debe sobreescribirse en main.dart'),
);

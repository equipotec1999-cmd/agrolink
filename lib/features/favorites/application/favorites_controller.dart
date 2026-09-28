import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../listings/data/listing_repository.dart';
import '../../listings/domain/listing.dart';

/// Favoritos con actualización optimista: la UI responde al instante y
/// (Fase 4) se sincroniza con POST/DELETE /api/v1/favorites/{listing}.
class FavoritesController extends Notifier<Set<String>> {
  @override
  // Sin persistencia todavía (ni local ni en backend — no hay tabla de
  // favoritos expuesta por la API aún): arranca vacío y se pierde al cerrar
  // la app. Pendiente: sincronizar con POST/DELETE /api/favorites/{listing}.
  Set<String> build() => {};

  void toggle(String listingId) {
    final next = {...state};
    if (!next.remove(listingId)) next.add(listingId);
    state = next;
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);

final favoriteListingsProvider = FutureProvider<List<Listing>>((ref) {
  final ids = ref.watch(favoritesProvider);
  return ref.watch(listingRepositoryProvider).byIds(ids);
});

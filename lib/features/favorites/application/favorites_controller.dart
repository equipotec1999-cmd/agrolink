import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../listings/data/listing_repository.dart';
import '../../listings/domain/listing.dart';
import '../data/favorites_repository.dart';

/// Favoritos con actualización optimista: la UI responde al instante y se
/// sincroniza con PUT/DELETE /api/favorites/{listing}; si el servidor falla,
/// se revierte el cambio. Al iniciar sesión baja los ids guardados del servidor
/// y al cerrar sesión se vacía.
class FavoritesController extends Notifier<Set<String>> {
  int _loadToken = 0;

  @override
  Set<String> build() {
    final user = ref.watch(authProvider);
    final repo = ref.watch(favoritesRepositoryProvider);
    if (user == null || repo == null) return {};
    _load(repo);
    return {};
  }

  Future<void> _load(FavoritesRepository repo) async {
    final token = ++_loadToken;
    try {
      final ids = await repo.ids();
      // Descarta la respuesta si mientras tanto cambió la sesión o se recargó.
      if (ref.mounted && token == _loadToken) state = ids;
    } catch (_) {
      // Sin red al arrancar: se queda vacío y se reintenta en el próximo login/recarga.
    }
  }

  /// Devuelve false si el servidor rechazó el cambio (ya revertido en la UI).
  Future<bool> toggle(String listingId) async {
    final wasFavorite = state.contains(listingId);
    _set(listingId, !wasFavorite);

    final repo = ref.read(favoritesRepositoryProvider);
    if (repo == null || ref.read(authProvider) == null) return true;

    try {
      wasFavorite ? await repo.remove(listingId) : await repo.add(listingId);
      return true;
    } catch (_) {
      if (ref.mounted) _set(listingId, wasFavorite);
      return false;
    }
  }

  void _set(String listingId, bool favorite) {
    final next = {...state};
    favorite ? next.add(listingId) : next.remove(listingId);
    state = next;
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);

final favoriteListingsProvider = FutureProvider<List<Listing>>((ref) {
  // Se vuelve a pedir cuando cambia el conjunto de ids (p. ej. al quitar uno).
  ref.watch(favoritesProvider);
  return ref.watch(listingRepositoryProvider).favorites();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/catalog.dart';

/// Contrato del catálogo. `load()` es async porque la implementación real (Fase 4) hace
/// GET /api/categories; el resultado se resuelve UNA vez al arrancar la app (ver main.dart)
/// y se expone después como valor síncrono vía `catalogProvider`, para no tener que tocar
/// las ~9 pantallas que ya hacen `ref.watch(catalogProvider)` esperando un `Catalog` directo.
abstract interface class CatalogRepository {
  Future<Catalog> load();
}

/// Se sobreescribe en main.dart con la implementación real (ApiCatalogRepository) antes de
/// levantar la app; este default solo aplica si algo corre sin pasar por main.dart (tests).
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => throw UnimplementedError('catalogRepositoryProvider debe sobreescribirse en main.dart'),
);

/// Se sobreescribe en main.dart con el Catalog ya resuelto (ver nota arriba).
final catalogProvider = Provider<Catalog>(
  (ref) => throw UnimplementedError('catalogProvider debe sobreescribirse en main.dart'),
);

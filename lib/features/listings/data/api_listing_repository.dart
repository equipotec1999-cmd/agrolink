import 'package:geolocator/geolocator.dart';

import '../../../core/location/device_location.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../catalog/domain/catalog.dart';
import '../../search/domain/search_filters.dart';
import '../domain/listing.dart';
import '../domain/listing_draft.dart';
import 'listing_repository.dart';

/// Implementación real contra Laravel (Fase 4). El catálogo (con sus `backendId`)
/// ya está resuelto en `main.dart` antes de construir esto, así que aquí solo se
/// usa para traducir id numérico <-> slug entre la API y el resto de la UI.
class ApiListingRepository implements ListingRepository {
  ApiListingRepository(this._client, this._catalog);

  final ApiClient _client;
  final Catalog _catalog;

  @override
  Future<List<Listing>> feed() async {
    final response = await _client.get('/listings') as Map<String, dynamic>;
    return _mapPage(response);
  }

  @override
  Future<Listing?> byId(String id) async {
    try {
      final response = await _client.get('/listings/$id') as Map<String, dynamic>;
      final pos = await DeviceLocation.lastKnown();
      return _fromJson(response['data'] as Map<String, dynamic>, pos);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<Listing>> byIds(Set<String> ids) async {
    // No hay endpoint de "traer varios por id" todavía — la única pantalla que
    // los necesita (favoritos) suele tener pocos, así que se piden uno por uno.
    // Uno que ya no exista (borrado) se omite en vez de tronar toda la lista.
    final results = <Listing>[];
    for (final id in ids) {
      final listing = await byId(id);
      if (listing != null) results.add(listing);
    }
    return results;
  }

  @override
  Future<List<Listing>> favorites() async {
    final response = await _client.get('/favorites') as Map<String, dynamic>;
    return _mapPage(response);
  }

  @override
  Future<List<Listing>> search(SearchFilters f) async {
    final query = <String, dynamic>{};
    if (f.query.trim().isNotEmpty) query['q'] = f.query.trim();
    if (f.productTypeId != null) {
      query['product_type_id'] = _catalog.type(f.productTypeId!).backendId;
    } else if (f.categoryId != null) {
      query['category_id'] = _catalog.category(f.categoryId!).backendId;
    }

    final response = await _client.get('/listings', query: query) as Map<String, dynamic>;
    var results = await _mapPage(response);

    // El backend (Fase 4) todavía solo filtra por texto/tipo/categoría — el
    // resto de los filtros de la pantalla de búsqueda (atributos, rango,
    // distancia, negociable, lote) se refinan aquí, igual que hacía el mock,
    // hasta que se muevan al query de Laravel.
    results = results.where((l) {
      if (f.maxDistanceKm != null && l.location.hasKnownDistance && l.location.distanceKm > f.maxDistanceKm!) {
        return false;
      }
      if (f.verifiedOnly && !l.hasVerifiedInfo) return false;
      if (f.negotiableOnly && !l.negotiable) return false;
      if (f.lotsOnly && !l.isLot) return false;

      for (final entry in f.attributeValues.entries) {
        if (entry.value.isEmpty) continue;
        final v = l.valueOf(entry.key);
        if (v == null || !entry.value.contains(v)) return false;
      }
      return true;
    }).toList();

    switch (f.sort) {
      case SortOption.nearest:
        results.sort((a, b) => a.location.distanceKm.compareTo(b.location.distanceKm));
      case SortOption.priceAsc:
        results.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceDesc:
        results.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.newest:
        results.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    }
    return results;
  }

  @override
  Future<Listing> publishDraft(
    ListingDraft draft,
    ProductType type, {
    required double lat,
    required double lng,
  }) async {
    final body = {
      'product_type_id': type.backendId,
      'title': draft.title.trim(),
      if (draft.description.trim().isNotEmpty) 'description': draft.description.trim(),
      if (draft.priceType != PriceType.quote) 'price': double.tryParse(draft.price),
      'price_type': _priceTypeWire(draft.priceType ?? type.priceTypes.first),
      'quantity': double.tryParse(draft.quantity) ?? 0,
      'unit': draft.unit.trim(),
      'sale_mode': draft.isLot ? 'lot' : 'individual',
      'negotiable': draft.negotiable,
      'attributes': draft.attributes,
      'location': {
        'state': draft.state,
        'municipality': draft.municipality,
        if (draft.postalCode.trim().isNotEmpty) 'postal_code': draft.postalCode.trim(),
        'lat': lat,
        'lng': lng,
      },
    };

    final created = await _client.post('/listings', body: body) as Map<String, dynamic>;
    final listingId = (created['data'] as Map<String, dynamic>)['id'];

    // Se sube una por una y en orden (la posición la define el orden de subida;
    // ver ListingController::uploadMedia en el backend). Si una foto falla (p.ej.
    // el archivo ya no existe), se sigue con las demás en vez de tronar todo el
    // flujo de publicar — el usuario ya vio y aceptó completar sin ella.
    for (final path in draft.photos) {
      try {
        await _client.postMultipart('/listings/$listingId/media', fieldName: 'photo', filePath: path);
      } catch (_) {
        continue;
      }
    }

    final published = await _client.post('/listings/$listingId/publish') as Map<String, dynamic>;
    final pos = await DeviceLocation.lastKnown();
    return _fromJson(published['data'] as Map<String, dynamic>, pos);
  }

  Future<List<Listing>> _mapPage(Map<String, dynamic> response) async {
    final data = response['data'] as List<dynamic>;
    final pos = await DeviceLocation.lastKnown();
    return data.map((raw) => _fromJson(raw as Map<String, dynamic>, pos)).toList();
  }

  Listing _fromJson(Map<String, dynamic> json, Position? pos) {
    final ptJson = json['product_type'] as Map<String, dynamic>;
    final type = _catalog.productTypes.firstWhere(
      (t) => t.backendId == ptJson['id'],
      orElse: () => throw StateError(
        'Listing ${json['id']}: el catálogo cargado no tiene el tipo de producto ${ptJson['id']} '
        '(¿se agregó en el backend después de que la app cargó el catálogo?).',
      ),
    );
    final category = _catalog.categories.firstWhere(
      (c) => c.backendId == ptJson['category_id'],
      orElse: () => throw StateError(
        'Listing ${json['id']}: el catálogo cargado no tiene la categoría ${ptJson['category_id']}.',
      ),
    );

    final locJson = json['location'] as Map<String, dynamic>?;
    final approxLat = (locJson?['approx_lat'] as num?)?.toDouble();
    final approxLng = (locJson?['approx_lng'] as num?)?.toDouble();
    final distanceKm = (pos != null && approxLat != null && approxLng != null)
        ? DeviceLocation.distanceKm(pos.latitude, pos.longitude, approxLat, approxLng)
        : -1.0;

    final mediaJson = json['media'] as List<dynamic>? ?? const [];
    final gallery = mediaJson.map((m) => (m as Map<String, dynamic>)['url'] as String).toList();

    final attrsCache = json['attributes'] as Map<String, dynamic>? ?? const {};
    final attributes = attrsCache.entries.map((e) => ListingAttributeValue(e.key, '${e.value}')).toList();

    final sellerJson = json['seller'] as Map<String, dynamic>;
    final documentsJson = json['documents'] as List<dynamic>? ?? const [];

    return Listing(
      id: '${json['id']}',
      title: json['title'] as String,
      categoryId: category.id,
      productTypeId: type.id,
      description: json['description'] as String? ?? '',
      // Laravel serializa los `decimal:2` cast como STRING, no num — de ahí el
      // interpolado antes de parsear en vez de un cast directo.
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      priceType: _priceTypeFromWire(json['price_type'] as String),
      quantity: double.tryParse('${json['quantity']}') ?? 0,
      unit: json['unit'] as String,
      negotiable: json['negotiable'] as bool? ?? false,
      isLot: json['sale_mode'] == 'lot',
      location: ApproxLocation(
        municipality: locJson?['municipality'] as String? ?? '',
        state: locJson?['state'] as String? ?? '',
        distanceKm: distanceKm,
      ),
      seller: Seller(
        id: '${sellerJson['id']}',
        name: sellerJson['name'] as String,
        memberSince: sellerJson['member_since'] as int? ?? DateTime.now().year,
        completedOps: sellerJson['completed_operations'] as int? ?? 0,
        accuracy: (sellerJson['rating_accuracy'] as num?)?.toDouble() ?? 0,
        fulfillment: (sellerJson['rating_fulfillment'] as num?)?.toDouble() ?? 0,
        communication: (sellerJson['rating_communication'] as num?)?.toDouble() ?? 0,
        verified: sellerJson['is_verified'] as bool? ?? false,
      ),
      gallery: gallery,
      emojiFallback: type.emoji,
      attributes: attributes,
      documents: documentsJson
          .map((d) => ListingDocument(
                name: (d as Map<String, dynamic>)['name'] as String,
                status: _docStatusFromWire(d['status'] as String),
              ))
          .toList(),
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String _priceTypeWire(PriceType t) => switch (t) {
        PriceType.fixed => 'fixed',
        PriceType.perUnit => 'per_unit',
        PriceType.perKg => 'per_kg',
        PriceType.perAnimal => 'per_animal',
        PriceType.perLot => 'per_lot',
        PriceType.quote => 'quote',
        PriceType.negotiable => 'fixed', // no existe en el backend; no debería llegar aquí
      };

  PriceType _priceTypeFromWire(String v) => switch (v) {
        'per_unit' => PriceType.perUnit,
        'per_kg' => PriceType.perKg,
        'per_animal' => PriceType.perAnimal,
        'per_lot' => PriceType.perLot,
        'quote' => PriceType.quote,
        _ => PriceType.fixed,
      };

  DocumentStatus _docStatusFromWire(String v) => switch (v) {
        'verified' => DocumentStatus.verified,
        'rejected' => DocumentStatus.rejected,
        'expired' => DocumentStatus.expired,
        'not_applicable' => DocumentStatus.notApplicable,
        _ => DocumentStatus.pending,
      };
}

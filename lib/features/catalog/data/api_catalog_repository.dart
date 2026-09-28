import '../../../core/network/api_client.dart';
import '../domain/catalog.dart';
import 'catalog_repository.dart';

/// Implementación real: un solo GET /api/categories trae categorías, tipos de producto
/// Y sus atributos dinámicos (con opciones y reglas de requerido/rango) ya anidados —
/// el backend los manda completos de una vez (ver CatalogController::categories()) para
/// que esta clase entregue exactamente la misma forma que ya esperaba toda la UI del
/// prototipo (home, buscador, wizard de publicar) cuando corría sobre datos mock.
class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._client);

  final ApiClient _client;

  @override
  Future<Catalog> load() async {
    // Laravel envuelve las colecciones de Resource en {"data": [...]} por defecto
    // (comportamiento estándar de JsonResource/ResourceCollection) — no manda un
    // array pelón, así que hay que desenvolverlo antes de iterar.
    final response = await _client.get('/categories');
    final json = (response as Map<String, dynamic>)['data'] as List<dynamic>;

    final categories = <AgroCategory>[];
    final productTypes = <ProductType>[];

    for (final raw in json) {
      final cat = raw as Map<String, dynamic>;
      categories.add(AgroCategory(
        id: cat['slug'] as String,
        backendId: cat['id'] as int,
        name: cat['name'] as String,
        emoji: cat['icon'] as String? ?? '📦',
        tagline: '',
      ));

      for (final rawType in (cat['product_types'] as List<dynamic>? ?? [])) {
        final type = rawType as Map<String, dynamic>;
        productTypes.add(ProductType(
          id: type['slug'] as String,
          backendId: type['id'] as int,
          categoryId: cat['slug'] as String,
          name: type['name'] as String,
          emoji: type['icon'] as String? ?? '📦',
          attributes: (type['attributes'] as List<dynamic>? ?? []).map(_attributeFromJson).toList(),
          // El backend aún no expone price_types por tipo (Fase 1 lo definía por producto,
          // no lo cambiamos); se ofrecen todas y el wizard ya filtra por lo que aplica.
          priceTypes: const [
            PriceType.fixed, PriceType.perUnit, PriceType.perKg,
            PriceType.perAnimal, PriceType.perLot, PriceType.quote,
          ],
        ));
      }
    }

    return Catalog(categories: categories, productTypes: productTypes);
  }

  AttributeDef _attributeFromJson(dynamic raw) {
    final a = raw as Map<String, dynamic>;
    return AttributeDef(
      key: a['key'] as String,
      label: a['label'] as String,
      type: _dataType(a['data_type'] as String),
      unit: a['unit'] as String?,
      options: (a['options'] as List<dynamic>? ?? []).map((o) => o as String).toList(),
      required: a['required'] as bool? ?? false,
      filterable: a['filterable'] as bool? ?? false,
      group: _group(a['group'] as String? ?? 'general'),
      min: (a['min'] as num?)?.toDouble(),
      max: (a['max'] as num?)?.toDouble(),
    );
  }

  AttributeDataType _dataType(String v) => switch (v) {
        'number' => AttributeDataType.number,
        'select' => AttributeDataType.select,
        'boolean' => AttributeDataType.boolean,
        'date' => AttributeDataType.date,
        _ => AttributeDataType.text,
      };

  AttributeGroup _group(String v) => switch (v) {
        'salud' => AttributeGroup.salud,
        'reproduccion' => AttributeGroup.reproduccion,
        'produccion' => AttributeGroup.produccion,
        'comercial' => AttributeGroup.comercial,
        _ => AttributeGroup.general,
      };
}

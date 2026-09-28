/// Catálogo dinámico: categorías -> tipos de producto -> atributos.
/// En producción viene del backend (tablas categories, product_types, attributes,
/// product_type_attributes). Agregar un tipo nuevo NO requiere cambiar la app.
library;

enum AttributeDataType { text, number, select, boolean, date }

enum AttributeGroup { general, salud, reproduccion, produccion, comercial }

extension AttributeGroupLabel on AttributeGroup {
  String get label => switch (this) {
        AttributeGroup.general => 'Características',
        AttributeGroup.salud => 'Salud',
        AttributeGroup.reproduccion => 'Reproducción',
        AttributeGroup.produccion => 'Producción',
        AttributeGroup.comercial => 'Comercial',
      };
}

class AttributeDef {
  const AttributeDef({
    required this.key,
    required this.label,
    required this.type,
    this.unit,
    this.options = const [],
    this.required = false,
    this.filterable = false,
    this.group = AttributeGroup.general,
    this.min,
    this.max,
    this.hint,
  });

  final String key;
  final String label;
  final AttributeDataType type;
  final String? unit;
  final List<String> options;
  final bool required;
  final bool filterable;
  final AttributeGroup group;
  final double? min;
  final double? max;
  final String? hint;
}

enum PriceType { fixed, perUnit, perKg, perAnimal, perLot, quote, negotiable }

extension PriceTypeX on PriceType {
  String get label => switch (this) {
        PriceType.fixed => 'Precio fijo',
        PriceType.perUnit => 'Por unidad',
        PriceType.perKg => 'Por kilogramo',
        PriceType.perAnimal => 'Por animal',
        PriceType.perLot => 'Por lote',
        PriceType.quote => 'Cotización',
        PriceType.negotiable => 'Negociable',
      };

  String get suffix => switch (this) {
        PriceType.perUnit => '/unidad',
        PriceType.perKg => '/kg',
        PriceType.perAnimal => '/animal',
        PriceType.perLot => '/lote',
        _ => '',
      };
}

class AgroCategory {
  const AgroCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tagline,
    this.backendId = 0,
  });

  final String id; // slug; también funciona como colorKey
  final String name;
  final String emoji;
  final String tagline;
  // id numérico real en Postgres (Fase 4: 0 = catálogo mock, sin backend real detrás).
  final int backendId;
}

class ProductType {
  const ProductType({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.emoji,
    required this.attributes,
    required this.priceTypes,
    this.backendId = 0,
  });

  final String id; // slug
  final String categoryId;
  final String name;
  final String emoji;
  final List<AttributeDef> attributes;
  final List<PriceType> priceTypes;
  // id numérico real en Postgres: lo pide la API al crear una publicación (product_type_id).
  final int backendId;

  List<AttributeDef> get requiredAttributes =>
      attributes.where((a) => a.required).toList();

  AttributeDef? attribute(String key) {
    for (final a in attributes) {
      if (a.key == key) return a;
    }
    return null;
  }
}

class Catalog {
  const Catalog({required this.categories, required this.productTypes});

  final List<AgroCategory> categories;
  final List<ProductType> productTypes;

  AgroCategory category(String id) => categories.firstWhere((c) => c.id == id);
  ProductType type(String id) => productTypes.firstWhere((t) => t.id == id);
  List<ProductType> typesOf(String categoryId) =>
      productTypes.where((t) => t.categoryId == categoryId).toList();
}

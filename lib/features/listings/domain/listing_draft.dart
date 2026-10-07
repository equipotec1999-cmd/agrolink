import '../../catalog/domain/catalog.dart';

/// Borrador de publicación. Se guarda como `draft` en backend y solo pasa a
/// `pending_review` cuando la completitud de campos obligatorios es 100%.
class ListingDraft {
  const ListingDraft({
    this.categoryId,
    this.productTypeId,
    this.title = '',
    this.description = '',
    this.price = '',
    this.priceType,
    this.quantity = '',
    this.unit = '',
    this.negotiable = false,
    this.isLot = false,
    this.attributes = const {},
    this.photos = const [],
    this.state = 'Yucatán',
    this.municipality = '',
    this.postalCode = '',
    this.documents = 0,
    this.lat,
    this.lng,
    this.quantityInTons = false,
  });

  final String? categoryId;
  final String? productTypeId;
  final String title;
  final String description;
  final String price;
  final PriceType? priceType;
  final String quantity;
  // Unidad de venta que espera el backend (StoreListingRequest::unit, requerido,
  // p.ej. "cabeza", "kg", "lote"). El wizard antes no la pedía porque publicar
  // era puramente decorativo.
  final String unit;
  final bool negotiable;
  final bool isLot;
  final Map<String, String> attributes;
  // Rutas locales de archivo (image_picker) de las fotos elegidas, en orden.
  final List<String> photos;
  final String state;
  final String municipality;
  final String postalCode;
  final int documents;
  // Ubicación real del dispositivo (Fase 4: botón "usar mi ubicación actual").
  // Sin esto no se puede publicar — el backend exige lat/lng cuando no viene
  // de una Property ya registrada (regla del propio StoreListingRequest).
  final double? lat;
  final double? lng;
  // Al vender "por kg" el vendedor puede ingresar la cantidad en toneladas.
  // Se convierte a kg al enviar al backend (quantity × 1000). No viaja al API.
  final bool quantityInTons;

  bool get hasLocation => lat != null && lng != null;

  /// Cantidad final que se envía al backend (siempre en kg cuando el precio es por kg).
  double get quantityForApi {
    final n = double.tryParse(quantity) ?? 0;
    return quantityInTons ? n * 1000 : n;
  }

  ListingDraft copyWith({
    String? categoryId,
    String? title,
    String? description,
    String? price,
    PriceType? priceType,
    String? quantity,
    String? unit,
    bool? negotiable,
    bool? isLot,
    Map<String, String>? attributes,
    List<String>? photos,
    String? state,
    String? municipality,
    String? postalCode,
    int? documents,
    double? lat,
    double? lng,
    bool? quantityInTons,
  }) {
    return ListingDraft(
      categoryId: categoryId ?? this.categoryId,
      productTypeId: productTypeId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      negotiable: negotiable ?? this.negotiable,
      isLot: isLot ?? this.isLot,
      attributes: attributes ?? this.attributes,
      photos: photos ?? this.photos,
      state: state ?? this.state,
      municipality: municipality ?? this.municipality,
      postalCode: postalCode ?? this.postalCode,
      documents: documents ?? this.documents,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      quantityInTons: quantityInTons ?? this.quantityInTons,
    );
  }

  /// Cambiar de tipo reinicia los atributos (cada tipo tiene su propia ficha).
  ListingDraft withType(ProductType t) => ListingDraft(
        categoryId: t.categoryId,
        productTypeId: t.id,
        title: title,
        description: description,
        price: price,
        priceType: t.priceTypes.first,
        quantity: quantity,
        unit: unit,
        negotiable: negotiable,
        isLot: isLot,
        photos: photos,
        state: state,
        municipality: municipality,
        postalCode: postalCode,
        documents: documents,
        lat: lat,
        lng: lng,
        quantityInTons: quantityInTons,
      );
}

class CompletenessSection {
  const CompletenessSection(this.label, this.done, this.total, {this.optional = false});
  final String label;
  final int done;
  final int total;
  final bool optional;

  bool get complete => done >= total;
}

class Completeness {
  const Completeness(this.sections);
  final List<CompletenessSection> sections;

  List<CompletenessSection> get _required => sections.where((s) => !s.optional).toList();

  double get ratio {
    final total = _required.fold<int>(0, (a, s) => a + s.total);
    final done = _required.fold<int>(0, (a, s) => a + (s.done > s.total ? s.total : s.done));
    return total == 0 ? 0 : done / total;
  }

  bool get canPublish => _required.every((s) => s.complete);
}

/// La misma regla vive en el backend (fuente de verdad); aquí solo guía al usuario.
Completeness evaluateDraft(ListingDraft d, ProductType? type) {
  final basics = [
    d.productTypeId != null,
    d.title.trim().length >= 8,
    double.tryParse(d.price) != null || d.priceType == PriceType.quote,
    d.priceType != null,
    double.tryParse(d.quantity) != null,
    d.unit.trim().isNotEmpty,
  ];
  final requiredAttrs = type?.requiredAttributes ?? const <AttributeDef>[];
  final filled = requiredAttrs.where((a) => (d.attributes[a.key] ?? '').trim().isNotEmpty).length;
  final attrsDone = type == null ? 0 : (requiredAttrs.isEmpty ? 1 : filled);

  return Completeness([
    CompletenessSection('Información básica', basics.where((b) => b).length, basics.length),
    CompletenessSection('Características', attrsDone, requiredAttrs.isEmpty ? 1 : requiredAttrs.length),
    CompletenessSection('Fotografías', d.photos.isEmpty ? 0 : 1, 1),
    CompletenessSection('Ubicación', (d.municipality.trim().isEmpty || !d.hasLocation) ? 0 : 1, 1),
    CompletenessSection('Documentación', d.documents > 0 ? 1 : 0, 1, optional: true),
  ]);
}

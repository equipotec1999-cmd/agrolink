import '../../catalog/domain/catalog.dart';

/// Nivel de confianza de cada dato. Nunca se asume que un documento subido es válido.
enum VerificationLevel { declared, documented, professional }

enum DocumentStatus { pending, verified, rejected, expired, notApplicable }

enum ListingStatus { draft, pendingReview, published, rejected, suspended, sold, expired, archived }

extension ListingStatusX on ListingStatus {
  String get label => switch (this) {
        ListingStatus.draft => 'Borrador',
        ListingStatus.pendingReview => 'En revisión',
        ListingStatus.published => 'Publicado',
        ListingStatus.rejected => 'Rechazado',
        ListingStatus.suspended => 'Suspendido',
        ListingStatus.sold => 'Vendido',
        ListingStatus.expired => 'Vencido',
        ListingStatus.archived => 'Archivado',
      };
}

class ListingAttributeValue {
  const ListingAttributeValue(this.key, this.value, [this.verification = VerificationLevel.declared]);
  final String key;
  final String value;
  final VerificationLevel verification;
}

class ListingDocument {
  const ListingDocument({required this.name, required this.status, this.note});
  final String name;
  final DocumentStatus status;
  final String? note;
}

/// Ubicación pública: solo municipio y distancia aproximada.
/// Coordenadas exactas se quedan en el backend (listing_locations).
class ApproxLocation {
  const ApproxLocation({required this.municipality, required this.state, required this.distanceKm});
  final String municipality;
  final String state;

  /// -1 = distancia desconocida (aún no hay permiso/posición del dispositivo).
  /// La API real no calcula esto en el servidor; se estima en el cliente con
  /// las coordenadas aproximadas del listing y la posición del teléfono.
  final double distanceKm;

  bool get hasKnownDistance => distanceKm >= 0;

  String get short => '$municipality, $state';
}

class Seller {
  const Seller({
    required this.id,
    required this.name,
    required this.memberSince,
    required this.completedOps,
    required this.accuracy,
    required this.fulfillment,
    required this.communication,
    this.cancellations,
    this.responseTime,
    this.verified = false,
  });

  final String id;
  final String name;
  final int memberSince;
  final int completedOps;
  // La API real todavía no lleva estas dos métricas (no hay columna ni cálculo
  // para ellas en el backend); null = "sin datos todavía", no se inventa un 0.
  final int? cancellations;
  final String? responseTime;
  final double accuracy; // 0..5
  final double fulfillment;
  final double communication;
  final bool verified;

  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.productTypeId,
    required this.description,
    required this.price,
    required this.priceType,
    required this.quantity,
    required this.unit,
    required this.location,
    required this.seller,
    required this.gallery,
    required this.attributes,
    required this.publishedAt,
    this.documents = const [],
    this.negotiable = false,
    this.isLot = false,
    this.wholesale = false,
    this.featured = false,
    this.status = ListingStatus.published,
    this.emojiFallback,
  });

  final String id;
  final String title;
  final String categoryId;
  final String productTypeId;
  final String description;
  final double price;
  final PriceType priceType;
  final double quantity;
  final String unit;
  final ApproxLocation location;
  final Seller seller;

  /// ⚠️ MOCK: en el prototipo las "fotos" son emojis sobre arte generado.
  /// En producción son URLs firmadas de almacenamiento externo (S3/R2).
  final List<String> gallery;
  final List<ListingAttributeValue> attributes;
  final List<ListingDocument> documents;
  final DateTime publishedAt;
  final bool negotiable;
  final bool isLot;
  final bool wholesale;
  final bool featured; // preparado para "publicaciones destacadas" (monetización)
  final ListingStatus status;

  /// Emoji del tipo de producto, para usar como arte de respaldo cuando `gallery`
  /// trae URLs reales (API) en vez de emojis (mock). Si no se da, se asume que
  /// `gallery` YA son emojis (⚠️ MOCK) y se usa el primero tal cual.
  final String? emojiFallback;

  String get cover => gallery.isEmpty ? '' : gallery.first;

  /// Emoji a mostrar mientras carga/si falla la foto real.
  String get placeholderEmoji => emojiFallback ?? (gallery.isEmpty ? '📦' : gallery.first);

  /// true si `cover`/`gallery` son URLs reales de foto, no emojis del prototipo.
  bool get hasRealPhotos => cover.startsWith('http');

  String? valueOf(String key) {
    for (final a in attributes) {
      if (a.key == key) return a.value;
    }
    return null;
  }

  bool get hasVerifiedInfo =>
      attributes.any((a) => a.verification != VerificationLevel.declared) ||
      documents.any((d) => d.status == DocumentStatus.verified);
}

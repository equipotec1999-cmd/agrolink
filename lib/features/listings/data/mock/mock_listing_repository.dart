// ⚠️ MOCK — Publicaciones de ejemplo (zona oriente/norte de Yucatán).
// Simula latencia de red para que los estados de carga sean reales.

import '../../../../core/utils/formatters.dart';
import '../../../catalog/domain/catalog.dart';
import '../../../search/domain/query_parser.dart';
import '../../../search/domain/search_filters.dart';
import '../../domain/listing.dart';
import '../../domain/listing_draft.dart';
import '../listing_repository.dart';

class MockListingRepository implements ListingRepository {
  MockListingRepository(this.catalog);

  final Catalog catalog;

  static const _latency = Duration(milliseconds: 450);

  @override
  Future<List<Listing>> feed() async {
    await Future<void>.delayed(_latency);
    return mockListings;
  }

  @override
  Future<Listing?> byId(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    for (final l in mockListings) {
      if (l.id == id) return l;
    }
    return null;
  }

  @override
  Future<List<Listing>> byIds(Set<String> ids) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return mockListings.where((l) => ids.contains(l.id)).toList();
  }

  // El mock no tiene sesión ni servidor: no hay favoritos persistidos.
  @override
  Future<List<Listing>> favorites() async => [];

  @override
  Future<List<Listing>> search(SearchFilters f) async {
    await Future<void>.delayed(_latency);
    final parsed = parseQuery(f.query);

    final results = mockListings.where((l) {
      if (f.categoryId != null && l.categoryId != f.categoryId) return false;
      if (f.productTypeId != null && l.productTypeId != f.productTypeId) return false;
      if (f.maxDistanceKm != null && l.location.distanceKm > f.maxDistanceKm!) return false;
      if (f.verifiedOnly && !l.hasVerifiedInfo) return false;
      if (f.negotiableOnly && !l.negotiable) return false;
      if (f.lotsOnly && !l.isLot) return false;
      if (parsed.wholesale && !l.wholesale) return false;

      for (final entry in f.attributeValues.entries) {
        if (entry.value.isEmpty) continue;
        final v = l.valueOf(entry.key);
        if (v == null || !entry.value.contains(v)) return false;
      }

      for (final entry in parsed.ranges.entries) {
        final v = l.valueOf(entry.key);
        if (v == null) continue; // el rango no aplica a este tipo de producto
        final n = double.tryParse(v);
        if (n == null || !entry.value.contains(n)) return false;
      }

      if (parsed.terms.isNotEmpty) {
        final haystack = _searchableText(l);
        if (!parsed.terms.every((t) => termMatches(haystack, t))) return false;
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
    await Future<void>.delayed(_latency);
    final listing = Listing(
      id: 'mock-${DateTime.now().microsecondsSinceEpoch}',
      title: draft.title,
      categoryId: type.categoryId,
      productTypeId: type.id,
      description: draft.description,
      price: double.tryParse(draft.price) ?? 0,
      priceType: draft.priceType ?? type.priceTypes.first,
      quantity: double.tryParse(draft.quantity) ?? 0,
      unit: 'unidad',
      negotiable: draft.negotiable,
      isLot: draft.isLot,
      location: ApproxLocation(municipality: draft.municipality, state: draft.state, distanceKm: 0),
      // ⚠️ MOCK: este repositorio no tiene sesión real, así que no hay forma de
      // saber quién publicó; se usa un vendedor de muestra.
      seller: _donBeto,
      gallery: draft.photos.isEmpty ? const ['📦'] : draft.photos,
      attributes: draft.attributes.entries.map((e) => ListingAttributeValue(e.key, e.value)).toList(),
      publishedAt: DateTime.now(),
    );
    mockListings.add(listing);
    return listing;
  }

  String _searchableText(Listing l) {
    final type = catalog.type(l.productTypeId);
    final category = catalog.category(l.categoryId);
    return normalize([
      l.title,
      l.description,
      type.name,
      category.name,
      l.location.municipality,
      ...l.attributes.map((a) => a.value),
      // sinónimos regionales (en backend: tabla search_synonyms)
      if (l.productTypeId == 'ovinos') 'borrego borregos carnero',
      if (l.productTypeId == 'equinos') 'caballo yegua potro',
      if (l.productTypeId == 'bovinos') 'ganado res toro vaca novillo becerro',
    ].join(' '));
  }
}

final _now = DateTime.now();

const _donBeto = Seller(
  id: 's1',
  name: 'Rancho San Alberto',
  memberSince: 2023,
  completedOps: 48,
  cancellations: 1,
  responseTime: '~1 h',
  accuracy: 4.9,
  fulfillment: 4.8,
  communication: 4.7,
  verified: true,
);

const _apiarios = Seller(
  id: 's2',
  name: 'Apiarios Kaab',
  memberSince: 2022,
  completedOps: 132,
  cancellations: 2,
  responseTime: '~30 min',
  accuracy: 4.9,
  fulfillment: 5.0,
  communication: 4.8,
  verified: true,
);

const _huerta = Seller(
  id: 's3',
  name: 'Huerta Los Aluxes',
  memberSince: 2024,
  completedOps: 21,
  cancellations: 0,
  responseTime: '~2 h',
  accuracy: 4.7,
  fulfillment: 4.6,
  communication: 4.9,
);

const _marisol = Seller(
  id: 's4',
  name: 'Marisol Chan',
  memberSince: 2025,
  completedOps: 6,
  cancellations: 0,
  responseTime: '~3 h',
  accuracy: 4.8,
  fulfillment: 4.9,
  communication: 4.6,
);

final mockListings = <Listing>[
  Listing(
    id: 'l1',
    title: 'Caballo Cuarto de Milla "Relámpago"',
    categoryId: 'animales',
    productTypeId: 'equinos',
    description:
        'Caballo alazán muy noble, trabajado en rienda y campo. Se entrega con registro y carnet de vacunación. Ideal para jinete intermedio.',
    price: 85000,
    priceType: PriceType.perAnimal,
    quantity: 1,
    unit: 'animal',
    negotiable: true,
    featured: true,
    location: const ApproxLocation(municipality: 'Tizimín', state: 'Yucatán', distanceKm: 6),
    seller: _donBeto,
    gallery: const ['🐎', '🏇', '🐴'],
    publishedAt: _now.subtract(const Duration(hours: 5)),
    attributes: const [
      ListingAttributeValue('raza_equino', 'Cuarto de Milla', VerificationLevel.documented),
      ListingAttributeValue('sexo_equino', 'Macho castrado'),
      ListingAttributeValue('edad_anios', '6', VerificationLevel.documented),
      ListingAttributeValue('peso', '480'),
      ListingAttributeValue('altura', '1.52'),
      ListingAttributeValue('color', 'Alazán'),
      ListingAttributeValue('disciplina', 'Rienda'),
      ListingAttributeValue('entrenamiento', 'Intermedio'),
      ListingAttributeValue('temperamento', 'Dócil'),
      ListingAttributeValue('vacunacion', 'Al corriente', VerificationLevel.professional),
      ListingAttributeValue('estado_sanitario', 'Sano', VerificationLevel.professional),
      ListingAttributeValue('enfermedades', 'Ninguna conocida'),
    ],
    documents: const [
      ListingDocument(name: 'Registro de asociación de raza', status: DocumentStatus.verified),
      ListingDocument(name: 'Constancia de vacunación', status: DocumentStatus.verified),
      ListingDocument(
        name: 'Documento de movilización',
        status: DocumentStatus.pending,
        note: 'Requisito según regla vigente de SENASICA para el trayecto',
      ),
    ],
  ),
  Listing(
    id: 'l2',
    title: 'Lote de 12 novillos Brahman x Suizo',
    categoryId: 'animales',
    productTypeId: 'bovinos',
    description:
        'Novillos parejos para finalizar, en pastoreo con suplemento. Se pueden ver en el rancho entre semana.',
    price: 48,
    priceType: PriceType.perKg,
    quantity: 12,
    unit: 'cabezas',
    isLot: true,
    negotiable: true,
    featured: true,
    location: const ApproxLocation(municipality: 'Panabá', state: 'Yucatán', distanceKm: 34),
    seller: _donBeto,
    gallery: const ['🐂', '🐄', '🌾'],
    publishedAt: _now.subtract(const Duration(days: 1)),
    attributes: const [
      ListingAttributeValue('raza_bovino', 'Brahman x Suizo'),
      ListingAttributeValue('sexo', 'Macho'),
      ListingAttributeValue('edad_meses', '18'),
      ListingAttributeValue('peso', '380'),
      ListingAttributeValue('proposito_bovino', 'Engorda'),
      ListingAttributeValue('condicion_corporal', '3'),
      ListingAttributeValue('arete', 'Aretados (12/12)', VerificationLevel.documented),
      ListingAttributeValue('vacunacion', 'Al corriente', VerificationLevel.documented),
      ListingAttributeValue('estado_sanitario', 'Sano'),
    ],
    documents: const [
      ListingDocument(name: 'Relación de aretes', status: DocumentStatus.verified),
      ListingDocument(name: 'Constancia de vacunación', status: DocumentStatus.pending),
    ],
  ),
  Listing(
    id: 'l3',
    title: 'Borregos Pelibuey de engorda',
    categoryId: 'animales',
    productTypeId: 'ovinos',
    description: 'Borregos de 4 a 5 meses, desparasitados, comiendo bien. Hay 20 disponibles.',
    price: 2800,
    priceType: PriceType.perAnimal,
    quantity: 20,
    unit: 'animales',
    isLot: true,
    negotiable: true,
    location: const ApproxLocation(municipality: 'Buctzotz', state: 'Yucatán', distanceKm: 58),
    seller: _marisol,
    gallery: const ['🐑', '🐏'],
    publishedAt: _now.subtract(const Duration(hours: 20)),
    attributes: const [
      ListingAttributeValue('raza_ovino', 'Pelibuey'),
      ListingAttributeValue('sexo', 'Macho'),
      ListingAttributeValue('edad_meses', '5'),
      ListingAttributeValue('peso', '38'),
      ListingAttributeValue('proposito_ovino', 'Engorda'),
      ListingAttributeValue('vacunacion', 'Parcial'),
      ListingAttributeValue('estado_sanitario', 'Sano'),
    ],
  ),
  Listing(
    id: 'l4',
    title: 'Miel multifloral de tajonal — mayoreo',
    categoryId: 'apicultura',
    productTypeId: 'miel',
    description:
        'Miel clara de la cosecha de primavera, extraída por centrífuga. Venta en tambo o cubeta. Envío a coordinar.',
    price: 78,
    priceType: PriceType.perKg,
    quantity: 3000,
    unit: 'kg',
    wholesale: true,
    featured: true,
    location: const ApproxLocation(municipality: 'Sucilá', state: 'Yucatán', distanceKm: 22),
    seller: _apiarios,
    gallery: const ['🍯', '🐝', '🌼'],
    publishedAt: _now.subtract(const Duration(hours: 2)),
    attributes: const [
      ListingAttributeValue('tipo_miel', 'Multifloral'),
      ListingAttributeValue('origen_floral', 'Tajonal y tzitzilché'),
      ListingAttributeValue('fecha_cosecha', 'Abr 2026'),
      ListingAttributeValue('lote', 'AK-2604', VerificationLevel.documented),
      ListingAttributeValue('extraccion', 'Centrífuga'),
      ListingAttributeValue('presentacion_miel', 'Granel (tambo)'),
      ListingAttributeValue('disponible_kg', '3000'),
      ListingAttributeValue('pedido_minimo', '200'),
    ],
    documents: const [
      ListingDocument(name: 'Análisis de laboratorio del lote', status: DocumentStatus.verified),
      ListingDocument(name: 'Certificado orgánico', status: DocumentStatus.notApplicable),
    ],
  ),
  Listing(
    id: 'l5',
    title: 'Núcleos de 5 bastidores con reina',
    categoryId: 'apicultura',
    productTypeId: 'nucleos',
    description: 'Núcleos fuertes, reina joven fecundada, listos para pasar a cámara de cría.',
    price: 1900,
    priceType: PriceType.perUnit,
    quantity: 15,
    unit: 'núcleos',
    location: const ApproxLocation(municipality: 'Espita', state: 'Yucatán', distanceKm: 41),
    seller: _apiarios,
    gallery: const ['🐝', '🏠'],
    publishedAt: _now.subtract(const Duration(days: 2)),
    attributes: const [
      ListingAttributeValue('bastidores', '5'),
      ListingAttributeValue('bastidores_cria', '3'),
      ListingAttributeValue('reina_fecundada', 'Sí'),
      ListingAttributeValue('genetica', 'Italiana'),
    ],
  ),
  Listing(
    id: 'l6',
    title: 'Chile habanero fresco de primera',
    categoryId: 'agricultura',
    productTypeId: 'chiles',
    description: 'Habanero naranja, corte de esta semana. Disponible por caja o por tonelada.',
    price: 32,
    priceType: PriceType.perKg,
    quantity: 1200,
    unit: 'kg',
    negotiable: true,
    wholesale: true,
    featured: true,
    location: const ApproxLocation(municipality: 'Dzilam de Bravo', state: 'Yucatán', distanceKm: 96),
    seller: _huerta,
    gallery: const ['🌶️', '🧺'],
    publishedAt: _now.subtract(const Duration(hours: 9)),
    attributes: const [
      ListingAttributeValue('variedad', 'Habanero naranja'),
      ListingAttributeValue('metodo_cultivo', 'Convencional'),
      ListingAttributeValue('sistema', 'Malla sombra'),
      ListingAttributeValue('fecha_cosecha', 'Esta semana'),
      ListingAttributeValue('calidad', 'Primera'),
      ListingAttributeValue('madurez', 'Maduro'),
      ListingAttributeValue('presentacion_cosecha', 'Caja'),
      ListingAttributeValue('disponible_kg', '1200'),
      ListingAttributeValue('pedido_minimo', '50'),
    ],
  ),
  Listing(
    id: 'l7',
    title: 'Plantas de limón persa injertadas',
    categoryId: 'agricultura',
    productTypeId: 'plantas',
    description: 'Plantas de vivero en bolsa, injertadas, de 60 a 80 cm. Descuento por volumen.',
    price: 65,
    priceType: PriceType.perUnit,
    quantity: 800,
    unit: 'plantas',
    wholesale: true,
    location: const ApproxLocation(municipality: 'Oxkutzcab', state: 'Yucatán', distanceKm: 212),
    seller: _huerta,
    gallery: const ['🌱', '🍋'],
    publishedAt: _now.subtract(const Duration(days: 3)),
    attributes: const [
      ListingAttributeValue('especie', 'Limón'),
      ListingAttributeValue('variedad', 'Persa'),
      ListingAttributeValue('altura_cm', '70'),
      ListingAttributeValue('contenedor', 'Bolsa'),
      ListingAttributeValue('injertada', 'Sí'),
    ],
  ),
  Listing(
    id: 'l8',
    title: 'Cabras Saanen lecheras',
    categoryId: 'animales',
    productTypeId: 'caprinos',
    description: 'Cabras en producción, mansas, acostumbradas a ordeña manual.',
    price: 4500,
    priceType: PriceType.perAnimal,
    quantity: 4,
    unit: 'animales',
    location: const ApproxLocation(municipality: 'Valladolid', state: 'Yucatán', distanceKm: 71),
    seller: _marisol,
    gallery: const ['🐐', '🥛'],
    publishedAt: _now.subtract(const Duration(days: 4)),
    attributes: const [
      ListingAttributeValue('raza_caprino', 'Saanen'),
      ListingAttributeValue('sexo', 'Hembra'),
      ListingAttributeValue('edad_meses', '30'),
      ListingAttributeValue('peso', '55'),
      ListingAttributeValue('proposito_caprino', 'Leche'),
      ListingAttributeValue('leche_litros', '2.5'),
      ListingAttributeValue('estado_reproductivo', 'Lactando'),
      ListingAttributeValue('vacunacion', 'Al corriente'),
      ListingAttributeValue('estado_sanitario', 'Sano'),
    ],
  ),
  Listing(
    id: 'l9',
    title: 'Papaya maradol por tonelada',
    categoryId: 'agricultura',
    productTypeId: 'frutas',
    description: 'Papaya en punto de corte para mercado nacional. Pedido mínimo 1 tonelada.',
    price: 12,
    priceType: PriceType.perKg,
    quantity: 8000,
    unit: 'kg',
    wholesale: true,
    location: const ApproxLocation(municipality: 'Hunucmá', state: 'Yucatán', distanceKm: 188),
    seller: _huerta,
    gallery: const ['🥭', '🚜'],
    publishedAt: _now.subtract(const Duration(hours: 30)),
    attributes: const [
      ListingAttributeValue('variedad', 'Maradol'),
      ListingAttributeValue('metodo_cultivo', 'Convencional'),
      ListingAttributeValue('sistema', 'Campo abierto'),
      ListingAttributeValue('fecha_cosecha', 'Continua'),
      ListingAttributeValue('calidad', 'Primera'),
      ListingAttributeValue('madurez', 'Pintón'),
      ListingAttributeValue('presentacion_cosecha', 'Tonelada'),
      ListingAttributeValue('disponible_kg', '8000'),
      ListingAttributeValue('pedido_minimo', '1000'),
    ],
  ),
  Listing(
    id: 'l10',
    title: 'Abejas reina italianas fecundadas',
    categoryId: 'apicultura',
    productTypeId: 'reinas',
    description: 'Reinas marcadas, envío en jaulita con acompañantes.',
    price: 450,
    priceType: PriceType.perUnit,
    quantity: 40,
    unit: 'reinas',
    location: const ApproxLocation(municipality: 'Tizimín', state: 'Yucatán', distanceKm: 9),
    seller: _apiarios,
    gallery: const ['👑', '🐝'],
    publishedAt: _now.subtract(const Duration(hours: 14)),
    attributes: const [
      ListingAttributeValue('genetica', 'Italiana'),
      ListingAttributeValue('fecundada', 'Sí'),
      ListingAttributeValue('marcada', 'Sí'),
    ],
  ),
];

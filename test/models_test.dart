import 'package:agrolink/features/chat/domain/chat.dart';
import 'package:agrolink/features/my_listings/data/my_listings_repository.dart';
import 'package:agrolink/features/operations/domain/operation.dart';
import 'package:agrolink/features/search/domain/search_filters.dart';
import 'package:agrolink/shared/widgets/category_glyphs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchFilters JSON (búsquedas guardadas)', () {
    test('ida y vuelta conserva todos los filtros', () {
      const original = SearchFilters(
        query: 'borregos de engorda',
        categoryId: 'animales',
        productTypeId: 'ovinos',
        maxDistanceKm: 80,
        verifiedOnly: true,
        negotiableOnly: true,
        lotsOnly: false,
        attributeValues: {
          'raza': {'Pelibuey', 'Dorper'},
        },
        sort: SortOption.priceAsc,
      );

      final copy = SearchFilters.fromJson(original.toJson());

      expect(copy.query, original.query);
      expect(copy.categoryId, 'animales');
      expect(copy.productTypeId, 'ovinos');
      expect(copy.maxDistanceKm, 80);
      expect(copy.verifiedOnly, isTrue);
      expect(copy.negotiableOnly, isTrue);
      expect(copy.lotsOnly, isFalse);
      expect(copy.attributeValues['raza'], {'Pelibuey', 'Dorper'});
      expect(copy.sort, SortOption.priceAsc);
    });

    test('un JSON vacío o con datos raros no truena', () {
      final f = SearchFilters.fromJson(const {'sort': 'inventado', 'max_distance_km': 'x'});
      expect(f.query, '');
      expect(f.sort, SortOption.nearest);
      expect(f.maxDistanceKm, isNull);
    });

    test('toJson omite atributos vacíos', () {
      const f = SearchFilters(attributeValues: {'raza': <String>{}});
      expect((f.toJson()['attributes'] as Map), isEmpty);
    });
  });

  group('Ofertas', () {
    test('el total es precio por unidad x cantidad', () {
      const o = Offer(id: '1', amount: 1400, quantity: 2, status: OfferStatus.sent);
      expect(o.total, 2800);
    });

    test('estados del backend y solo "enviada" está abierta', () {
      expect(OfferStatusX.fromWire('aceptada'), OfferStatus.accepted);
      expect(OfferStatusX.fromWire('contraoferta'), OfferStatus.countered);
      expect(OfferStatusX.fromWire('desconocido'), OfferStatus.sent);
      expect(OfferStatus.sent.isOpen, isTrue);
      expect(OfferStatus.accepted.isOpen, isFalse);
    });
  });

  group('Operaciones', () {
    test('traduce los estados en español del backend', () {
      expect(OperationStatus.fromWire('pagado'), OperationStatus.paid);
      expect(OperationStatus.fromWire('en_transito'), OperationStatus.inTransit);
      expect(OperationStatus.fromWire('oferta_aceptada'), OperationStatus.offerAccepted);
    });
  });

  group('MyListing', () {
    Map<String, dynamic> json(String status, {String? note}) => {
          'id': 7,
          'title': 'Miel',
          'description': null,
          'price': '120.00', // Laravel manda decimales como texto
          'quantity': '50.00',
          'unit': 'kg',
          'negotiable': true,
          'status': status,
          'moderation_note': note,
          'media': [
            {'url': 'https://x/y.jpg'},
          ],
        };

    test('lee números en texto y la foto de portada', () {
      final l = MyListing.fromJson(json('publicada'));
      expect(l.id, '7');
      expect(l.price, 120.0);
      expect(l.quantity, 50.0);
      expect(l.description, '');
      expect(l.coverUrl, 'https://x/y.jpg');
    });

    test('qué acciones corresponden a cada estado', () {
      expect(MyListing.fromJson(json('rechazada')).canResubmit, isTrue);
      expect(MyListing.fromJson(json('suspended')).canResubmit, isTrue);
      expect(MyListing.fromJson(json('publicada')).canResubmit, isFalse);
      expect(MyListing.fromJson(json('borrador')).canPublish, isTrue);
      expect(MyListing.fromJson(json('archivada')).canArchive, isFalse);
      expect(MyListing.fromJson(json('publicada')).canArchive, isTrue);
    });

    test('el motivo vacío se trata como ausente y el estado tiene etiqueta', () {
      expect(MyListing.fromJson(json('rechazada', note: '   ')).moderationNote, isNull);
      expect(MyListing.fromJson(json('rechazada', note: ' Fotos falsas ')).moderationNote, 'Fotos falsas');
      expect(MyListing.fromJson(json('en_revision')).statusLabel, 'En revisión');
    });
  });

  group('Símbolos', () {
    test('los emoji de avisos se cambian por su símbolo y el resto se queda', () {
      expect(glyphKeyForEmoji('⚠️'), 'warning');
      expect(glyphKeyForEmoji('✅'), 'done');
      expect(glyphKeyForEmoji('📍'), '📍');
    });

    test('todas las claves del catálogo tienen símbolo', () {
      for (final k in ['cow', 'horse', 'sheep', 'goat', 'pig', 'hive', 'bee', 'crown', 'honey', 'chili', 'fruit', 'leaf', 'sprout']) {
        expect(isGlyphKey(k), isTrue, reason: k);
      }
    });
  });
}

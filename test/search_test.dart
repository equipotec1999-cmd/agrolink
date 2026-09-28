import 'package:agrolink/core/utils/formatters.dart';
import 'package:agrolink/features/catalog/data/mock/mock_catalog.dart';
import 'package:agrolink/features/listings/data/mock/mock_listing_repository.dart';
import 'package:agrolink/features/search/domain/query_parser.dart';
import 'package:agrolink/features/search/domain/search_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMoney', () {
    test('agrega separadores de miles', () {
      expect(formatMoney(85000), '\$85,000');
      expect(formatMoney(1200), '\$1,200');
      expect(formatMoney(48), '\$48');
    });
  });

  group('parseQuery', () {
    test('entiende rango de peso', () {
      final q = parseQuery('borregos de engorda de 35 a 50 kg');
      expect(q.ranges['peso']?.min, 35);
      expect(q.ranges['peso']?.max, 50);
      expect(q.terms, containsAll(['borregos', 'engorda']));
    });

    test('entiende edad máxima en años', () {
      final q = parseQuery('caballos cuarto de milla menores de 8 años');
      expect(q.ranges['edad_anios']?.max, 8);
    });

    test('entiende mayoreo', () {
      expect(parseQuery('miel multifloral por mayoreo').wholesale, isTrue);
    });
  });

  group('MockListingRepository.search', () {
    late final MockListingRepository repo;

    setUpAll(() async {
      repo = MockListingRepository(await MockCatalogRepository().load());
    });

    test('borregos de 35 a 50 kg -> Pelibuey', () async {
      final r = await repo.search(const SearchFilters(query: 'borregos de engorda de 35 a 50 kg'));
      expect(r.map((l) => l.id), ['l3']);
    });

    test('chile habanero más de 500 kg', () async {
      final r = await repo.search(const SearchFilters(query: 'chile habanero más de 500 kg'));
      expect(r.map((l) => l.id), ['l6']);
    });

    test('caballos menores de 8 años', () async {
      final r = await repo.search(const SearchFilters(query: 'caballos cuarto de milla menores de 8 años'));
      expect(r.map((l) => l.id), ['l1']);
    });
  });
}

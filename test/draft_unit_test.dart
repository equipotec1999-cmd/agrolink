import 'package:flutter_test/flutter_test.dart';
import 'package:agrolink/features/catalog/domain/catalog.dart';
import 'package:agrolink/features/listings/domain/listing_draft.dart';

void main() {
  test('la unidad se deduce del tipo de precio si el vendedor no la escribió', () {
    expect(const ListingDraft(priceType: PriceType.perAnimal).effectiveUnit, 'animal');
    expect(const ListingDraft(priceType: PriceType.perKg).effectiveUnit, 'kg');
    expect(const ListingDraft(priceType: PriceType.perLot).effectiveUnit, 'lote');
    expect(const ListingDraft(priceType: PriceType.perUnit).effectiveUnit, '');
    expect(const ListingDraft(priceType: PriceType.perUnit, unit: 'caja').effectiveUnit, 'caja');
  });
}

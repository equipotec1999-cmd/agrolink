import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/catalog.dart';
import '../domain/listing_draft.dart';

/// Estado del asistente de publicación. El borrador sobrevive si el usuario
/// cierra la pantalla (en Fase 4 se autoguarda como `draft` en el backend).
class ListingDraftController extends Notifier<ListingDraft> {
  @override
  ListingDraft build() => const ListingDraft();

  void selectCategory(String id) => state = ListingDraft(
        categoryId: id,
        title: state.title,
        description: state.description,
        photos: state.photos,
        municipality: state.municipality,
        postalCode: state.postalCode,
      );

  void selectType(ProductType t) => state = state.withType(t);

  void edit(ListingDraft Function(ListingDraft d) fn) => state = fn(state);

  void setAttribute(String key, String value) =>
      state = state.copyWith(attributes: {...state.attributes, key: value});

  void addPhoto(String art) => state = state.copyWith(photos: [...state.photos, art]);

  void removePhoto(int index) =>
      state = state.copyWith(photos: [...state.photos]..removeAt(index));

  void reset() => state = const ListingDraft();
}

final listingDraftProvider = NotifierProvider<ListingDraftController, ListingDraft>(
  ListingDraftController.new,
);

final draftCompletenessProvider = Provider<Completeness>((ref) {
  final draft = ref.watch(listingDraftProvider);
  final catalog = ref.watch(catalogProvider);
  final type = draft.productTypeId == null ? null : catalog.type(draft.productTypeId!);
  return evaluateDraft(draft, type);
});

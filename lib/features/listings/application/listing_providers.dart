import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/listing_repository.dart';
import '../domain/listing.dart';

final feedProvider = FutureProvider<List<Listing>>(
  (ref) => ref.watch(listingRepositoryProvider).feed(),
);

final listingByIdProvider = FutureProvider.family<Listing?, String>(
  (ref, id) => ref.watch(listingRepositoryProvider).byId(id),
);

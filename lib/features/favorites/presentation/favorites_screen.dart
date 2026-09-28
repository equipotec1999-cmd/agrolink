import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../listings/presentation/widgets/listing_widgets.dart';
import '../application/favorites_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoriteListingsProvider);
    final catalog = ref.watch(catalogProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
              child: Row(
                children: [
                  CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                  const SizedBox(width: 14),
                  const Text('Favoritos', style: AppText.h1),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: favs.when(
                skipLoadingOnReload: true,
                loading: () => ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [
                    Skeleton(height: 124, radius: 16),
                    SizedBox(height: 12),
                    Skeleton(height: 124, radius: 16),
                  ],
                ),
                error: (e, _) => const EmptyState(icon: Icons.wifi_off_rounded, title: 'Error', message: 'Intenta de nuevo.'),
                data: (list) => list.isEmpty
                    ? EmptyState(
                        icon: Icons.favorite_border_rounded,
                        title: 'Aún no guardas nada',
                        message: 'Toca el corazón en cualquier publicación para tenerla a la mano.',
                        action: AgroButton(label: 'Explorar', expand: false, onTap: () => context.go('/home')),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                        itemCount: list.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => FadeSlideIn(
                          key: ValueKey('fav-${list[i].id}'),
                          delay: Duration(milliseconds: 50 * i),
                          child: ListingTile(
                            listing: list[i],
                            heroPrefix: 'fav',
                            typeName: catalog.type(list[i].productTypeId).name,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

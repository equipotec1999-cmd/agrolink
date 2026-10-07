import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/agrolink_logo.dart';
import '../../../shared/widgets/category_glyphs.dart';
import '../../../shared/widgets/motion.dart';
import '../../notifications/application/notifications_controller.dart';
import '../../../shared/widgets/product_art.dart';
import '../../auth/application/auth_controller.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/catalog.dart';
import '../../listings/application/listing_providers.dart';
import '../../listings/domain/listing.dart';
import '../../listings/presentation/widgets/listing_widgets.dart';
import '../../search/application/search_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _radius = 100;

  void _openCategory(String id) {
    ref.read(searchFiltersProvider.notifier).setCategory(id);
    context.go('/search');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final catalog = ref.watch(catalogProvider);
    final feed = ref.watch(feedProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.forest,
        onRefresh: () => ref.refresh(feedProvider.future),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _Header(name: user?.firstName ?? 'Productor'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: const FadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Del campo,\ndirecto a ti.', style: AppText.hero),
                      SizedBox(height: 10),
                      RusticDivider(width: 110),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _SearchLauncher(onTap: () => context.go('/search')),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 196,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: catalog.categories.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final c = catalog.categories[i];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 120 + i * 70),
                      child: _CategoryCard(
                        category: c,
                        typeCount: catalog.typesOf(c.id).length,
                        onTap: () => _openCategory(c.id),
                      ),
                    );
                  },
                ),
              ),
            ),
            ...feed.when<List<Widget>>(
              loading: () => [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: Skeleton(height: 230, radius: 20),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.64,
                    children: List.generate(4, (_) => const Skeleton(radius: 18)),
                  ),
                ),
              ],
              error: (e, _) => [
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Sin conexión',
                    message: 'No pudimos cargar las publicaciones.',
                    action: AgroButton(
                      label: 'Reintentar',
                      expand: false,
                      onTap: () => ref.invalidate(feedProvider),
                    ),
                  ),
                ),
              ],
              data: (listings) {
                final featured = listings.where((l) => l.featured).toList();
                final nearby = listings
                    .where((l) => _radius == null || l.location.distanceKm <= _radius!)
                    .toList()
                  ..sort((a, b) => a.location.distanceKm.compareTo(b.location.distanceKm));
                return [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
                      child: SectionHeader(title: 'Destacados de la semana'),
                    ),
                  ),
                  SliverToBoxAdapter(child: _FeaturedCarousel(listings: featured, catalog: catalog)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      child: SectionHeader(
                        title: 'Cerca de ti',
                        action: 'Ver todo',
                        onAction: () => context.go('/search'),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          for (final r in const [25, 50, 100, 250, null]) ...[
                            AgroChip(
                              dense: true,
                              label: r == null ? 'Todo México' : '$r km',
                              selected: _radius == r,
                              onTap: () => setState(() => _radius = r),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (nearby.isEmpty)
                    const SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.explore_off_rounded,
                        title: 'Nada tan cerca',
                        message: 'Amplía el radio para ver más publicaciones.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverGrid.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.64,
                        ),
                        itemCount: nearby.length,
                        itemBuilder: (context, i) => FadeSlideIn(
                          key: ValueKey('${nearby[i].id}-$_radius'),
                          delay: Duration(milliseconds: 40 * i),
                          child: ListingCard(listing: nearby[i], heroPrefix: 'home'),
                        ),
                      ),
                    ),
                ];
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider).unread;
    return Row(
      children: [
        const AgroLinkMark(size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola, $name', style: AppText.title, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              const Row(
                children: [
                  Icon(Icons.near_me_rounded, size: 13, color: AppColors.forest),
                  SizedBox(width: 4),
                  Text('Tizimín, Yucatán', style: AppText.muted),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.muted),
                ],
              ),
            ],
          ),
        ),
        CircleIconButton(
          icon: Icons.favorite_border_rounded,
          onTap: () => context.push('/favorites'),
        ),
        const SizedBox(width: 10),
        CircleIconButton(
          icon: Icons.notifications_none_rounded,
          badge: unread > 0,
          onTap: () => context.push('/notifications'),
        ),
      ],
    );
  }
}

class _SearchLauncher extends StatelessWidget {
  const _SearchLauncher({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.only(left: 18, right: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.ink),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Caballos, miel, habanero…',
                style: AppText.muted,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.tune_rounded, color: AppColors.lime, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.typeCount, required this.onTap});

  final AgroCategory category;
  final int typeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Tarjeta tipo "sello": fondo con el acento tenue de la categoría, emblema
    // oficial al centro teñido del tono profundo, rótulo en serif debajo.
    final p = paletteFor(category.id);
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 136,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        decoration: BoxDecoration(
          color: p.soft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.strong.withValues(alpha: 0.55), width: 1.2),
        ),
        child: Column(
          children: [
            Expanded(
              child: hasCategoryEmblem(category.id)
                  ? CategoryEmblem(categoryId: category.id, height: 110, color: p.deep)
                  : CategoryGlyph(value: category.emoji, size: 56, color: p.deep),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(category.name, style: AppText.h3.copyWith(fontSize: 13.5, color: p.deep)),
            ),
            const SizedBox(height: 2),
            Text('$typeCount tipos', style: AppText.muted.copyWith(fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({required this.listings, required this.catalog});

  final List<Listing> listings;
  final Catalog catalog;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  final _controller = PageController(viewportFraction: 0.86);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _page = _controller.page ?? 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.listings.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.listings.length,
            itemBuilder: (context, i) {
              final delta = math.min(1.0, (i - _page).abs());
              final l = widget.listings[i];
              return Transform.scale(
                scale: 1 - delta * 0.07,
                child: Opacity(
                  opacity: 1 - delta * 0.35,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _FeaturedCard(
                      listing: l,
                      typeName: widget.catalog.type(l.productTypeId).name,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.listings.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page.round() == i ? 22 : 7,
                height: 3,
                decoration: BoxDecoration(
                  color: _page.round() == i ? AppColors.ink : AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.listing, required this.typeName});

  final Listing listing;
  final String typeName;

  @override
  Widget build(BuildContext context) {
    final tag = 'featured-${listing.id}';
    return Pressable(
      scale: 0.98,
      onTap: () => context.push('/listing/${listing.id}?hero=$tag'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Antes aquí se dibujaba `listing.cover` como TEXTO a 110px: con datos
            // reales eso es la URL de la foto. Ahora la foto real (o el arte de
            // respaldo si no tiene) se muestra como en el resto de tarjetas.
            ProductArt(
              emoji: listing.placeholderEmoji,
              imageUrl: listing.hasRealPhotos ? listing.cover : null,
              colorKey: listing.categoryId,
              radius: 20,
              emojiSize: 96,
              heroTag: tag,
              variant: 1,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xD91E2420)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_outlined, size: 14, color: AppColors.lime),
                    const SizedBox(width: 4),
                    Text('Destacado', style: AppText.label.copyWith(color: AppColors.bone, fontSize: 11)),
                  ],
                ),
              ),
            ),
            Positioned(top: 12, right: 12, child: FavoriteButton(listingId: listing.id)),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeName.toUpperCase(),
                    style: AppText.overline.copyWith(color: AppColors.lime),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.h3.copyWith(color: AppColors.bone),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      PriceText(listing, size: 19, color: AppColors.bone),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: LocationLine(listing, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

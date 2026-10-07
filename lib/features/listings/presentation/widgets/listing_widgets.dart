import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/agro_widgets.dart';
import '../../../../shared/widgets/motion.dart';
import '../../../../shared/widgets/product_art.dart';
import '../../../catalog/domain/catalog.dart';
import '../../../favorites/application/favorites_controller.dart';
import '../../domain/listing.dart';

String priceLabel(Listing l) =>
    l.priceType == PriceType.quote ? 'Cotizar' : formatMoney(l.price);

class PriceText extends StatelessWidget {
  const PriceText(this.listing, {super.key, this.size = 20, this.color = AppColors.ink});

  final Listing listing;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: priceLabel(listing), style: AppText.price.copyWith(fontSize: size, color: color)),
          TextSpan(
            text: ' ${listing.priceType.suffix}',
            style: AppText.muted.copyWith(fontSize: size * 0.6, color: color.withValues(alpha: 0.6)),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.listingId, this.size = 38});

  final String listingId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoritesProvider.select((s) => s.contains(listingId)));
    return Pressable(
      scale: 0.85,
      onTap: () async {
        final ok = await ref.read(favoritesProvider.notifier).toggle(listingId);
        if (!ok && context.mounted) {
          showAgroSnack(context, 'No se pudo actualizar tus favoritos. Revisa tu conexión.', emoji: '⚠️');
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.94),
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.elasticOut,
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Icon(
            fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(fav),
            color: fav ? AppColors.clay : AppColors.ink,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

class VerifiedTag extends StatelessWidget {
  const VerifiedTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_outlined, size: 13, color: AppColors.lime),
          const SizedBox(width: 4),
          Text('Info verificada', style: AppText.label.copyWith(color: AppColors.bone, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class LocationLine extends StatelessWidget {
  const LocationLine(this.listing, {super.key, this.color = AppColors.muted});

  final Listing listing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.place_rounded, size: 14, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            listing.location.hasKnownDistance
                ? '${listing.location.municipality} · ${listing.location.distanceKm.toStringAsFixed(0)} km'
                : listing.location.municipality,
            style: AppText.muted.copyWith(fontSize: 12, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Tarjeta vertical para grids.
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, this.heroPrefix = 'grid'});

  final Listing listing;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final tag = '$heroPrefix-${listing.id}';
    return Pressable(
      onTap: () => context.push('/listing/${listing.id}?hero=$tag'),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductArt(
                      emoji: listing.placeholderEmoji,
                      imageUrl: listing.hasRealPhotos ? listing.cover : null,
                      colorKey: listing.categoryId,
                      heroTag: tag,
                      radius: 13,
                      emojiSize: 58,
                      variant: listing.id.hashCode,
                    ),
                  ),
                  Positioned(top: 8, right: 8, child: FavoriteButton(listingId: listing.id, size: 34)),
                  if (listing.hasVerifiedInfo) const Positioned(top: 10, left: 8, child: VerifiedTag()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PriceText(listing, size: 18),
                  const SizedBox(height: 2),
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong.copyWith(fontSize: 13, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  LocationLine(listing),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila horizontal para resultados y favoritos.
class ListingTile extends StatelessWidget {
  const ListingTile({super.key, required this.listing, this.heroPrefix = 'tile', this.typeName});

  final Listing listing;
  final String heroPrefix;
  final String? typeName;

  @override
  Widget build(BuildContext context) {
    final tag = '$heroPrefix-${listing.id}';
    return Pressable(
      scale: 0.98,
      onTap: () => context.push('/listing/${listing.id}?hero=$tag'),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: ProductArt(
                emoji: listing.placeholderEmoji,
                imageUrl: listing.hasRealPhotos ? listing.cover : null,
                colorKey: listing.categoryId,
                heroTag: tag,
                radius: 11,
                emojiSize: 46,
                variant: listing.id.hashCode,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (typeName != null)
                        Flexible(
                          child: Text(
                            typeName!.toUpperCase(),
                            style: AppText.overline.copyWith(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (listing.hasVerifiedInfo) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 14, color: AppColors.leaf),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title.copyWith(fontSize: 14, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  PriceText(listing, size: 17),
                  const SizedBox(height: 4),
                  LocationLine(listing),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FavoriteButton(listingId: listing.id, size: 34),
                const SizedBox(height: 60),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

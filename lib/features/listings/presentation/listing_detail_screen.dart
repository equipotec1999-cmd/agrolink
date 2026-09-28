import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/product_art.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/catalog.dart';
import '../../chat/application/chat_controller.dart';
import '../../chat/presentation/offer_sheet.dart';
import '../application/listing_providers.dart';
import '../domain/listing.dart';
import 'widgets/listing_widgets.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.id, this.heroTag});

  final String id;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listingByIdProvider(id));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.forest))),
      error: (e, _) => const Scaffold(
        body: EmptyState(icon: Icons.wifi_off_rounded, title: 'Error', message: 'No pudimos cargar la publicación.'),
      ),
      data: (listing) => listing == null
          ? const Scaffold(
              body: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No encontrada',
                message: 'La publicación ya no está disponible.',
              ),
            )
          : _DetailView(listing: listing, heroTag: heroTag),
    );
  }
}

class _DetailView extends ConsumerStatefulWidget {
  const _DetailView({required this.listing, this.heroTag});
  final Listing listing;
  final String? heroTag;

  @override
  ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  int _photo = 0;
  bool _fullSpecs = false;

  Listing get l => widget.listing;

  void _contact() {
    final convId = ref.read(chatProvider.notifier).openFor(l);
    context.push('/chat/$convId');
  }

  Future<void> _offer() async {
    final ctrl = ref.read(chatProvider.notifier);
    final convId = ctrl.openFor(l);
    final conv = ctrl.byId(convId)!;
    final sent = await showOfferSheet(context, conv);
    if (sent && mounted) context.push('/chat/$convId');
  }

  void _report() {
    const reasons = [
      'Fraude',
      'Información falsa',
      'Producto inexistente',
      'Documentación sospechosa',
      'Publicación duplicada',
      'Conducta inapropiada',
      'Producto no permitido',
      'Otro',
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(21))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reportar publicación', style: AppText.h2),
              const SizedBox(height: 4),
              const Text('Un moderador revisará tu reporte.', style: AppText.muted),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in reasons)
                    AgroChip(
                      dense: true,
                      label: r,
                      selected: false,
                      onTap: () {
                        Navigator.of(sheet).pop();
                        showAgroSnack(context, 'Reporte enviado: $r', emoji: '🚩');
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final type = catalog.type(l.productTypeId);
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 380 + top,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        // Sin fotos reales todavía (listing publicado sin media): un solo
                        // "slide" con el arte de respaldo, en vez de dejar la pantalla en blanco.
                        itemCount: l.gallery.isEmpty ? 1 : l.gallery.length,
                        onPageChanged: (i) => setState(() => _photo = i),
                        itemBuilder: (context, i) => ProductArt(
                          emoji: l.placeholderEmoji,
                          imageUrl: l.hasRealPhotos ? l.gallery[i] : null,
                          colorKey: l.categoryId,
                          radius: 0,
                          emojiSize: 150,
                          variant: i,
                          heroTag: i == 0 ? widget.heroTag : null,
                        ),
                      ),
                      Positioned(
                        bottom: 44,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.ink.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${_photo + 1}/${l.gallery.isEmpty ? 1 : l.gallery.length}',
                            style: AppText.label.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Precio
                        FadeSlideIn(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(child: PriceText(l, size: 32)),
                              if (l.negotiable)
                                const StatusPill(label: 'Negociable', color: AppColors.forest, icon: Icons.handshake_outlined),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 3. Nombre
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 60),
                          child: Text(l.title, style: AppText.h2),
                        ),
                        const SizedBox(height: 10),
                        // 4. Ubicación aproximada
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: Row(
                            children: [
                              const Icon(Icons.place_rounded, size: 16, color: AppColors.forest),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${l.location.short} · a ${l.location.distanceKm.toStringAsFixed(0)} km',
                                  style: AppText.bodyStrong.copyWith(fontSize: 13),
                                ),
                              ),
                              const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.muted),
                              const SizedBox(width: 3),
                              Text('Aprox.', style: AppText.muted.copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 5. Información principal
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 140),
                          child: _KeyFacts(listing: l, type: type),
                        ),
                        const SizedBox(height: 24),
                        const Text('Descripción', style: AppText.h3),
                        const SizedBox(height: 8),
                        Text(l.description, style: AppText.bodyText),
                        const SizedBox(height: 28),
                        // 6. Ficha técnica
                        Row(
                          children: [
                            const Expanded(child: Text('Ficha técnica', style: AppText.h3)),
                            StatusPill(label: type.name, color: paletteFor(l.categoryId).deep),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const _TrustLegend(),
                        const SizedBox(height: 12),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _SpecSheet(listing: l, type: type, expanded: _fullSpecs),
                        ),
                        if (l.attributes.length > 6)
                          Center(
                            child: TextButton.icon(
                              onPressed: () => setState(() => _fullSpecs = !_fullSpecs),
                              icon: AnimatedRotation(
                                turns: _fullSpecs ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: const Icon(Icons.expand_more_rounded, color: AppColors.forest),
                              ),
                              label: Text(
                                _fullSpecs ? 'Ver menos' : 'Ver ficha completa (${l.attributes.length})',
                                style: AppText.label.copyWith(color: AppColors.forest),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        // 7. Documentación
                        _Documents(listing: l),
                        const SizedBox(height: 28),
                        // 8. Vendedor
                        _SellerCard(seller: l.seller),
                        const SizedBox(height: 18),
                        Center(
                          child: TextButton.icon(
                            onPressed: _report,
                            icon: const Icon(Icons.flag_outlined, size: 18, color: AppColors.muted),
                            label: Text('Reportar publicación', style: AppText.label.copyWith(color: AppColors.muted)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Barra superior flotante
          Positioned(
            top: top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                const Spacer(),
                CircleIconButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () => showAgroSnack(context, 'Enlace copiado: agrolink.mx/p/${l.id}', emoji: '🔗'),
                ),
                const SizedBox(width: 10),
                FavoriteButton(listingId: l.id, size: 46),
              ],
            ),
          ),
          // 9 y 10. Contactar / Hacer oferta
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                boxShadow: [
                  BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: AgroButton(
                          label: 'Contactar',
                          icon: Icons.chat_bubble_outline_rounded,
                          tone: ButtonTone.light,
                          onTap: _contact,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AgroButton(
                          label: 'Hacer oferta',
                          icon: Icons.local_offer_rounded,
                          onTap: _offer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyFacts extends StatelessWidget {
  const _KeyFacts({required this.listing, required this.type});
  final Listing listing;
  final ProductType type;

  @override
  Widget build(BuildContext context) {
    final facts = <(String, String)>[
      ('Disponible', '${listing.quantity.toStringAsFixed(0)} ${listing.unit}'),
      ('Venta', listing.isLot ? 'Por lote' : 'Individual'),
      for (final a in listing.attributes.take(4))
        if (type.attribute(a.key) case final def?)
          (def.label, def.unit == null ? a.value : '${a.value} ${def.unit}'),
    ];
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: facts.length,
        separatorBuilder: (context, i) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (label, value) = facts[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.line, width: 1.2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label.toUpperCase(), style: AppText.overline.copyWith(fontSize: 9.5)),
                const SizedBox(height: 4),
                Text(value, style: AppText.title),
              ],
            ),
          );
        },
      ),
    );
  }
}

(IconData, Color, String) trustStyle(VerificationLevel v) => switch (v) {
      VerificationLevel.declared => (Icons.person_outline_rounded, AppColors.muted, 'Declarado por el vendedor'),
      VerificationLevel.documented => (Icons.description_outlined, AppColors.sky, 'Verificado con documento'),
      VerificationLevel.professional => (Icons.verified_rounded, AppColors.success, 'Verificado por profesional'),
    };

class _TrustLegend extends StatelessWidget {
  const _TrustLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final v in VerificationLevel.values)
          Builder(builder: (context) {
            final (icon, color, label) = trustStyle(v);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(label, style: AppText.muted.copyWith(fontSize: 11)),
              ],
            );
          }),
      ],
    );
  }
}

class _SpecSheet extends StatelessWidget {
  const _SpecSheet({required this.listing, required this.type, required this.expanded});

  final Listing listing;
  final ProductType type;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final values = expanded ? listing.attributes : listing.attributes.take(6).toList();
    final groups = <AttributeGroup, List<ListingAttributeValue>>{};
    for (final v in values) {
      final def = type.attribute(v.key);
      if (def == null) continue;
      groups.putIfAbsent(def.group, () => []).add(v);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line, width: 1.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(entry.key.label.toUpperCase(), style: AppText.overline),
            ),
            for (final v in entry.value) _SpecRow(def: type.attribute(v.key)!, value: v),
          ],
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.def, required this.value});
  final AttributeDef def;
  final ListingAttributeValue value;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = trustStyle(value.verification);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cream, width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(def.label, style: AppText.muted)),
          Flexible(
            child: Text(
              def.unit == null ? value.value : '${value.value} ${def.unit}',
              style: AppText.bodyStrong,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(message: label, child: Icon(icon, size: 16, color: color)),
        ],
      ),
    );
  }
}

class _Documents extends StatelessWidget {
  const _Documents({required this.listing});
  final Listing listing;

  (String, Color, IconData) _style(DocumentStatus s) => switch (s) {
        DocumentStatus.pending => ('Pendiente', AppColors.honey, Icons.schedule_rounded),
        DocumentStatus.verified => ('Verificado', AppColors.success, Icons.check_circle_rounded),
        DocumentStatus.rejected => ('Rechazado', AppColors.danger, Icons.cancel_rounded),
        DocumentStatus.expired => ('Vencido', AppColors.danger, Icons.event_busy_rounded),
        DocumentStatus.notApplicable => ('No aplica', AppColors.muted, Icons.remove_circle_outline_rounded),
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Documentación', style: AppText.h3),
        const SizedBox(height: 10),
        if (listing.documents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.line, width: 1.2)),
            child: const Text('El vendedor no ha subido documentos.', style: AppText.muted),
          )
        else
          for (final d in listing.documents)
            Builder(builder: (context) {
              final (label, color, icon) = _style(d.status);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.line, width: 1.2)),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name, style: AppText.bodyStrong),
                          if (d.note != null) Text(d.note!, style: AppText.muted.copyWith(fontSize: 11.5)),
                        ],
                      ),
                    ),
                    StatusPill(label: label, color: color),
                  ],
                ),
              );
            }),
        const SizedBox(height: 4),
        const Text(
          'Un documento subido no se considera válido hasta que un verificador lo revisa. '
          'Los requisitos oficiales se consultan en la fuente (p. ej. SENASICA).',
          style: TextStyle(fontFamily: AppText.body, fontSize: 11.5, color: AppColors.muted, height: 1.4),
        ),
      ],
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.seller});
  final Seller seller;

  @override
  Widget build(BuildContext context) {
    final s = seller;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.lime,
                child: Text(s.initials, style: AppText.h3.copyWith(fontSize: 17)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            s.name,
                            style: AppText.title.copyWith(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (s.verified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: AppColors.lime, size: 17),
                        ],
                      ],
                    ),
                    Text(
                      'En AgroLink desde ${s.memberSince}',
                      style: AppText.muted.copyWith(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Metric(value: '${s.completedOps}', label: 'Operaciones'),
              _Metric(value: s.responseTime ?? 'Sin datos', label: 'Respuesta'),
              _Metric(value: s.cancellations != null ? '${s.cancellations}' : '—', label: 'Cancelaciones'),
            ],
          ),
          const SizedBox(height: 16),
          _RatingBar(label: 'Exactitud', value: s.accuracy),
          _RatingBar(label: 'Cumplimiento', value: s.fulfillment),
          _RatingBar(label: 'Comunicación', value: s.communication),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppText.h3.copyWith(color: AppColors.lime)),
          Text(label, style: AppText.muted.copyWith(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: AppText.muted.copyWith(color: Colors.white70, fontSize: 12)),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value / 5),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 7,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(AppColors.lime),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(value.toStringAsFixed(1), style: AppText.label.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

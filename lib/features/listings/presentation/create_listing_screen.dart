import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../my_listings/data/my_listings_repository.dart';
import '../../../core/location/device_location.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/product_art.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/catalog.dart';
import '../application/listing_draft_controller.dart';
import '../data/listing_repository.dart';
import '../domain/listing_draft.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _pages = PageController();
  int _step = 0;
  bool _publishing = false;

  static const _titles = [
    ('¿Qué vas a vender?', 'Elige el tipo: la ficha se adapta a él.'),
    ('Lo básico', 'Título, precio y cantidad.'),
    ('Ficha técnica', 'Campos específicos de este producto.'),
    ('Fotos y documentos', 'Las publicaciones con fotos venden más.'),
    ('Ubicación', 'Solo mostramos municipio y distancia.'),
    ('Revisión', 'Así se verá tu publicación.'),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    _pages.animateToPage(step, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  void _next() {
    final draft = ref.read(listingDraftProvider);
    if (_step == 0 && draft.productTypeId == null) {
      showAgroSnack(context, 'Elige un tipo de producto', emoji: '👆');
      return;
    }
    if (_step < _titles.length - 1) {
      _go(_step + 1);
    } else {
      _publish();
    }
  }

  Future<void> _publish() async {
    final draft = ref.read(listingDraftProvider);
    final catalog = ref.read(catalogProvider);
    final type = catalog.type(draft.productTypeId!); // canPublish ya lo garantiza

    if (!draft.hasLocation) {
      showAgroSnack(context, 'Comparte tu ubicación en el paso anterior para publicar', emoji: '📍');
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _publishing = true);
    try {
      await ref.read(listingRepositoryProvider).publishDraft(
            draft,
            type,
            lat: draft.lat!,
            lng: draft.lng!,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const _PublishedDialog(),
      );
      if (!mounted) return;
      ref.read(listingDraftProvider.notifier).reset();
      ref.invalidate(myListingsProvider);
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completeness = ref.watch(draftCompletenessProvider);
    final (title, subtitle) = _titles[_step];
    final isLast = _step == _titles.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.close_rounded,
                    onTap: () {
                      showAgroSnack(context, 'Borrador guardado', emoji: '💾');
                      context.pop();
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PASO ${_step + 1} DE ${_titles.length}', style: AppText.overline),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: (_step + 1) / _titles.length),
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 7,
                              backgroundColor: AppColors.sand,
                              valueColor: const AlwaysStoppedAnimation(AppColors.forest),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PercentBadge(ratio: completeness.ratio),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(a),
                    child: child,
                  ),
                ),
                child: SizedBox(
                  key: ValueKey(_step),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.h1),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppText.muted),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _TypeStep(),
                  _BasicsStep(),
                  _AttributesStep(),
                  _MediaStep(),
                  _LocationStep(),
                  _ReviewStep(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child: _step == 0
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: AgroButton(
                              label: 'Atrás',
                              tone: ButtonTone.light,
                              expand: false,
                              onTap: () => _go(_step - 1),
                            ),
                          ),
                  ),
                  Expanded(
                    child: AgroButton(
                      label: isLast ? 'Enviar a revisión' : 'Continuar',
                      icon: isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                      tone: isLast ? ButtonTone.lime : ButtonTone.dark,
                      loading: isLast && _publishing,
                      onTap: (isLast && (!completeness.canPublish || _publishing)) ? null : _next,
                    ),
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

class _PercentBadge extends StatelessWidget {
  const _PercentBadge({required this.ratio});
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: ratio),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 4.5,
                backgroundColor: AppColors.sand,
                valueColor: AlwaysStoppedAnimation(v >= 1 ? AppColors.success : AppColors.forest),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text('${(v * 100).round()}%', style: AppText.label.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────── Paso 1: tipo
class _TypeStep extends ConsumerWidget {
  const _TypeStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final draft = ref.watch(listingDraftProvider);
    final ctrl = ref.read(listingDraftProvider.notifier);
    final categoryId = draft.categoryId ?? catalog.categories.first.id;
    final types = catalog.typesOf(categoryId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in catalog.categories)
              AgroChip(
                dense: true,
                emoji: c.emoji,
                label: c.name,
                selected: c.id == categoryId,
                onTap: () => ctrl.selectCategory(c.id),
              ),
          ],
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            for (var i = 0; i < types.length; i++)
              FadeSlideIn(
                key: ValueKey('${categoryId}_${types[i].id}'),
                delay: Duration(milliseconds: 40 * i),
                child: _TypeCard(
                  type: types[i],
                  selected: draft.productTypeId == types[i].id,
                  onTap: () => ctrl.selectType(types[i]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(18)),
          child: const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Los tipos y sus campos vienen del catálogo del servidor: se pueden agregar nuevos sin actualizar la app.',
                  style: TextStyle(fontFamily: AppText.body, fontSize: 12, color: AppColors.ink, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type, required this.selected, required this.onTap});

  final ProductType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              child: ProductArt(emoji: type.emoji, colorKey: type.categoryId, radius: 20, emojiSize: 34),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                type.name,
                style: AppText.label.copyWith(color: selected ? AppColors.lime : AppColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────── Paso 2: básicos
class _BasicsStep extends ConsumerWidget {
  const _BasicsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(listingDraftProvider);
    final ctrl = ref.read(listingDraftProvider.notifier);
    final catalog = ref.watch(catalogProvider);
    final type = draft.productTypeId == null ? null : catalog.type(draft.productTypeId!);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        AgroTextField(
          label: 'Título',
          hint: type == null ? 'Ej. Novillos Brahman' : 'Ej. ${type.name} de primera',
          initialValue: draft.title,
          onChanged: (v) => ctrl.edit((d) => d.copyWith(title: v)),
        ),
        const SizedBox(height: 16),
        AgroTextField(
          label: 'Descripción',
          hint: 'Cuenta lo que un comprador querría saber',
          initialValue: draft.description,
          maxLines: 4,
          onChanged: (v) => ctrl.edit((d) => d.copyWith(description: v)),
        ),
        const SizedBox(height: 20),
        const Text('¿Cómo se vende?', style: AppText.label),
        const SizedBox(height: 6),
        Text(
          'La unidad y el precio dependen de esta elección.',
          style: AppText.muted.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in type?.priceTypes ?? PriceType.values)
              AgroChip(
                dense: true,
                label: p.label,
                selected: draft.priceType == p,
                onTap: () {
                  // Al elegir el tipo de precio ya queda la unidad obvia: por kg → "kg",
                  // por animal → "animal", por lote → "lote". El vendedor solo escribe
                  // la unidad cuando el tipo es "por unidad" (puede ser pieza, caja, etc.).
                  final unit = _impliedUnit(p);
                  ctrl.edit((d) => d.copyWith(
                        priceType: p,
                        unit: unit ?? (p == PriceType.perUnit ? '' : d.unit),
                      ));
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...[
          Row(
            children: [
              if (draft.priceType != PriceType.quote) ...[
              Expanded(
                child: AgroTextField(
                  label: 'Precio (MXN)',
                  icon: Icons.attach_money_rounded,
                  initialValue: draft.price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffixText: draft.priceType?.suffix,
                  onChanged: (v) => ctrl.edit((d) => d.copyWith(price: v)),
                ),
              ),
              const SizedBox(width: 12),
              ],
              Expanded(
                child: AgroTextField(
                  label: _quantityLabel(draft.priceType, draft.unit, inTons: draft.quantityInTons),
                  icon: Icons.inventory_2_outlined,
                  initialValue: draft.quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => ctrl.edit((d) => d.copyWith(quantity: v)),
                ),
              ),
            ],
          ),
          // Para precios "por kg" damos la opción de ingresar la cantidad en toneladas:
          // el precio sigue siendo por kg (estándar comercial) y la app convierte x1000
          // al enviar; así no hay que calcular mentalmente los kilos.
          if (draft.priceType == PriceType.perKg) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Mi cantidad está en:', style: AppText.muted.copyWith(fontSize: 12.5)),
                const SizedBox(width: 10),
                AgroChip(
                  dense: true,
                  label: 'kg',
                  selected: !draft.quantityInTons,
                  onTap: () => ctrl.edit((d) => d.copyWith(quantityInTons: false)),
                ),
                const SizedBox(width: 6),
                AgroChip(
                  dense: true,
                  label: 'toneladas',
                  selected: draft.quantityInTons,
                  onTap: () => ctrl.edit((d) => d.copyWith(quantityInTons: true)),
                ),
              ],
            ),
            if (draft.quantityInTons && (double.tryParse(draft.quantity) ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: Text(
                  '= ${formatQuantity((double.tryParse(draft.quantity) ?? 0) * 1000)} kg',
                  style: AppText.muted.copyWith(fontSize: 12),
                ),
              ),
          ],
        ],
        // "Unidad" solo aparece cuando el tipo de precio no la fija por sí mismo
        // (perUnit, fixed, negotiable): ahí puede ser pieza, caja, bulto, etc.
        if (_showsUnitField(draft.priceType)) ...[
          const SizedBox(height: 16),
          AgroTextField(
            label: 'Unidad',
            hint: 'Ej. pieza, caja, bulto, cabeza',
            icon: Icons.straighten_rounded,
            initialValue: draft.unit,
            onChanged: (v) => ctrl.edit((d) => d.copyWith(unit: v)),
          ),
        ],
        const SizedBox(height: 16),
        _ToggleTile(
          title: 'Precio negociable',
          subtitle: 'Permite recibir ofertas y contraofertas',
          value: draft.negotiable,
          onChanged: (v) => ctrl.edit((d) => d.copyWith(negotiable: v)),
        ),
        _ToggleTile(
          title: 'Venta por lote',
          subtitle: 'Se vende todo junto, no por pieza',
          value: draft.isLot,
          onChanged: (v) => ctrl.edit((d) => d.copyWith(isLot: v)),
        ),
      ],
    );
  }
}

/// Para tipos de precio con unidad implícita devuelve el texto que va al borrador
/// (y que se usa como etiqueta en la cantidad). Para los que admiten unidad libre
/// (por unidad, precio fijo, negociable), devuelve null — se le pide al vendedor.
String? _impliedUnit(PriceType? p) => switch (p) {
      PriceType.perAnimal => 'animal',
      PriceType.perKg => 'kg',
      PriceType.perLot => 'lote',
      _ => null,
    };

bool _showsUnitField(PriceType? p) =>
    p == PriceType.perUnit || p == PriceType.quote || p == PriceType.fixed || p == PriceType.negotiable || p == null;

/// Etiqueta de "cantidad disponible" según cómo se vende: "100 kg", "20 animales",
/// "3 lotes", etcétera; para precio por unidad usa lo que el vendedor escribió.
String _quantityLabel(PriceType? p, String unit, {bool inTons = false}) {
  final u = switch (p) {
    PriceType.perAnimal => 'animales',
    PriceType.perKg => inTons ? 'ton' : 'kg',
    PriceType.perLot => 'lotes',
    PriceType.perUnit => unit.trim().isEmpty ? 'unidades' : unit.trim(),
    _ => unit.trim().isEmpty ? 'disponible' : unit.trim(),
  };
  return 'Cantidad ($u)';
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line, width: 1.2)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyStrong),
                Text(subtitle, style: AppText.muted.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.forest,
            activeThumbColor: AppColors.lime,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── Paso 3: atributos dinámicos
class _AttributesStep extends ConsumerWidget {
  const _AttributesStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(listingDraftProvider);
    final catalog = ref.watch(catalogProvider);
    if (draft.productTypeId == null) {
      return const EmptyState(
        icon: Icons.category_outlined,
        title: 'Primero elige un tipo',
        message: 'La ficha depende del producto.',
      );
    }
    final type = catalog.type(draft.productTypeId!);
    final groups = <AttributeGroup, List<AttributeDef>>{};
    for (final a in type.attributes) {
      groups.putIfAbsent(a.group, () => []).add(a);
    }

    return ListView(
      key: ValueKey(type.id),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: ProductArt(emoji: type.emoji, colorKey: type.categoryId, radius: 12, emojiSize: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${type.name} · ${type.requiredAttributes.length} campos obligatorios',
                style: AppText.bodyStrong,
              ),
            ),
          ],
        ),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 4),
            child: Text(entry.key.label.toUpperCase(), style: AppText.overline),
          ),
          for (final a in entry.value)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _DynamicField(def: a, value: draft.attributes[a.key] ?? ''),
            ),
        ],
      ],
    );
  }
}

/// Renderiza el control correcto según el tipo de dato del atributo.
class _DynamicField extends ConsumerWidget {
  const _DynamicField({required this.def, required this.value});

  final AttributeDef def;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(listingDraftProvider.notifier);
    final label = def.required ? '${def.label} *' : def.label;

    switch (def.type) {
      case AttributeDataType.select:
      case AttributeDataType.boolean:
        final options = def.type == AttributeDataType.boolean ? const ['Sí', 'No'] : def.options;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(label, style: AppText.label),
            ),
            if (def.hint != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(def.hint!, style: AppText.muted.copyWith(fontSize: 11.5)),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in options)
                  AgroChip(
                    dense: true,
                    label: o,
                    selected: value == o,
                    onTap: () => ctrl.setAttribute(def.key, value == o ? '' : o),
                  ),
              ],
            ),
          ],
        );
      case AttributeDataType.number:
        return AgroTextField(
          label: label,
          initialValue: value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffixText: def.unit,
          onChanged: (v) => ctrl.setAttribute(def.key, v),
        );
      case AttributeDataType.text:
        return AgroTextField(
          label: label,
          initialValue: value,
          onChanged: (v) => ctrl.setAttribute(def.key, v),
        );
      case AttributeDataType.date:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(label, style: AppText.label),
            ),
            Pressable(
              scale: 0.98,
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 1),
                  initialDate: now,
                );
                if (picked != null) {
                  ctrl.setAttribute(def.key, '${picked.day}/${picked.month}/${picked.year}');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line, width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded, color: AppColors.muted, size: 20),
                    const SizedBox(width: 12),
                    Text(value.isEmpty ? 'Elegir fecha' : value, style: value.isEmpty ? AppText.muted : AppText.bodyStrong),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}

// ─────────────────────────────── Paso 4: fotos y documentos
class _MediaStep extends ConsumerWidget {
  const _MediaStep();

  Future<void> _addPhoto(WidgetRef ref) async {
    // Selector de fotos del sistema (Android 13+ no pide permiso de galería
    // para esto; en versiones viejas sí lo pide image_picker por su cuenta).
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2000);
    if (file != null) ref.read(listingDraftProvider.notifier).addPhoto(file.path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(listingDraftProvider);
    final ctrl = ref.read(listingDraftProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            Pressable(
              onTap: draft.photos.length >= 10 ? null : () => _addPhoto(ref),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_rounded, color: AppColors.lime, size: 26),
                    const SizedBox(height: 6),
                    Text('${draft.photos.length}/10', style: AppText.label.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < draft.photos.length; i++)
              FadeSlideIn(
                key: ValueKey('photo-${draft.photos[i]}'),
                offset: 10,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(File(draft.photos[i]), fit: BoxFit.cover),
                      ),
                    ),
                    if (i == 0)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: StatusPill(label: 'Portada', color: AppColors.ink),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: CircleIconButton(
                        icon: Icons.close_rounded,
                        size: 26,
                        onTap: () => ctrl.removePhoto(i),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Elige fotos reales de tu galería. La primera es la portada; se suben al publicar.',
          style: AppText.muted.copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 26),
        const Text('DOCUMENTACIÓN (OPCIONAL)', style: AppText.overline),
        const SizedBox(height: 10),
        for (var i = 0; i < draft.documents; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line, width: 1.2)),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: AppColors.sky),
                const SizedBox(width: 10),
                Expanded(child: Text('Documento ${i + 1}.pdf', style: AppText.bodyStrong)),
                const StatusPill(label: 'Pendiente', color: AppColors.honey),
              ],
            ),
          ),
        AgroButton(
          label: 'Subir documento',
          icon: Icons.upload_file_rounded,
          tone: ButtonTone.light,
          onTap: () => ctrl.edit((d) => d.copyWith(documents: d.documents + 1)),
        ),
        const SizedBox(height: 8),
        Text(
          'Todo documento queda "Pendiente" hasta que un verificador lo revise.',
          style: AppText.muted.copyWith(fontSize: 11.5),
        ),
      ],
    );
  }
}

// ─────────────────────────────── Paso 5: ubicación
class _LocationStep extends ConsumerStatefulWidget {
  const _LocationStep();

  @override
  ConsumerState<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<_LocationStep> {
  static const _states = ['Yucatán', 'Campeche', 'Quintana Roo', 'Tabasco', 'Chiapas', 'Veracruz', 'Jalisco', 'Sonora'];
  bool _locating = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final position = await DeviceLocation.current();
    if (!mounted) return;
    setState(() => _locating = false);
    if (position == null) {
      showAgroSnack(context, 'No se pudo obtener tu ubicación. Revisa permisos y GPS.', emoji: '📍');
      return;
    }
    ref.read(listingDraftProvider.notifier).edit(
          (d) => d.copyWith(lat: position.latitude, lng: position.longitude),
        );
    if (!mounted) return;
    showAgroSnack(context, 'Ubicación capturada', emoji: '📍');
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(listingDraftProvider);
    final ctrl = ref.read(listingDraftProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        const Text('Estado', style: AppText.label),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _states)
              AgroChip(
                dense: true,
                label: s,
                selected: draft.state == s,
                onTap: () => ctrl.edit((d) => d.copyWith(state: s)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        AgroTextField(
          label: 'Municipio',
          icon: Icons.location_city_rounded,
          hint: 'Ej. Tizimín',
          initialValue: draft.municipality,
          onChanged: (v) => ctrl.edit((d) => d.copyWith(municipality: v)),
        ),
        const SizedBox(height: 16),
        AgroTextField(
          label: 'Código postal',
          icon: Icons.markunread_mailbox_outlined,
          hint: '97700',
          initialValue: draft.postalCode,
          keyboardType: TextInputType.number,
          onChanged: (v) => ctrl.edit((d) => d.copyWith(postalCode: v)),
        ),
        const SizedBox(height: 20),
        AgroButton(
          label: draft.hasLocation ? 'Ubicación capturada ✓' : 'Usar mi ubicación actual',
          icon: Icons.my_location_rounded,
          tone: draft.hasLocation ? ButtonTone.light : ButtonTone.dark,
          loading: _locating,
          onTap: _locating ? null : _useCurrentLocation,
        ),
        const SizedBox(height: 8),
        Text(
          'Necesaria para publicar: el backend calcula la distancia aproximada con esto.',
          style: AppText.muted.copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.privacy_tip_outlined, color: AppColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Tu ubicación exacta nunca se muestra. Los compradores solo ven municipio y distancia aproximada.',
                  style: AppText.muted.copyWith(color: Colors.white70, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────── Paso 6: revisión
class _ReviewStep extends ConsumerWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(draftCompletenessProvider);
    final draft = ref.watch(listingDraftProvider);
    final pct = (c.ratio * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line, width: 1.2)),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: c.ratio),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: v,
                          strokeWidth: 9,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.sand,
                          valueColor: AlwaysStoppedAnimation(c.canPublish ? AppColors.success : AppColors.honey),
                        ),
                      ),
                      Text('${(v * 100).round()}%', style: AppText.h2),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.canPublish ? '¡Lista para revisión!' : 'Casi lista', style: AppText.h3),
                    const SizedBox(height: 4),
                    Text(
                      c.canPublish
                          ? 'Un moderador la revisará antes de publicarla.'
                          : 'Completa los campos obligatorios ($pct%). No se publican fichas incompletas.',
                      style: AppText.muted.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final s in c.sections)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line, width: 1.2)),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    s.complete
                        ? Icons.check_circle_rounded
                        : (s.optional ? Icons.error_outline_rounded : Icons.radio_button_unchecked_rounded),
                    key: ValueKey('${s.label}-${s.complete}'),
                    color: s.complete ? AppColors.success : (s.optional ? AppColors.honey : AppColors.muted),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(s.label, style: AppText.bodyStrong)),
                Text(
                  s.optional && !s.complete ? 'Recomendado' : '${s.done > s.total ? s.total : s.done}/${s.total}',
                  style: AppText.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (draft.title.isNotEmpty)
          Text('“${draft.title}”', style: AppText.h3.copyWith(color: AppColors.forest)),
      ],
    );
  }
}

class _PublishedDialog extends StatefulWidget {
  const _PublishedDialog();

  @override
  State<_PublishedDialog> createState() => _PublishedDialogState();
}

class _PublishedDialogState extends State<_PublishedDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
              child: Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 52, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: 20),
            const Text('¡Enviada a revisión!', style: AppText.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Estado: pending_review. Te avisaremos cuando un moderador la apruebe.',
              style: AppText.muted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            AgroButton(label: 'Listo', onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

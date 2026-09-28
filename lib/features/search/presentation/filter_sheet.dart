import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/catalog.dart';
import '../application/search_controller.dart';
import '../domain/search_filters.dart';

Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(21))),
    builder: (_) => const _FilterSheet(),
  );
}

/// Los filtros de atributos se generan desde el catálogo: si el backend agrega
/// un atributo "filtrable" a un tipo de producto, aparece aquí sin tocar código.
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late SearchFilters _f = ref.read(searchFiltersProvider);

  void _toggleAttr(String key, String value) {
    final map = {for (final e in _f.attributeValues.entries) e.key: {...e.value}};
    final set = map.putIfAbsent(key, () => <String>{});
    if (!set.remove(value)) set.add(value);
    setState(() => _f = _f.copyWith(attributeValues: map));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final types = _f.categoryId == null ? catalog.productTypes : catalog.typesOf(_f.categoryId!);
    final selectedType = _f.productTypeId == null ? null : catalog.type(_f.productTypeId!);
    final attrFilters = selectedType?.attributes
            .where((a) => a.filterable && a.type == AttributeDataType.select)
            .toList() ??
        const <AttributeDef>[];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(9)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Text('Filtros', style: AppText.h2)),
                    TextButton(
                      onPressed: () => setState(
                        () => _f = SearchFilters(query: _f.query, categoryId: _f.categoryId, sort: _f.sort),
                      ),
                      child: Text('Limpiar', style: AppText.label.copyWith(color: AppColors.clay)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                const _Label('TIPO DE PRODUCTO'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in types)
                      AgroChip(
                        dense: true,
                        emoji: t.emoji,
                        label: t.name,
                        selected: _f.productTypeId == t.id,
                        onTap: () => setState(() {
                          _f = _f.productTypeId == t.id
                              ? _f.copyWith(clearType: true, attributeValues: const {})
                              : _f.copyWith(productTypeId: t.id, categoryId: t.categoryId, attributeValues: const {});
                        }),
                      ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final a in attrFilters) ...[
                        _Label(a.label.toUpperCase()),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final o in a.options)
                              AgroChip(
                                dense: true,
                                label: o,
                                selected: _f.attributeValues[a.key]?.contains(o) ?? false,
                                onTap: () => _toggleAttr(a.key, o),
                              ),
                          ],
                        ),
                      ],
                      if (selectedType == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Elige un tipo de producto para ver filtros específicos (raza, propósito, calidad…).',
                            style: AppText.muted.copyWith(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const _Label('DISTANCIA MÁXIMA'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final km in const [25, 50, 100, 250])
                      AgroChip(
                        dense: true,
                        label: '$km km',
                        selected: _f.maxDistanceKm == km,
                        onTap: () => setState(() {
                          _f = _f.maxDistanceKm == km ? _f.copyWith(clearDistance: true) : _f.copyWith(maxDistanceKm: km);
                        }),
                      ),
                  ],
                ),
                const _Label('CONFIANZA Y VENTA'),
                _SwitchRow(
                  title: 'Solo con información verificada',
                  subtitle: 'Documentos o profesional',
                  value: _f.verifiedOnly,
                  onChanged: (v) => setState(() => _f = _f.copyWith(verifiedOnly: v)),
                ),
                _SwitchRow(
                  title: 'Precio negociable',
                  value: _f.negotiableOnly,
                  onChanged: (v) => setState(() => _f = _f.copyWith(negotiableOnly: v)),
                ),
                _SwitchRow(
                  title: 'Venta por lote',
                  value: _f.lotsOnly,
                  onChanged: (v) => setState(() => _f = _f.copyWith(lotsOnly: v)),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: AgroButton(
                label: 'Ver resultados',
                icon: Icons.check_rounded,
                onTap: () {
                  ref.read(searchFiltersProvider.notifier).apply(_f);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(text, style: AppText.overline),
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.value, required this.onChanged, this.subtitle});

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line, width: 1.2)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyStrong),
                if (subtitle != null) Text(subtitle!, style: AppText.muted.copyWith(fontSize: 12)),
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

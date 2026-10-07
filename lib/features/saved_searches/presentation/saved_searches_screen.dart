import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../search/application/search_controller.dart';
import '../../search/domain/search_filters.dart';
import '../data/saved_searches_repository.dart';

/// Resumen legible de los filtros guardados.
String describeFilters(SearchFilters f, WidgetRef ref) {
  final catalog = ref.read(catalogProvider);
  final parts = <String>[];
  if (f.query.trim().isNotEmpty) parts.add('"${f.query.trim()}"');
  for (final t in catalog.productTypes) {
    if (t.id == f.productTypeId) parts.add(t.name);
  }
  if (f.productTypeId == null) {
    for (final c in catalog.categories) {
      if (c.id == f.categoryId) parts.add(c.name);
    }
  }
  if (f.maxDistanceKm != null) parts.add('≤ ${f.maxDistanceKm} km');
  if (f.verifiedOnly) parts.add('Verificados');
  if (f.negotiableOnly) parts.add('Negociable');
  if (f.lotsOnly) parts.add('Lotes');
  final attrs = f.attributeValues.values.where((s) => s.isNotEmpty).length;
  if (attrs > 0) parts.add('$attrs filtro(s)');
  return parts.isEmpty ? 'Todas las publicaciones' : parts.join(' · ');
}

class SavedSearchesScreen extends ConsumerWidget {
  const SavedSearchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(savedSearchesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
              child: Row(
                children: [
                  CircleIconButton(icon: Icons.arrow_back_rounded, background: AppColors.cream, onTap: () => context.pop()),
                  const SizedBox(width: 12),
                  const Text('Búsquedas guardadas', style: AppText.h1),
                ],
              ),
            ),
            Expanded(
              child: items.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.wifi_off_rounded, title: 'No pudimos cargar', message: '$e'),
                data: (list) => list.isEmpty
                    ? const EmptyState(
                        icon: Icons.bookmark_border_rounded,
                        title: 'Sin búsquedas guardadas',
                        message: 'En Buscar, ajusta tus filtros y toca "Guardar búsqueda" para repetirla con un toque.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(savedSearchesProvider.future),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                          itemCount: list.length,
                          separatorBuilder: (context, i) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final s = list[i];
                            return Material(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  ref.read(searchFiltersProvider.notifier).apply(s.filters);
                                  context.go('/search');
                                },
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.line, width: 1.2),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.bookmark_rounded, color: AppColors.forest),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.name, style: AppText.bodyStrong),
                                            const SizedBox(height: 2),
                                            Text(describeFilters(s.filters, ref), style: AppText.muted),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted),
                                        onPressed: () async {
                                          try {
                                            await ref.read(savedSearchesRepositoryProvider).delete(s.id);
                                            ref.invalidate(savedSearchesProvider);
                                          } on ApiException catch (e) {
                                            if (context.mounted) showAgroSnack(context, e.message, emoji: '⚠️');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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

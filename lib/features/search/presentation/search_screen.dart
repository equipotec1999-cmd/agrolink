import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../listings/presentation/widgets/listing_widgets.dart';
import '../application/search_controller.dart';
import '../domain/search_filters.dart';
import 'filter_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _query =
      TextEditingController(text: ref.read(searchFiltersProvider).query);

  static const _examples = [
    'caballos cuarto de milla menores de 8 años',
    'borregos de engorda de 35 a 50 kg',
    'chile habanero más de 500 kg',
    'miel multifloral por mayoreo',
  ];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _setQuery(String q) {
    _query.text = q;
    _query.selection = TextSelection.collapsed(offset: q.length);
    ref.read(searchFiltersProvider.notifier).setQuery(q);
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final parsed = ref.watch(parsedQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final catalog = ref.watch(catalogProvider);
    final ctrl = ref.read(searchFiltersProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Text('Buscar', style: AppText.h1),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _query,
                        onChanged: ctrl.setQuery,
                        textInputAction: TextInputAction.search,
                        style: AppText.bodyStrong,
                        decoration: InputDecoration(
                          hintText: 'Escribe como hablas: “borregos de 35 a 50 kg”',
                          hintStyle: AppText.muted.copyWith(fontSize: 12.5),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.ink),
                          suffixIcon: filters.query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                                  onPressed: () => _setQuery(''),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Pressable(
                      onTap: () => showFilterSheet(context),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.tune_rounded, color: AppColors.lime),
                            if (filters.activeCount > 0)
                              Positioned(
                                top: 9,
                                right: 9,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                                  child: Text('${filters.activeCount}', style: AppText.label.copyWith(fontSize: 10)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Interpretación de la búsqueda en lenguaje natural
            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                child: parsed.chips.isEmpty
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.forest),
                            Text('Entendimos:', style: AppText.label.copyWith(color: AppColors.forest)),
                            for (final c in parsed.chips)
                              StatusPill(label: c, color: AppColors.forest),
                          ],
                        ),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    AgroChip(
                      label: 'Todo',
                      selected: filters.categoryId == null,
                      onTap: () => ctrl.setCategory(null),
                    ),
                    for (final c in catalog.categories) ...[
                      const SizedBox(width: 8),
                      AgroChip(
                        label: c.name,
                        emoji: c.emoji,
                        selected: filters.categoryId == c.id,
                        onTap: () => ctrl.setCategory(c.id),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (filters.query.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PRUEBA BUSCAR', style: AppText.overline),
                      const SizedBox(height: 8),
                      for (final e in _examples)
                        Pressable(
                          scale: 0.98,
                          onTap: () => _setQuery(e),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                const Icon(Icons.north_west_rounded, size: 16, color: AppColors.muted),
                                const SizedBox(width: 10),
                                Expanded(child: Text(e, style: AppText.bodyStrong.copyWith(fontSize: 13.5))),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        results.hasValue ? '${results.value!.length} resultados' : 'Buscando…',
                        style: AppText.h3,
                      ),
                    ),
                    PopupMenuButton<SortOption>(
                      initialValue: filters.sort,
                      onSelected: ctrl.setSort,
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (context) => [
                        for (final s in SortOption.values)
                          PopupMenuItem(value: s, child: Text(s.label, style: AppText.bodyStrong)),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const Icon(Icons.swap_vert_rounded, size: 18, color: AppColors.forest),
                            const SizedBox(width: 4),
                            Text(filters.sort.label, style: AppText.label.copyWith(color: AppColors.forest)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            results.when<Widget>(
              skipLoadingOnReload: true,
              loading: () => SliverList.separated(
                itemCount: 4,
                separatorBuilder: (context, i) => const SizedBox(height: 12),
                itemBuilder: (context, i) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Skeleton(height: 124, radius: 16),
                ),
              ),
              error: (e, _) => const SliverToBoxAdapter(
                child: EmptyState(icon: Icons.wifi_off_rounded, title: 'Error de conexión', message: 'Intenta de nuevo.'),
              ),
              data: (list) => list.isEmpty
                  ? SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.grass_rounded,
                        title: 'Sin resultados',
                        message: 'Prueba con menos filtros o guarda la búsqueda para recibir una alerta.',
                        action: AgroButton(
                          label: 'Crear alerta',
                          icon: Icons.notifications_active_outlined,
                          expand: false,
                          tone: ButtonTone.lime,
                          onTap: () => showAgroSnack(context, 'Te avisaremos cuando aparezca algo compatible', emoji: '🔔'),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => FadeSlideIn(
                          key: ValueKey('s-${list[i].id}'),
                          delay: Duration(milliseconds: 35 * i),
                          child: ListingTile(
                            listing: list[i],
                            heroPrefix: 'search',
                            typeName: catalog.type(list[i].productTypeId).name,
                          ),
                        ),
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        ),
      ),
    );
  }
}

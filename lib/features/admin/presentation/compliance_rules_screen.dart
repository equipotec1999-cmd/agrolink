import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../catalog/data/catalog_repository.dart';
import '../data/compliance_rules_repository.dart';

/// Administración de reglas de cumplimiento (requisitos legales por tipo de producto, con fuente oficial).
class ComplianceRulesScreen extends ConsumerWidget {
  const ComplianceRulesScreen({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, {ComplianceRule? rule}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(21))),
      builder: (_) => _RuleForm(rule: rule),
    );
    if (saved == true) ref.invalidate(complianceRulesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, ComplianceRule rule) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('¿Eliminar regla?'),
        content: Text('"${rule.title}"'),
        actions: [
          TextButton(onPressed: () => Navigator.of(d).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(d).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(complianceRulesRepositoryProvider).delete(rule.id);
      ref.invalidate(complianceRulesProvider);
    } on ApiException catch (e) {
      if (context.mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(complianceRulesProvider);
    final catalog = ref.watch(catalogProvider);

    String scope(ComplianceRule r) {
      for (final t in catalog.productTypes) {
        if (t.backendId == r.productTypeId) return t.name;
      }
      for (final c in catalog.categories) {
        if (c.backendId == r.categoryId) return 'Categoría ${c.name}';
      }
      return '—';
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva regla'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
              child: Row(
                children: [
                  CircleIconButton(icon: Icons.arrow_back_rounded, background: AppColors.cream, onTap: () => context.pop()),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Reglas de cumplimiento', style: AppText.h1)),
                ],
              ),
            ),
            Expanded(
              child: rules.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.wifi_off_rounded, title: 'No pudimos cargar', message: '$e'),
                data: (items) => items.isEmpty
                    ? const EmptyState(
                        icon: Icons.gavel_rounded,
                        title: 'Sin reglas',
                        message: 'Agrega los requisitos legales por tipo de producto, citando la fuente oficial.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(complianceRulesProvider.future),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                          itemCount: items.length,
                          separatorBuilder: (context, i) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final r = items[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line, width: 1.2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(r.title, style: AppText.bodyStrong)),
                                      PopupMenuButton<String>(
                                        onSelected: (v) => v == 'edit' ? _openForm(context, ref, rule: r) : _delete(context, ref, r),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                                          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text('Aplica a: ${scope(r)}', style: AppText.muted),
                                  if (r.description != null && r.description!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(r.description!, style: AppText.muted.copyWith(color: AppColors.ink)),
                                  ],
                                  const SizedBox(height: 6),
                                  Text('Fuente: ${r.sourceName}', style: AppText.label),
                                  const SizedBox(height: 8),
                                  Wrap(spacing: 6, children: [
                                    if (r.documentRequired) const StatusPill(label: 'Documento requerido', color: AppColors.danger),
                                    if (!r.documentRequired && r.documentSuggested)
                                      const StatusPill(label: 'Documento sugerido', color: AppColors.honey),
                                  ]),
                                ],
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

class _RuleForm extends ConsumerStatefulWidget {
  const _RuleForm({this.rule});

  final ComplianceRule? rule;

  @override
  ConsumerState<_RuleForm> createState() => _RuleFormState();
}

class _RuleFormState extends ConsumerState<_RuleForm> {
  late final _title = TextEditingController(text: widget.rule?.title);
  late final _description = TextEditingController(text: widget.rule?.description);
  late final _source = TextEditingController(text: widget.rule?.sourceName);
  late final _url = TextEditingController(text: widget.rule?.sourceUrl);
  late int? _typeId = widget.rule?.productTypeId;
  late bool _suggested = widget.rule?.documentSuggested ?? false;
  late bool _required = widget.rule?.documentRequired ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _source.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().length < 3 || _source.text.trim().length < 2) {
      showAgroSnack(context, 'Título y fuente oficial son obligatorios', emoji: '⚠️');
      return;
    }
    if (_typeId == null && widget.rule?.categoryId == null) {
      showAgroSnack(context, 'Elige el tipo de producto', emoji: '⚠️');
      return;
    }
    final body = <String, dynamic>{
      if (_typeId != null) 'product_type_id': _typeId,
      'title': _title.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'source_name': _source.text.trim(),
      'source_url': _url.text.trim().isEmpty ? null : _url.text.trim(),
      'document_suggested': _suggested || _required,
      'document_required': _required,
    };
    setState(() => _saving = true);
    try {
      final repo = ref.read(complianceRulesRepositoryProvider);
      widget.rule == null ? await repo.create(body) : await repo.update(widget.rule!.id, body);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(catalogProvider).productTypes;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.rule == null ? 'Nueva regla' : 'Editar regla', style: AppText.h2),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: types.any((t) => t.backendId == _typeId) ? _typeId : null,
              decoration: const InputDecoration(labelText: 'Tipo de producto'),
              items: [for (final t in types) DropdownMenuItem(value: t.backendId, child: Text('${t.emoji} ${t.name}'))],
              onChanged: (v) => setState(() => _typeId = v),
            ),
            const SizedBox(height: 12),
            AgroTextField(label: 'Título', controller: _title),
            const SizedBox(height: 12),
            AgroTextField(label: 'Descripción', controller: _description, maxLines: 3),
            const SizedBox(height: 12),
            AgroTextField(label: 'Fuente oficial (SENASICA, SAT…)', controller: _source),
            const SizedBox(height: 12),
            AgroTextField(label: 'Enlace de la fuente', controller: _url, keyboardType: TextInputType.url),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Documento sugerido'),
              value: _suggested || _required,
              onChanged: _required ? null : (v) => setState(() => _suggested = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Documento requerido'),
              value: _required,
              onChanged: (v) => setState(() => _required = v),
            ),
            const SizedBox(height: 8),
            AgroButton(label: 'Guardar', icon: Icons.check_rounded, loading: _saving, onTap: _save),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/product_art.dart';
import '../../auth/application/auth_controller.dart';
import '../../verification/data/verification_repository.dart';
import '../data/moderation_repository.dart';

/// Pide un texto en un diálogo. Devuelve null si se cancela.
Future<String?> _askText(BuildContext context, {required String title, required String hint, bool required = true}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (dialog, setState) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 300,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: required && controller.text.trim().length < 3
                ? null
                : () => Navigator.of(dialog).pop(controller.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ),
  );
}

/// Sección de moderación (solo cuentas con permiso de moderar; el backend lo exige igual).
class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canDocs = ref.watch(authProvider)?.canReviewDocuments ?? false;
    return DefaultTabController(
      length: canDocs ? 3 : 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
                child: Row(
                  children: [
                    CircleIconButton(icon: Icons.arrow_back_rounded, background: AppColors.cream, onTap: () => context.pop()),
                    const SizedBox(width: 12),
                    const Text('Moderación', style: AppText.h1),
                  ],
                ),
              ),
              TabBar(tabs: [
                const Tab(text: 'Por revisar'),
                const Tab(text: 'Reportes'),
                if (canDocs) const Tab(text: 'Vendedores'),
              ]),
              Expanded(
                child: TabBarView(children: [
                  const _QueueTab(),
                  const _ReportsTab(),
                  if (canDocs) const _SellersTab(),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _run(BuildContext context, Future<void> Function() action, VoidCallback onDone, String okMessage) async {
  try {
    await action();
    onDone();
    if (context.mounted) showAgroSnack(context, okMessage, emoji: '✅');
  } on ApiException catch (e) {
    if (context.mounted) showAgroSnack(context, e.message, emoji: '⚠️');
  }
}

class _QueueTab extends ConsumerWidget {
  const _QueueTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(moderationQueueProvider);
    final repo = ref.read(moderationRepositoryProvider);

    return queue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.wifi_off_rounded, title: 'No pudimos cargar', message: '$e'),
      data: (items) => items.isEmpty
          ? const EmptyState(
              icon: Icons.verified_outlined,
              title: 'Todo revisado',
              message: 'No hay publicaciones pendientes de revisión.',
            )
          : RefreshIndicator(
              onRefresh: () => ref.refresh(moderationQueueProvider.future),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                itemCount: items.length,
                separatorBuilder: (context, i) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final it = items[i];
                  return _Card(
                    onOpen: () => context.push('/listing/${it.id}'),
                    leading: ProductArt(emoji: '📦', colorKey: '', imageUrl: it.coverUrl, radius: 14, emojiSize: 24),
                    title: it.title,
                    lines: [
                      '${formatMoney(it.price)} · ${it.seller}',
                      if (it.place.isNotEmpty) it.place,
                      if (it.openReports > 0) '🚩 ${it.openReports} reporte(s) abierto(s)',
                    ],
                    actions: [
                      Expanded(
                        child: AgroButton(
                          label: 'Rechazar',
                          tone: ButtonTone.light,
                          height: 44,
                          onTap: () async {
                            final reason = await _askText(context,
                                title: 'Motivo del rechazo', hint: 'Se le muestra al vendedor');
                            if (reason == null || !context.mounted) return;
                            await _run(context, () => repo.reject(it.id, reason),
                                () => ref.invalidate(moderationQueueProvider), 'Publicación rechazada');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AgroButton(
                          label: 'Aprobar',
                          tone: ButtonTone.lime,
                          height: 44,
                          onTap: () => _run(context, () => repo.approve(it.id),
                              () => ref.invalidate(moderationQueueProvider), 'Publicación aprobada'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(moderationReportsProvider);
    final repo = ref.read(moderationRepositoryProvider);

    Future<void> resolve(ReportItem r, ReportAction action, {required bool askNote}) async {
      String? note;
      if (askNote) {
        note = await _askText(context,
            title: action == ReportAction.hideListing ? 'Nota para el vendedor' : 'Nota',
            hint: 'Opcional', required: false);
        if (note == null || !context.mounted) return; // cancelado
      }
      await _run(context, () => repo.resolveReport(r.id, action, note: note),
          () => ref.invalidate(moderationReportsProvider), 'Reporte atendido');
    }

    return reports.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.wifi_off_rounded, title: 'No pudimos cargar', message: '$e'),
      data: (items) => items.isEmpty
          ? const EmptyState(icon: Icons.flag_outlined, title: 'Sin reportes', message: 'No hay reportes abiertos.')
          : RefreshIndicator(
              onRefresh: () => ref.refresh(moderationReportsProvider.future),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                itemCount: items.length,
                separatorBuilder: (context, i) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final r = items[i];
                  return _Card(
                    onOpen: r.listingId == null || r.listingStatus != 'published' ? null : () => context.push('/listing/${r.listingId}'),
                    leading: const Center(child: Text('🚩', style: TextStyle(fontSize: 26))),
                    title: r.reasonLabel,
                    lines: [
                      '«${r.listingTitle}» · ${r.seller}',
                      if (r.listingStatus.isNotEmpty && r.listingStatus != 'published') 'Estado: ${r.listingStatus}',
                      if (r.description != null && r.description!.isNotEmpty) r.description!,
                      'Reportó: ${r.reporter}',
                    ],
                    actions: [
                      Expanded(
                        child: AgroButton(
                          label: 'Descartar',
                          tone: ButtonTone.light,
                          height: 44,
                          onTap: () => resolve(r, ReportAction.dismiss, askNote: false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AgroButton(
                          label: 'Suspender',
                          tone: ButtonTone.lime,
                          height: 44,
                          onTap: () => resolve(r, ReportAction.hideListing, askNote: true),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _SellersTab extends ConsumerWidget {
  const _SellersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingVerificationsProvider);
    final repo = ref.read(verificationRepositoryProvider);

    return pending.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.wifi_off_rounded, title: 'No pudimos cargar', message: '$e'),
      data: (items) => items.isEmpty
          ? const EmptyState(
              icon: Icons.verified_user_outlined,
              title: 'Sin solicitudes',
              message: 'No hay vendedores esperando verificación.',
            )
          : RefreshIndicator(
              onRefresh: () => ref.refresh(pendingVerificationsProvider.future),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                itemCount: items.length,
                separatorBuilder: (context, i) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final v = items[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.userName, style: AppText.title),
                        Text(v.userEmail, style: AppText.muted.copyWith(fontSize: 12.5)),
                        if (v.businessName != null && v.businessName!.isNotEmpty)
                          Text('Negocio: ${v.businessName}', style: AppText.muted.copyWith(fontSize: 12.5)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final d in v.documents)
                              ActionChip(
                                label: Text(d.label),
                                avatar: const Icon(Icons.image_outlined, size: 18),
                                onPressed: () => _showDoc(context, repo, v.id, d),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: AgroButton(
                              label: 'Rechazar',
                              tone: ButtonTone.light,
                              height: 44,
                              onTap: () async {
                                final reason = await _askText(context,
                                    title: 'Motivo del rechazo', hint: 'Se le muestra al vendedor');
                                if (reason == null || !context.mounted) return;
                                await _run(context, () => repo.reject(v.id, reason),
                                    () => ref.invalidate(pendingVerificationsProvider), 'Solicitud rechazada');
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AgroButton(
                              label: 'Verificar',
                              tone: ButtonTone.lime,
                              height: 44,
                              onTap: () => _run(context, () => repo.approve(v.id),
                                  () => ref.invalidate(pendingVerificationsProvider), 'Vendedor verificado'),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _showDoc(BuildContext context, VerificationRepository repo, String reqId, VerificationDoc d) {
    return showDialog<void>(
      context: context,
      builder: (dialog) => Dialog(
        child: FutureBuilder(
          future: repo.documentBytes(reqId, d.id),
          builder: (c, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError || snap.data == null) {
              return const Padding(padding: EdgeInsets.all(24), child: Text('No se pudo abrir el documento.'));
            }
            return InteractiveViewer(child: Image.memory(snap.data!, fit: BoxFit.contain));
          },
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.leading, required this.title, required this.lines, required this.actions, this.onOpen});

  final Widget leading;
  final String title;
  final List<String> lines;
  final List<Widget> actions;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 56, height: 56, child: leading),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      for (final l in lines)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(l, style: AppText.muted.copyWith(fontSize: 12.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
                if (onOpen != null) const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: actions),
        ],
      ),
    );
  }
}

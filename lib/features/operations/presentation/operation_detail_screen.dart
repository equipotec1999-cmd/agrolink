import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/product_art.dart';
import '../data/operations_repository.dart';
import '../domain/operation.dart';

/// Seguimiento de una operación: resumen, línea de tiempo y el siguiente paso según mi rol.
class OperationDetailScreen extends ConsumerStatefulWidget {
  const OperationDetailScreen({super.key, required this.operationId});
  final String operationId;

  @override
  ConsumerState<OperationDetailScreen> createState() => _OperationDetailScreenState();
}

class _OperationDetailScreenState extends ConsumerState<OperationDetailScreen> {
  bool _busy = false;

  Color _color(OperationStatus s) => switch (s) {
        OperationStatus.cancelled || OperationStatus.dispute => AppColors.danger,
        OperationStatus.completed || OperationStatus.confirmed => AppColors.success,
        _ => AppColors.sky,
      };

  /// Texto del botón según quién soy y a qué estado pasa.
  String _label(Operation o, OperationStatus to) {
    final buyer = o.role == OperationRole.buyer;
    return switch (to) {
      OperationStatus.pendingPayment => 'Ya pagué',
      OperationStatus.paid => 'Confirmar pago recibido',
      OperationStatus.preparingDelivery => 'Estoy preparando la entrega',
      OperationStatus.inTransit => 'Marcar en camino',
      OperationStatus.delivered => 'Marcar como entregado',
      OperationStatus.completed => 'Confirmar que lo recibí',
      OperationStatus.cancelled => buyer ? 'Cancelar compra' : 'Cancelar venta',
      _ => to.label,
    };
  }

  /// Qué sigue, en una línea, para quien no tiene botón.
  String _hint(Operation o) {
    final buyer = o.role == OperationRole.buyer;
    return switch (o.status) {
      OperationStatus.offerAccepted => buyer ? 'Acuerda el pago con el vendedor y avisa cuando lo hagas.' : 'Esperando el pago del comprador.',
      OperationStatus.pendingPayment => buyer ? 'El vendedor debe confirmar que recibió tu pago.' : '',
      OperationStatus.paid || OperationStatus.preparingDelivery || OperationStatus.inTransit =>
        buyer ? 'El vendedor está preparando la entrega.' : '',
      OperationStatus.delivered => buyer ? '' : 'Esperando que el comprador confirme la recepción.',
      OperationStatus.completed => 'Operación cerrada.',
      OperationStatus.cancelled => 'Esta operación se canceló.',
      _ => '',
    };
  }

  Future<void> _go(Operation o, OperationStatus to) async {
    if (to == OperationStatus.cancelled) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('¿Cancelar la operación?'),
          content: const Text('Esto no se puede deshacer y se avisará a la otra persona.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Volver')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, cancelar')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(operationsRepositoryProvider).transition(o.id, to);
      ref.invalidate(operationDetailProvider(o.id));
      ref.invalidate(operationsProvider);
      if (mounted) showAgroSnack(context, 'Listo: ${to.label.toLowerCase()}');
    } catch (e) {
      if (mounted) showAgroSnack(context, '$e', emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rate(Operation o) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bone,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ReviewSheet(operation: o),
    );
    if (done == true) {
      ref.invalidate(operationDetailProvider(o.id));
      ref.invalidate(operationsProvider);
      if (mounted) showAgroSnack(context, 'Gracias por tu calificación');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(operationDetailProvider(widget.operationId));
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
                  Text('Operación #${widget.operationId}', style: AppText.h1),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(icon: Icons.wifi_off_rounded, title: 'No pudimos cargar', message: '$e'),
                data: (o) => RefreshIndicator(
                  onRefresh: () => ref.refresh(operationDetailProvider(widget.operationId).future),
                  child: _body(o),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(Operation o) {
    final qty = o.quantity.toStringAsFixed(o.quantity == o.quantity.roundToDouble() ? 0 : 2);
    final who = o.role == OperationRole.buyer ? 'Vendedor' : 'Comprador';
    final cancel = o.actions.where((a) => a == OperationStatus.cancelled).firstOrNull;
    final forward = o.actions.where((a) => a != OperationStatus.cancelled).toList();
    final hint = _hint(o);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line, width: 1.2),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: ProductArt(emoji: '📦', colorKey: '', imageUrl: o.coverUrl, radius: 18, emojiSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.listingTitle, style: AppText.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text('$who: ${o.counterpart}', style: AppText.muted.copyWith(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('$qty ${o.unit} · ${formatMoney(o.total)}', style: AppText.bodyStrong),
                    const SizedBox(height: 6),
                    StatusPill(label: o.status.label, color: _color(o.status)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (forward.isNotEmpty)
          for (final to in forward) ...[
            AgroButton(
              label: _label(o, to),
              tone: ButtonTone.lime,
              loading: _busy,
              onTap: _busy ? null : () => _go(o, to),
            ),
            const SizedBox(height: 8),
          ]
        else if (hint.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
            child: Text(hint, style: AppText.bodyText),
          ),
        if (o.canReview) ...[
          const SizedBox(height: 8),
          AgroButton(label: 'Calificar a ${o.counterpart}', icon: Icons.star_rounded, onTap: () => _rate(o)),
        ] else if (o.reviewed) ...[
          const SizedBox(height: 8),
          Text('Ya calificaste esta operación.', style: AppText.muted),
        ],
        const SizedBox(height: 8),
        AgroButton(
          label: 'Abrir conversación',
          tone: ButtonTone.light,
          icon: Icons.chat_bubble_outline_rounded,
          onTap: () => context.push('/chat/${o.conversationId}'),
        ),
        if (cancel != null)
          Center(
            child: TextButton(
              onPressed: _busy ? null : () => _go(o, cancel),
              child: Text(_label(o, cancel), style: AppText.bodyText.copyWith(color: AppColors.danger)),
            ),
          ),
        const SizedBox(height: 16),
        Text('Seguimiento', style: AppText.h3),
        const SizedBox(height: 8),
        for (final e in o.events.reversed) _EventRow(event: e, color: _color(e.status)),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.color});
  final OperationEvent event;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.status.label, style: AppText.bodyStrong),
                  if (event.note != null && event.note!.isNotEmpty) Text(event.note!, style: AppText.muted.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Text(timeAgo(event.at), style: AppText.muted.copyWith(fontSize: 11)),
          ],
        ),
      );
}

/// Calificación de la otra parte: el comprador evalúa al vendedor y el vendedor al comprador.
class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.operation});
  final Operation operation;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  final _comment = TextEditingController();
  final Map<String, int> _scores = {};
  bool _sending = false;
  String? _error;

  late final List<(String key, String label)> _axes = widget.operation.role == OperationRole.buyer
      ? const [('accuracy', 'Exactitud (lo que ofreció)'), ('fulfillment', 'Cumplimiento'), ('communication', 'Comunicación')]
      : const [('payment', 'Pago'), ('reception', 'Recepción'), ('communication', 'Comunicación')];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(operationsRepositoryProvider).review(widget.operation.id, _scores, _comment.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = _axes.every((a) => _scores.containsKey(a.$1));
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Califica a ${widget.operation.counterpart}', style: AppText.h2),
            const SizedBox(height: 12),
            for (final a in _axes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(a.$2, style: AppText.bodyText)),
                    for (var i = 1; i <= 5; i++)
                      GestureDetector(
                        onTap: () => setState(() => _scores[a.$1] = i),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            (_scores[a.$1] ?? 0) >= i ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 30,
                            color: AppColors.clay,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _comment,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Comentario (opcional)'),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: AppText.muted.copyWith(color: AppColors.danger))),
            AgroButton(label: 'Enviar calificación', loading: _sending, onTap: complete && !_sending ? _send : null),
          ],
        ),
      ),
    );
  }
}

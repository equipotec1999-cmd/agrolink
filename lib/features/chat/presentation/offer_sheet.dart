import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/product_art.dart';
import '../application/chat_controller.dart';
import '../domain/chat.dart';

/// Abre la hoja de oferta. Devuelve true si se envió.
Future<bool> showOfferSheet(BuildContext context, Conversation conversation) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(21))),
    builder: (_) => _OfferSheet(conversation: conversation),
  );
  return sent ?? false;
}

class _OfferSheet extends ConsumerStatefulWidget {
  const _OfferSheet({required this.conversation});
  final Conversation conversation;

  @override
  ConsumerState<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends ConsumerState<_OfferSheet> {
  // Precio y cantidad se pueden escribir a mano o ajustar con los botones.
  late final _amountCtrl = TextEditingController(text: _fmt((widget.conversation.listingPrice * 0.92 / 10).round() * 10.0));
  final _qtyCtrl = TextEditingController(text: '1');
  bool _sending = false;

  static String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double get _amount => double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
  double get _qty => double.tryParse(_qtyCtrl.text.replaceAll(',', '')) ?? 0;

  void _setAmount(double v) => setState(() => _amountCtrl.text = _fmt(v));
  void _setQty(double v) => setState(() => _qtyCtrl.text = _fmt(v));

  @override
  void dispose() {
    _amountCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  double get _list => widget.conversation.listingPrice;

  double _bound(double v, double step) => math.max(step, math.min(_list * 2, v));

  Future<void> _send(String conversationId) async {
    setState(() => _sending = true);
    final error = await ref.read(chatProvider.notifier).sendOffer(conversationId, _amount, _qty);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _sending = false);
      showAgroSnack(context, error, emoji: '⚠️');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    final discount = _list == 0 ? 0 : ((1 - _amount / _list) * 100).round();
    final step = _list >= 1000 ? 100.0 : (_list >= 100 ? 10.0 : 1.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 14, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(9)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: ProductArt(emoji: c.listingEmoji, colorKey: c.listingColorKey, imageUrl: c.listingCoverUrl, radius: 16, emojiSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.listingTitle, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Precio publicado: ${formatMoney(_list)} ${c.priceSuffix}', style: AppText.muted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('TU OFERTA', style: AppText.overline),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepButton(icon: Icons.remove_rounded, onTap: () => _setAmount(_bound(_amount - step, step))),
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: _amountCtrl,
                      onChanged: (_) => setState(() {}),
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      style: AppText.price.copyWith(fontSize: 38),
                      decoration: const InputDecoration(
                        prefixText: '\$ ',
                        isDense: true,
                        border: InputBorder.none,
                        hintText: '0',
                      ),
                    ),
                    Text(
                      discount > 0 ? '$discount% debajo del precio' : 'Igual o arriba del precio',
                      style: AppText.label.copyWith(color: discount > 0 ? AppColors.clay : AppColors.forest),
                    ),
                  ],
                ),
              ),
              _StepButton(icon: Icons.add_rounded, onTap: () => _setAmount(_bound(_amount + step, step))),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final pct in const [5, 10, 15])
                AgroChip(
                  dense: true,
                  label: '-$pct%',
                  selected: discount == pct,
                  onTap: () => _setAmount((_list * (100 - pct) / 100 / step).round() * step),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(child: Text('Cantidad', style: AppText.title)),
              _StepButton(icon: Icons.remove_rounded, small: true, onTap: () => _setQty(_qty > 1 ? _qty - 1 : 1)),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _qtyCtrl,
                  onChanged: (_) => setState(() {}),
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  style: AppText.h3,
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: '1'),
                ),
              ),
              _StepButton(icon: Icons.add_rounded, small: true, onTap: () => _setQty(_qty + 1)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total estimado: ${formatMoney(_amount * _qty)}  ·  Sin pagos dentro de la app por ahora.',
            style: AppText.muted.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 22),
          AgroButton(
            label: _sending ? 'Enviando…' : 'Enviar oferta',
            icon: Icons.local_offer_rounded,
            tone: ButtonTone.lime,
            onTap: (_sending || _amount <= 0 || _qty <= 0) ? null : () => _send(c.id),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap, this.small = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final s = small ? 38.0 : 52.0;
    return Pressable(
      scale: 0.88,
      onTap: onTap,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(s * 0.26),
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Icon(icon, color: AppColors.ink, size: small ? 18 : 24),
      ),
    );
  }
}

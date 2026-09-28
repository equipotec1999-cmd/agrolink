import 'dart:math' as math;

import 'package:flutter/material.dart';
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
  late double _amount = (widget.conversation.listingPrice * 0.92 / 10).round() * 10.0;
  double _qty = 1;

  double get _list => widget.conversation.listingPrice;

  double _bound(double v, double step) => math.max(step, math.min(_list * 2, v));

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
                child: ProductArt(emoji: c.listingEmoji, colorKey: c.listingColorKey, radius: 16, emojiSize: 28),
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
              _StepButton(icon: Icons.remove_rounded, onTap: () => setState(() => _amount = _bound(_amount - step, step))),
              Expanded(
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a),
                          child: child,
                        ),
                      ),
                      child: Text(
                        formatMoney(_amount),
                        key: ValueKey(_amount),
                        style: AppText.price.copyWith(fontSize: 38),
                      ),
                    ),
                    Text(
                      discount > 0 ? '$discount% debajo del precio' : 'Igual o arriba del precio',
                      style: AppText.label.copyWith(color: discount > 0 ? AppColors.clay : AppColors.forest),
                    ),
                  ],
                ),
              ),
              _StepButton(icon: Icons.add_rounded, onTap: () => setState(() => _amount = _bound(_amount + step, step))),
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
                  onTap: () => setState(() => _amount = (_list * (100 - pct) / 100 / step).round() * step),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(child: Text('Cantidad', style: AppText.title)),
              _StepButton(icon: Icons.remove_rounded, small: true, onTap: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1)),
              SizedBox(
                width: 54,
                child: Text(_qty.toStringAsFixed(0), textAlign: TextAlign.center, style: AppText.h3),
              ),
              _StepButton(icon: Icons.add_rounded, small: true, onTap: () => setState(() => _qty += 1)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total estimado: ${formatMoney(_amount * _qty)}  ·  Sin pagos dentro de la app por ahora.',
            style: AppText.muted.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 22),
          AgroButton(
            label: 'Enviar oferta',
            icon: Icons.local_offer_rounded,
            tone: ButtonTone.lime,
            onTap: () {
              ref.read(chatProvider.notifier).sendOffer(c.id, _amount, _qty);
              Navigator.of(context).pop(true);
            },
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

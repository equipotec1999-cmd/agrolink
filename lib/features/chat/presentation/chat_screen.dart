import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/product_art.dart';
import '../application/chat_controller.dart';
import '../domain/chat.dart';
import 'offer_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).markRead(widget.conversationId));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    ref.read(chatProvider.notifier).sendText(widget.conversationId, text);
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(conversationProvider(widget.conversationId));
    if (c == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Conversación no encontrada',
          message: 'Puede que haya sido archivada.',
        ),
      );
    }
    final messages = c.messages.reversed.toList();

    return Scaffold(
      body: Column(
        children: [
          _ChatHeader(conversation: c),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: messages.length + (c.typing ? 1 : 0),
              itemBuilder: (context, i) {
                if (c.typing && i == 0) return const _TypingBubble();
                final m = messages[c.typing ? i - 1 : i];
                return FadeSlideIn(
                  key: ValueKey(m.id),
                  offset: 12,
                  child: _MessageItem(conversation: c, message: m),
                );
              },
            ),
          ),
          _Composer(
            controller: _input,
            onSend: _send,
            onOffer: () => showOfferSheet(context, c),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.conversation});
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleIconButton(icon: Icons.arrow_back_rounded, background: AppColors.cream, onTap: () => context.pop()),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: AppColors.forest,
                    child: Text(
                      c.counterpart.substring(0, 1),
                      style: AppText.title.copyWith(color: AppColors.lime),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.counterpart, style: AppText.title, overflow: TextOverflow.ellipsis),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            c.typing ? 'escribiendo…' : 'Suele responder en ~1 h',
                            key: ValueKey(c.typing),
                            style: AppText.muted.copyWith(
                              fontSize: 12,
                              color: c.typing ? AppColors.forest : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.flag_outlined,
                    background: AppColors.cream,
                    size: 42,
                    onTap: () => showAgroSnack(context, 'Reporte de conducta: disponible en Fase 6', emoji: '🚩'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Pressable(
                scale: 0.98,
                onTap: () => context.push('/listing/${c.listingId}'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: ProductArt(emoji: c.listingEmoji, colorKey: c.listingColorKey, radius: 12, emojiSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.listingTitle, style: AppText.bodyStrong.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${formatMoney(c.listingPrice)} ${c.priceSuffix}', style: AppText.muted.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageItem extends ConsumerWidget {
  const _MessageItem({required this.conversation, required this.message});

  final Conversation conversation;
  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = message;
    if (m.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(100)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.handshake_rounded, color: AppColors.lime, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(m.text ?? '', style: AppText.label.copyWith(color: Colors.white, fontSize: 11.5)),
              ),
            ],
          ),
        ),
      );
    }

    final bubble = m.offer != null
        ? _OfferBubble(conversation: conversation, message: m)
        : Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: m.mine ? AppColors.forest : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(m.mine ? 22 : 6),
                bottomRight: Radius.circular(m.mine ? 6 : 22),
              ),
            ),
            child: Text(
              m.text ?? '',
              style: AppText.bodyText.copyWith(color: m.mine ? Colors.white : AppColors.ink),
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          bubble,
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 6, right: 6),
            child: Text(formatTime(m.at), style: AppText.muted.copyWith(fontSize: 10.5)),
          ),
        ],
      ),
    );
  }
}

class _OfferBubble extends ConsumerWidget {
  const _OfferBubble({required this.conversation, required this.message});

  final Conversation conversation;
  final ChatMessage message;

  Color _statusColor(OfferStatus s) => switch (s) {
        OfferStatus.accepted => AppColors.success,
        OfferStatus.rejected || OfferStatus.cancelled || OfferStatus.expired => AppColors.danger,
        OfferStatus.countered => AppColors.honey,
        OfferStatus.sent => AppColors.sky,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = message.offer!;
    final mine = message.mine;
    final ctrl = ref.read(chatProvider.notifier);
    final dark = mine;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.ink : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? AppColors.ink : AppColors.line, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer_rounded, size: 16, color: dark ? AppColors.lime : AppColors.forest),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  mine ? 'TU OFERTA' : 'CONTRAOFERTA',
                  style: AppText.overline.copyWith(color: dark ? Colors.white60 : AppColors.muted),
                ),
              ),
              StatusPill(label: offer.status.label, color: _statusColor(offer.status)),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: formatMoney(offer.amount),
                style: AppText.price.copyWith(color: dark ? AppColors.bone : AppColors.ink, fontSize: 26),
              ),
              TextSpan(
                text: ' ${conversation.priceSuffix}',
                style: AppText.muted.copyWith(color: dark ? Colors.white60 : AppColors.muted),
              ),
            ]),
          ),
          Text(
            '× ${offer.quantity.toStringAsFixed(0)}  ·  Total ${formatMoney(offer.amount * offer.quantity)}',
            style: AppText.muted.copyWith(fontSize: 12, color: dark ? Colors.white60 : AppColors.muted),
          ),
          if (offer.status.isOpen) ...[
            const SizedBox(height: 14),
            if (mine)
              AgroButton(
                label: 'Cancelar oferta',
                tone: ButtonTone.light,
                height: 44,
                onTap: () => ctrl.respond(conversation.id, message.id, OfferStatus.cancelled),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: AgroButton(
                      label: 'Rechazar',
                      tone: ButtonTone.light,
                      height: 44,
                      onTap: () => ctrl.respond(conversation.id, message.id, OfferStatus.rejected),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AgroButton(
                      label: 'Aceptar',
                      tone: ButtonTone.lime,
                      height: 44,
                      onTap: () => ctrl.respond(conversation.id, message.id, OfferStatus.accepted),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line, width: 1.2)),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.translate(
                  offset: Offset(0, -4 * _wave(_c.value, i)),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.4 + 0.6 * _wave(_c.value, i)),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _wave(double t, int i) {
    final x = (t - i * 0.18) % 1.0;
    return x < 0.5 ? x * 2 : (1 - x) * 2;
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend, required this.onOffer});

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Pressable(
                scale: 0.88,
                onTap: onOffer,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(18)),
                  child: const Row(
                    children: [
                      Icon(Icons.local_offer_rounded, color: AppColors.ink, size: 18),
                      SizedBox(width: 6),
                      Text('Oferta', style: AppText.label),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onSend(),
                  textInputAction: TextInputAction.send,
                  style: AppText.bodyStrong,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje…',
                    hintStyle: AppText.muted,
                    filled: true,
                    fillColor: AppColors.cream,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleIconButton(
                icon: Icons.arrow_upward_rounded,
                background: AppColors.ink,
                color: AppColors.lime,
                size: 50,
                onTap: onSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

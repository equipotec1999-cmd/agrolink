import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../../../shared/widgets/product_art.dart';
import '../../moderation/data/moderation_repository.dart';
import '../../moderation/presentation/report_sheet.dart';
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
  /// Reportar a la otra persona de la conversación: motivo + descripción obligatoria.
  Future<void> _reportUser(Conversation c) async {
    final id = c.counterpartId;
    if (id == null) {
      showAgroSnack(context, 'No pudimos identificar al usuario.', emoji: '⚠️');
      return;
    }
    final result = await showReportSheet(context, title: 'Reportar a ${c.counterpart}');
    if (result == null || !mounted) return;
    final (reason, description) = result;
    try {
      await ref.read(moderationRepositoryProvider).reportUser(id, reason, description: description);
      if (mounted) showAgroSnack(context, 'Reporte enviado', emoji: '🚩');
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    }
  }

  static const _pollEvery = Duration(seconds: 4);

  final _input = TextEditingController();
  late final ChatController _chat = ref.read(chatProvider.notifier);
  Timer? _poll;
  bool _firstLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _chat.setOpen(widget.conversationId);
    Future.microtask(_firstLoad);
    // Polling: pide solo los mensajes nuevos (after_id) y, de paso, el servidor
    // marca como leídos los de la otra persona.
    _poll = Timer.periodic(_pollEvery, (_) => _chat.loadMessages(widget.conversationId));
  }

  Future<void> _firstLoad() async {
    final ok = await _chat.loadMessages(widget.conversationId);
    if (mounted) setState(() => _firstLoadFailed = !ok);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _chat.setOpen(null);
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _chat.sendText(widget.conversationId, text);
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
          _ChatHeader(conversation: c, onReport: () => _reportUser(c)),
          Expanded(
            child: !c.messagesLoaded
                ? (_firstLoadFailed
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('No pudimos cargar los mensajes.', style: AppText.muted),
                              const SizedBox(height: 12),
                              AgroButton(label: 'Reintentar', tone: ButtonTone.light, height: 44, onTap: _firstLoad),
                            ],
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()))
                : messages.isEmpty
                    ? const Center(child: Text('Escribe el primer mensaje 👋', style: AppText.muted))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          return FadeSlideIn(
                            key: ValueKey(m.id),
                            offset: 12,
                            child: _MessageItem(
                              conversation: c,
                              message: m,
                              onRetry: () => _chat.retry(widget.conversationId, m.id),
                            ),
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
  const _ChatHeader({required this.conversation, required this.onReport});
  final Conversation conversation;
  final VoidCallback onReport;

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
                      c.counterpart.isEmpty ? '?' : c.counterpart.substring(0, 1),
                      style: AppText.title.copyWith(color: AppColors.lime),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.counterpart, style: AppText.title, overflow: TextOverflow.ellipsis),
                        Text('Sobre una publicación', style: AppText.muted.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.flag_outlined,
                    background: AppColors.cream,
                    size: 42,
                    onTap: onReport,
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
                        child: ProductArt(emoji: c.listingEmoji, colorKey: c.listingColorKey, imageUrl: c.listingCoverUrl, radius: 12, emojiSize: 22),
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

class _MessageItem extends StatelessWidget {
  const _MessageItem({required this.conversation, required this.message, required this.onRetry});

  final Conversation conversation;
  final ChatMessage message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final m = message;

    final bubble = m.offer != null
        ? _OfferBubble(conversation: conversation, message: m)
        : Opacity(
      opacity: m.pending ? 0.6 : 1,
      child: Container(
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
          m.text,
          style: AppText.bodyText.copyWith(color: m.mine ? Colors.white : AppColors.ink),
        ),
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
            child: m.failed
                ? GestureDetector(
                    onTap: onRetry,
                    child: Text(
                      'No se envió · toca para reintentar',
                      style: AppText.muted.copyWith(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w700),
                    ),
                  )
                : Text(m.pending ? 'Enviando…' : formatTime(m.at), style: AppText.muted.copyWith(fontSize: 10.5)),
          ),
        ],
      ),
    );
  }
}

class _OfferBubble extends ConsumerStatefulWidget {
  const _OfferBubble({required this.conversation, required this.message});

  final Conversation conversation;
  final ChatMessage message;

  @override
  ConsumerState<_OfferBubble> createState() => _OfferBubbleState();
}

class _OfferBubbleState extends ConsumerState<_OfferBubble> {
  bool _busy = false;

  Color _statusColor(OfferStatus s) => switch (s) {
        OfferStatus.accepted => AppColors.success,
        OfferStatus.rejected || OfferStatus.cancelled || OfferStatus.expired => AppColors.danger,
        OfferStatus.countered => AppColors.honey,
        OfferStatus.sent => AppColors.sky,
      };

  Future<void> _respond(String action) async {
    setState(() => _busy = true);
    final error = await ref
        .read(chatProvider.notifier)
        .respondOffer(widget.conversation.id, widget.message.offer!.id, action);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) showAgroSnack(context, error, emoji: '⚠️');
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.message.offer!;
    final mine = widget.message.mine;
    final dark = mine;

    // Una oferta abierta cuyo plazo ya pasó se ve vencida sin esperar al servidor.
    final expired = offer.status.isOpen && offer.expiresAt != null && offer.expiresAt!.isBefore(DateTime.now());
    final status = expired ? OfferStatus.expired : offer.status;

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
                  mine ? 'TU OFERTA' : 'OFERTA RECIBIDA',
                  style: AppText.overline.copyWith(color: dark ? Colors.white60 : AppColors.muted),
                ),
              ),
              StatusPill(label: status.label, color: _statusColor(status)),
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
                text: ' ${widget.conversation.priceSuffix}',
                style: AppText.muted.copyWith(color: dark ? Colors.white60 : AppColors.muted),
              ),
            ]),
          ),
          Text(
            '× ${offer.quantity.toStringAsFixed(0)}  ·  Total ${formatMoney(offer.total)}',
            style: AppText.muted.copyWith(fontSize: 12, color: dark ? Colors.white60 : AppColors.muted),
          ),
          if (status == OfferStatus.accepted && offer.operationId != null) ...[
            const SizedBox(height: 10),
            Text(
              'Operación #${offer.operationId} creada',
              style: AppText.label.copyWith(color: dark ? AppColors.lime : AppColors.forest, fontSize: 12),
            ),
          ],
          if (status.isOpen) ...[
            const SizedBox(height: 14),
            if (_busy)
              const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)))
            else if (mine)
              AgroButton(
                label: 'Cancelar oferta',
                tone: ButtonTone.light,
                height: 44,
                onTap: () => _respond('cancel'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: AgroButton(label: 'Rechazar', tone: ButtonTone.light, height: 44, onTap: () => _respond('reject')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AgroButton(label: 'Aceptar', tone: ButtonTone.lime, height: 44, onTap: () => _respond('accept')),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
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

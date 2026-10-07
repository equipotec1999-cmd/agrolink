import 'dart:async';

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

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
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
          _ChatHeader(conversation: c),
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
                              message: m,
                              onRetry: () => _chat.retry(widget.conversationId, m.id),
                            ),
                          );
                        },
                      ),
          ),
          _Composer(controller: _input, onSend: _send),
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
  const _MessageItem({required this.message, required this.onRetry});

  final ChatMessage message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final m = message;

    final bubble = Opacity(
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

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

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

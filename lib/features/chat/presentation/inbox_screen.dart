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

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    // Al entrar a la pestaña se refresca de inmediato (además del refresco periódico).
    Future.microtask(() => ref.read(chatProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final list = chat.conversations;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text('Mensajes', style: AppText.h1),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Cada conversación está ligada a una publicación.', style: AppText.muted),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: list.isEmpty && chat.loading
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty && chat.error != null
                      ? EmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'No pudimos cargar tus mensajes',
                          message: chat.error!,
                        )
                      : list.isEmpty
                  ? const EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Sin conversaciones',
                      message: 'Cuando contactes a un vendedor, la plática aparecerá aquí.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(chatProvider.notifier).refresh(),
                      child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                      itemCount: list.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => FadeSlideIn(
                        delay: Duration(milliseconds: 50 * i),
                        child: _ConversationTile(conversation: list[i]),
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

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final lastAt = c.lastAt;
    return Pressable(
      scale: 0.98,
      onTap: () => context.push('/chat/${c.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line, width: 1.2)),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: ProductArt(emoji: c.listingEmoji, colorKey: c.listingColorKey, imageUrl: c.listingCoverUrl, radius: 18, emojiSize: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(c.counterpart, style: AppText.title, overflow: TextOverflow.ellipsis)),
                      if (lastAt != null) Text(timeAgo(lastAt), style: AppText.muted.copyWith(fontSize: 11)),
                    ],
                  ),
                  Text(
                    c.listingTitle,
                    style: AppText.label.copyWith(color: AppColors.forest, fontSize: 11.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastText == null ? 'Nueva conversación' : '${c.lastMine ? 'Tú: ' : ''}${c.lastText}',
                          style: AppText.muted.copyWith(
                            fontSize: 12.5,
                            color: c.unread > 0 ? AppColors.ink : AppColors.muted,
                            fontWeight: c.unread > 0 ? FontWeight.w700 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (c.unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(10)),
                          child: Text('${c.unread}', style: AppText.label.copyWith(fontSize: 11)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

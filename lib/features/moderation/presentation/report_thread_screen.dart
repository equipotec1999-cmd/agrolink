import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../auth/application/auth_controller.dart';

/// Mostrar el hilo del chat (read-only) relacionado a un reporte para valorarlo.
class ReportThreadScreen extends ConsumerStatefulWidget {
  const ReportThreadScreen({super.key, required this.reportId});
  final String reportId;

  @override
  ConsumerState<ReportThreadScreen> createState() => _ReportThreadScreenState();
}

class _ReportThreadScreenState extends ConsumerState<ReportThreadScreen> {
  late Future<List<_Thread>> _future = _load();

  Future<List<_Thread>> _load() async {
    final client = ref.read(apiClientProvider);
    final response = await client.get('/moderation/reports/${widget.reportId}/thread') as Map<String, dynamic>;
    return (response['data'] as List<dynamic>).map((raw) => _Thread.fromJson(raw as Map<String, dynamic>)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat del reporte')),
      body: FutureBuilder<List<_Thread>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EmptyState(icon: Icons.wifi_off_rounded, title: 'No pudimos cargar', message: '${snap.error}');
          }
          final threads = snap.data ?? [];
          if (threads.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Sin chat',
              message: 'No hay conversación entre estas personas.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: threads.length,
            itemBuilder: (context, i) {
              final t = threads[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (threads.length > 1 || (t.listingTitle ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${t.buyer.name} ↔ ${t.seller.name}${t.listingTitle == null ? '' : ' · «${t.listingTitle}»'}',
                      style: AppText.title,
                    ),
                    const SizedBox(height: 10),
                  ],
                  for (final m in t.messages) _MessageBubble(message: m, buyer: t.buyer, seller: t.seller),
                  const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.buyer, required this.seller});
  final _Msg message;
  final _Who buyer;
  final _Who seller;

  @override
  Widget build(BuildContext context) {
    final sender = message.senderId == buyer.id ? buyer : seller;
    final isOffer = message.offerAmount != null;
    final bg = sender.id == buyer.id ? AppColors.cream : AppColors.lime.withValues(alpha: 0.35);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sender.name, style: AppText.label.copyWith(color: AppColors.ink, fontSize: 12)),
          const SizedBox(height: 4),
          if (isOffer)
            Text('🏷️ Oferta: \$${message.offerAmount!.toStringAsFixed(2)} (${message.offerStatus ?? ''})', style: AppText.bodyStrong)
          else
            Text(message.body ?? '', style: AppText.bodyText),
        ],
      ),
    );
  }
}

class _Thread {
  _Thread({required this.id, required this.buyer, required this.seller, required this.messages, this.listingTitle});
  final int id;
  final String? listingTitle;
  final _Who buyer;
  final _Who seller;
  final List<_Msg> messages;

  factory _Thread.fromJson(Map<String, dynamic> j) => _Thread(
        id: j['id'] as int,
        listingTitle: j['listing_title'] as String?,
        buyer: _Who.fromJson(j['buyer'] as Map<String, dynamic>),
        seller: _Who.fromJson(j['seller'] as Map<String, dynamic>),
        messages: ((j['messages'] as List<dynamic>?) ?? const [])
            .map((m) => _Msg.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

class _Who {
  _Who({required this.id, required this.name});
  final int id;
  final String name;
  factory _Who.fromJson(Map<String, dynamic> j) => _Who(id: j['id'] as int, name: '${j['name'] ?? 'Usuario'}');
}

class _Msg {
  _Msg({required this.id, required this.senderId, this.body, this.offerAmount, this.offerStatus});
  final int id;
  final int senderId;
  final String? body;
  final double? offerAmount;
  final String? offerStatus;
  factory _Msg.fromJson(Map<String, dynamic> j) => _Msg(
        id: j['id'] as int,
        senderId: j['sender_id'] as int,
        body: j['body'] as String?,
        offerAmount: j['offer_amount'] == null ? null : double.tryParse('${j['offer_amount']}'),
        offerStatus: j['offer_status'] as String?,
      );
}

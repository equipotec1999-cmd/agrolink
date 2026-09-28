import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';

class AppNotification {
  const AppNotification(this.emoji, this.title, this.body, this.when, this.route, {this.unread = false});
  final String emoji;
  final String title;
  final String body;
  final String when;
  final String route;
  final bool unread;
}

// ⚠️ MOCK: en Fase 4 -> GET /api/v1/notifications + push (FCM).
const _mock = [
  AppNotification('🔔', 'Nueva coincidencia', 'Tu alerta "borregos 35–50 kg" encontró 1 publicación.', 'hace 12 min', '/listing/l3', unread: true),
  AppNotification('🏷️', 'Contraoferta recibida', 'Marisol Chan respondió con \$2,650 por animal.', 'hace 1 h', '/chat/c2', unread: true),
  AppNotification('📉', 'Bajó de precio', 'Miel multifloral de tajonal ahora a \$78/kg.', 'ayer', '/listing/l4'),
  AppNotification('🛡️', 'Documento verificado', 'La constancia de vacunación de "Relámpago" fue verificada.', 'hace 2 días', '/listing/l1'),
];

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 20, 40),
          children: [
            Row(
              children: [
                CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                const SizedBox(width: 14),
                const Text('Notificaciones', style: AppText.h1),
              ],
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < _mock.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: 60 * i),
                child: Pressable(
                  scale: 0.98,
                  onTap: () => context.push(_mock[i].route),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10, left: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _mock[i].unread ? Colors.white : AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _mock[i].unread ? Colors.white : AppColors.line),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(16)),
                          child: Text(_mock[i].emoji, style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(_mock[i].title, style: AppText.title)),
                                  if (_mock[i].unread)
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(color: AppColors.clay, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(_mock[i].body, style: AppText.muted),
                              const SizedBox(height: 6),
                              Text(_mock[i].when, style: AppText.muted.copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
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

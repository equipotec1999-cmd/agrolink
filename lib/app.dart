import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/application/chat_controller.dart';
import 'features/notifications/application/notifications_controller.dart';

class AgroLinkApp extends ConsumerStatefulWidget {
  const AgroLinkApp({super.key});

  @override
  ConsumerState<AgroLinkApp> createState() => _AgroLinkAppState();
}

class _AgroLinkAppState extends ConsumerState<AgroLinkApp> {
  @override
  void initState() {
    super.initState();
    ref.read(pushServiceProvider)?.listen(
      // Llegó un push con la app abierta: se refresca sin esperar al ciclo de polling.
      onForeground: () {
        ref.read(notificationsProvider.notifier).refresh();
        ref.read(chatProvider.notifier).refresh();
      },
      onOpen: (route) => ref.read(routerProvider).push(route),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'AgroLink',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

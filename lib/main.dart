import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/network/token_storage.dart';
import 'core/push/push_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/data/api_auth_repository.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/catalog/data/api_catalog_repository.dart';
import 'features/catalog/data/catalog_repository.dart';
import 'features/catalog/domain/catalog.dart';
import 'features/chat/data/chat_repository.dart';
import 'features/favorites/data/favorites_repository.dart';
import 'features/listings/data/api_listing_repository.dart';
import 'features/moderation/data/moderation_repository.dart';
import 'features/notifications/data/notifications_repository.dart';
import 'features/operations/data/operations_repository.dart';
import 'features/listings/data/listing_repository.dart';
import 'shared/widgets/agrolink_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Algo en pantalla desde el primer frame: las dos llamadas de abajo pueden
  // tardar (o fallar por red) y antes la app se quedaba en NEGRO mientras tanto.
  runApp(const _BootLoadingApp());

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final catalogRepository = ApiCatalogRepository(apiClient);
  final authRepository = ApiAuthRepository(apiClient, tokenStorage);

  // Push: si Firebase no está configurado (falta google-services.json) la app sigue
  // sin avisos push en vez de fallar al arrancar.
  PushService? pushService;
  try {
    await Firebase.initializeApp();
    pushService = PushService(apiClient);
  } catch (_) {}

  try {
    // Dos llamadas al arrancar, antes de mostrar cualquier pantalla: el catálogo (lo
    // necesita casi toda la app) y, si había un token guardado, confirmar que sigue
    // siendo válido (GET /api/me) para no pedir login de nuevo innecesariamente.
    final results = await Future.wait([
      catalogRepository.load(),
      authRepository.restoreSession(),
    ]);
    final catalog = results[0] as Catalog;
    final restoredUser = results[1] as AppUser?;
    // Necesita el catálogo ya resuelto (traduce id numérico <-> slug), por eso
    // se construye hasta aquí y no junto a los otros repos arriba.
    final listingRepository = ApiListingRepository(apiClient, catalog);

    runApp(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(catalogRepository),
          catalogProvider.overrideWithValue(catalog),
          authRepositoryProvider.overrideWithValue(authRepository),
          initialAuthUserProvider.overrideWithValue(restoredUser),
          listingRepositoryProvider.overrideWithValue(listingRepository),
          favoritesRepositoryProvider.overrideWithValue(ApiFavoritesRepository(apiClient)),
          // "Mis" mensajes se decide con el usuario de la sesión actual, que cambia
          // al hacer login/logout; por eso se lee del provider en cada llamada.
          pushServiceProvider.overrideWithValue(pushService),
          moderationRepositoryProvider.overrideWithValue(ApiModerationRepository(apiClient)),
          operationsRepositoryProvider.overrideWithValue(ApiOperationsRepository(apiClient)),
          notificationsRepositoryProvider.overrideWithValue(ApiNotificationsRepository(apiClient)),
          chatRepositoryProvider.overrideWith(
            (ref) => ApiChatRepository(apiClient, catalog, myId: () => ref.read(authProvider)!.id),
          ),
        ],
        child: const AgroLinkApp(),
      ),
    );
  } catch (error) {
    // Sin la API no hay app útil que mostrar (el catálogo es la base de casi todo);
    // en vez de una pantalla en blanco o un crash, un error claro con reintento.
    runApp(_BootErrorApp(
      error: error,
      onRetry: main,
    ));
  }
}

class _BootErrorApp extends StatelessWidget {
  const _BootErrorApp({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AgroLinkMark(size: 96, color: AppColors.bone),
                const SizedBox(height: 22),
                Text(
                  'No pudimos conectar con AgroLink',
                  style: AppText.h3.copyWith(color: AppColors.bone),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '$error',
                  style: AppText.muted.copyWith(color: AppColors.bone.withValues(alpha: 0.6)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Colores explícitos: esta pantalla se arma ANTES del tema de la
                // app (por eso antes salía el morado default de Material).
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lime,
                    foregroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pantalla de carga mientras se conecta con la API al arrancar. Se arma antes
/// del tema de la app, por eso usa colores explícitos.
class _BootLoadingApp extends StatelessWidget {
  const _BootLoadingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AgroLinkMark(size: 140, color: AppColors.bone),
              const SizedBox(height: 28),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bone.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 14),
              Text(
                'Conectando…',
                style: AppText.muted.copyWith(color: AppColors.bone.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

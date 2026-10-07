import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/push/push_service.dart';
import '../data/auth_repository.dart';

enum UserIntent { buy, sell, both }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.intent,
    this.canModerate = false,
    this.twoFactorEnabled = false,
    this.twoFactorRequired = false,
    this.canManageRules = false,
    this.phone,
    this.emailVerified = false,
    this.sellerVerified = false,
    this.canReviewDocuments = false,
  });
  final int id;
  final String name;
  final String email;
  final String? phone;
  final bool emailVerified;

  /// Vendedor verificado (insignia) y permiso de revisar solicitudes de verificación.
  final bool sellerVerified;
  final bool canReviewDocuments;
  final UserIntent intent;

  /// El backend le dio permiso de moderar: se muestra la sección de moderación.
  final bool canModerate;

  /// Verificación en dos pasos activa / obligatoria para esta cuenta (permisos administrativos).
  final bool twoFactorEnabled;
  final bool twoFactorRequired;

  /// Puede administrar las reglas de cumplimiento.
  final bool canManageRules;

  String get firstName => name.split(' ').first;
}

/// Usuario restaurado (si había un token válido guardado) antes de levantar la app —
/// se resuelve en main.dart y se inyecta aquí para que AuthController arranque ya
/// "logueado" sin que la UI tenga que esperar una llamada async extra al abrir.
final initialAuthUserProvider = Provider<AppUser?>((ref) => null);

/// Delegar en AuthRepository (real contra la API, o uno de prueba) para que este
/// controller solo se encargue de manejar el estado, no de cómo se autentica.
class AuthController extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    final restored = ref.read(initialAuthUserProvider);
    // Sesión restaurada al abrir la app: se re-registra el token push (puede haber rotado).
    if (restored != null) Future.microtask(_registerPush);
    return restored;
  }

  void _registerPush() => ref.read(pushServiceProvider)?.register();

  Future<void> login(String email, String password) async {
    state = await ref.read(authRepositoryProvider).login(email, password);
    _registerPush();
  }

  /// Segundo paso del inicio de sesión (cuentas con verificación en dos pasos).
  Future<void> completeTwoFactor(String challengeToken, {String? code, String? recoveryCode}) async {
    state = await ref
        .read(authRepositoryProvider)
        .completeTwoFactor(challengeToken, code: code, recoveryCode: recoveryCode);
    _registerPush();
  }

  /// Vuelve a pedir el usuario al servidor (p. ej. tras activar/desactivar la verificación en dos pasos).
  Future<void> refreshUser() async {
    final fresh = await ref.read(authRepositoryProvider).restoreSession();
    if (fresh != null) state = fresh;
  }

  Future<void> register(String name, String email, String password, UserIntent intent) async {
    state = await ref.read(authRepositoryProvider).register(name, email, password, intent);
    _registerPush();
  }

  Future<void> logout() async {
    // Antes de cerrar sesión: el backend necesita el token de sesión para olvidar este celular.
    await ref.read(pushServiceProvider)?.unregister();
    await ref.read(authRepositoryProvider).logout();
    state = null;
  }
}

final authProvider = NotifierProvider<AuthController, AppUser?>(AuthController.new);

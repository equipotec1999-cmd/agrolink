import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';

/// Contrato de autenticación. La UI (login/register screens) solo conoce esto, nunca
/// si hay un token Sanctum real detrás o datos de prueba.
abstract interface class AuthRepository {
  Future<AppUser> login(String email, String password);
  Future<AppUser> register(String name, String email, String password, UserIntent intent);
  Future<void> logout();

  /// Si hay un token guardado y sigue siendo válido (GET /api/me responde bien), regresa
  /// el usuario para restaurar la sesión al abrir la app; si no, null (hay que iniciar sesión).
  Future<AppUser?> restoreSession();
}

/// Se sobreescribe en main.dart con ApiAuthRepository antes de levantar la app.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError('authRepositoryProvider debe sobreescribirse en main.dart'),
);

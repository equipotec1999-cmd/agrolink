import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';

/// El login fue correcto pero la cuenta pide un código de la app autenticadora.
/// Resultado de /register: la cuenta se creó pero necesita confirmar un código
/// enviado al correo o teléfono. El token completo llega en /verify-contact.
class ContactVerificationRequired implements Exception {
  const ContactVerificationRequired({required this.channel, required this.destination});
  final String channel; // 'email' | 'sms'
  final String destination;
}

class TwoFactorRequired implements Exception {
  TwoFactorRequired(this.challengeToken);
  final String challengeToken;

  @override
  String toString() => 'Se requiere verificación en dos pasos';
}

/// Contrato de autenticación. La UI (login/register screens) solo conoce esto, nunca
/// si hay un token Sanctum real detrás o datos de prueba.
abstract interface class AuthRepository {
  /// Lanza [TwoFactorRequired] si la cuenta tiene verificación en dos pasos.
  Future<AppUser> login(String email, String password);
  Future<AppUser> completeTwoFactor(String challengeToken, {String? code, String? recoveryCode});
  /// Registra una cuenta. Lanza [ContactVerificationRequired] con el canal (email|sms)
  /// y el destino al que se mandó el código. El token completo llega en [verifyContact].
  Future<void> register(String name, String password, UserIntent intent,
      {String? email, String? phone, String? lastname, String channel = 'email'});

  /// Confirma el código enviado al correo/teléfono y devuelve el usuario con sesión.
  Future<AppUser> verifyContact({required String destination, required String code});

  Future<void> resendVerification(String destination);
  Future<void> logout();

  /// Si hay un token guardado y sigue siendo válido (GET /api/me responde bien), regresa
  /// el usuario para restaurar la sesión al abrir la app; si no, null (hay que iniciar sesión).
  Future<AppUser?> restoreSession();
}

/// Se sobreescribe en main.dart con ApiAuthRepository antes de levantar la app.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError('authRepositoryProvider debe sobreescribirse en main.dart'),
);

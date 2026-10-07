import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage.dart';
import '../application/auth_controller.dart';
import 'auth_repository.dart';

/// Implementación real contra Laravel + Sanctum (POST /api/login, /api/register,
/// /api/logout, GET /api/me). Guarda el token en TokenStorage (cifrado) al iniciar
/// sesión y lo borra al cerrarla.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  @override
  Future<AppUser> login(String email, String password) async {
    final json = await _client.post(
      '/login',
      withAuth: false,
      body: {
        'email': email,
        'password': password,
        // Sanctum nombra el token con esto (útil para "cerrar sesión en otros dispositivos"
        // más adelante); no es un identificador de seguridad por sí solo.
        'device_name': 'agrolink-android',
      },
    );
    if (json['requires_two_factor'] == true) {
      throw TwoFactorRequired(json['challenge_token'] as String);
    }
    await _tokenStorage.save(json['token'] as String);
    return _userFromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<AppUser> completeTwoFactor(String challengeToken, {String? code, String? recoveryCode}) async {
    final json = await _client.post(
      '/two-factor/challenge',
      bearer: challengeToken,
      body: {
        if (code != null) 'code': code,
        if (recoveryCode != null) 'recovery_code': recoveryCode,
      },
    );
    await _tokenStorage.save(json['token'] as String);
    return _userFromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<AppUser> register(String name, String email, String password, UserIntent intent) async {
    final json = await _client.post(
      '/register',
      withAuth: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
    await _tokenStorage.save(json['token'] as String);
    return _userFromJson(json['user'] as Map<String, dynamic>, intent: intent);
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post('/logout');
    } on ApiException {
      // Si el token ya no era válido, no importa: igual lo borramos localmente.
    } on SocketException {
      // Sin conexión: cerramos sesión localmente de todos modos.
    }
    await _tokenStorage.clear();
  }

  @override
  Future<AppUser?> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null) return null;

    try {
      final response = await _client.get('/me') as Map<String, dynamic>;
      // A diferencia de /login y /register (donde el UserResource va embebido
      // en un array manual y por eso NO se envuelve), aquí el controller regresa
      // el Resource directo como respuesta raíz, así que Laravel SÍ lo envuelve
      // en {"data": {...}} por el comportamiento default de JsonResource.
      final json = response['data'] as Map<String, dynamic>;
      return _userFromJson(json);
    } catch (_) {
      // Token vencido/revocado o sin conexión al abrir la app: mejor pedir login de nuevo
      // que dejar a alguien "atorado" en un estado de sesión que ya no sirve.
      await _tokenStorage.clear();
      return null;
    }
  }

  AppUser _userFromJson(Map<String, dynamic> json, {UserIntent intent = UserIntent.both}) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      emailVerified: json['email_verified'] == true,
      intent: intent,
      canModerate: json['can_moderate'] == true,
      twoFactorEnabled: json['two_factor_enabled'] == true,
      twoFactorRequired: json['two_factor_required'] == true,
      canManageRules: json['can_manage_rules'] == true,
    );
  }
}

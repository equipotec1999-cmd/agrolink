import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el token de Sanctum cifrado (Android Keystore / iOS Keychain), nunca en
/// SharedPreferences plano — es una credencial real, no una preferencia de UI.
class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'agrolink_auth_token';

  Future<void> save(String token) => _storage.write(key: _key, value: token);

  Future<String?> read() => _storage.read(key: _key);

  Future<void> clear() => _storage.delete(key: _key);
}

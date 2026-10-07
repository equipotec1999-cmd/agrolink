import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class TwoFactorSetup {
  const TwoFactorSetup({required this.secret, required this.otpauthUrl});
  final String secret;
  final String otpauthUrl;
}

abstract interface class TwoFactorRepository {
  /// Paso 1: el servidor genera el secreto (aún sin activar).
  Future<TwoFactorSetup> setup();

  /// Paso 2: con un código válido se activa; devuelve los códigos de recuperación (se ven una sola vez).
  Future<List<String>> confirm(String code);

  Future<void> disable({required String password, String? code, String? recoveryCode});
}

final twoFactorRepositoryProvider = Provider<TwoFactorRepository>(
  (ref) => throw UnimplementedError('twoFactorRepositoryProvider debe sobreescribirse en main.dart'),
);

class ApiTwoFactorRepository implements TwoFactorRepository {
  ApiTwoFactorRepository(this._client);

  final ApiClient _client;

  @override
  Future<TwoFactorSetup> setup() async {
    final json = await _client.post('/two-factor/setup') as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    return TwoFactorSetup(secret: '${data['secret']}', otpauthUrl: '${data['otpauth_url']}');
  }

  @override
  Future<List<String>> confirm(String code) async {
    final json = await _client.post('/two-factor/confirm', body: {'code': code}) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    return (data['recovery_codes'] as List<dynamic>).map((c) => '$c').toList();
  }

  @override
  Future<void> disable({required String password, String? code, String? recoveryCode}) async {
    await _client.post('/two-factor/disable', body: {
      'password': password,
      if (code != null && code.isNotEmpty) 'code': code,
      if (recoveryCode != null && recoveryCode.isNotEmpty) 'recovery_code': recoveryCode,
    });
  }
}

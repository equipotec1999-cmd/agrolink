import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

abstract interface class AccountRepository {
  Future<void> updateProfile({required String name, String? phone});
  Future<void> changePassword({required String current, required String next});
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => throw UnimplementedError('accountRepositoryProvider debe sobreescribirse en main.dart'),
);

class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> updateProfile({required String name, String? phone}) async {
    await _client.patch('/me', body: {'name': name, 'phone': (phone == null || phone.isEmpty) ? null : phone});
  }

  @override
  Future<void> changePassword({required String current, required String next}) async {
    await _client.post('/me/password', body: {
      'current_password': current,
      'password': next,
      'password_confirmation': next,
    });
  }
}

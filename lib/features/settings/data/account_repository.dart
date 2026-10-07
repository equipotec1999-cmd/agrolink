import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/application/auth_controller.dart';

/// Cifras reales del perfil. `rating` es null mientras no haya operaciones completadas.
class ProfileStats {
  const ProfileStats({required this.listings, required this.sales, required this.purchases, this.rating});
  final int listings;
  final int sales;
  final int purchases;
  final double? rating;
}

abstract interface class AccountRepository {
  Future<ProfileStats> stats();
  Future<void> updateProfile({required String name, String? phone});
  Future<void> changePassword({required String current, required String next});
}

final profileStatsProvider = FutureProvider.autoDispose<ProfileStats>((ref) {
  // Depende de la sesión: al cambiar de usuario se vuelve a pedir.
  ref.watch(authProvider);
  return ref.watch(accountRepositoryProvider).stats();
});

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => throw UnimplementedError('accountRepositoryProvider debe sobreescribirse en main.dart'),
);

class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository(this._client);

  final ApiClient _client;

  @override
  Future<ProfileStats> stats() async {
    final r = await _client.get('/me/stats') as Map<String, dynamic>;
    final d = r['data'] as Map<String, dynamic>;
    return ProfileStats(
      listings: int.tryParse('${d['listings']}') ?? 0,
      sales: int.tryParse('${d['sales']}') ?? 0,
      purchases: int.tryParse('${d['purchases']}') ?? 0,
      rating: double.tryParse('${d['rating']}'),
    );
  }

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

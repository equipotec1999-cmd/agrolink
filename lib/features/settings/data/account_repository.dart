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

/// Datos editables del perfil. Null = "no cambiar"; cadena vacía = "borrar".
class ProfileEdit {
  const ProfileEdit({this.name, this.lastname, this.phone, this.bio, this.state, this.municipality});
  final String? name;
  final String? lastname;
  final String? phone;
  final String? bio;
  final String? state;
  final String? municipality;
}

abstract interface class AccountRepository {
  Future<ProfileStats> stats();

  /// Actualiza el perfil y devuelve el usuario fresco (con avatar_url, bio, lugar...).
  Future<AppUser> updateProfile(ProfileEdit edit);
  Future<void> changePassword({required String current, required String next});

  /// Sube el avatar (ruta local del archivo). Devuelve el usuario con la URL ya resuelta.
  Future<AppUser> uploadAvatar(String path);
  Future<AppUser> removeAvatar();
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
  Future<AppUser> updateProfile(ProfileEdit edit) async {
    // Solo manda los campos presentes; "" significa borrar (lastname, bio, teléfono...).
    final body = <String, dynamic>{
      if (edit.name != null) 'name': edit.name,
      if (edit.lastname != null) 'lastname': edit.lastname!.isEmpty ? null : edit.lastname,
      if (edit.phone != null) 'phone': edit.phone!.isEmpty ? null : edit.phone,
      if (edit.bio != null) 'bio': edit.bio!.isEmpty ? null : edit.bio,
      if (edit.state != null) 'state': edit.state!.isEmpty ? null : edit.state,
      if (edit.municipality != null) 'municipality': edit.municipality!.isEmpty ? null : edit.municipality,
    };
    final r = await _client.patch('/me', body: body) as Map<String, dynamic>;
    return _userFromJson(r['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({required String current, required String next}) async {
    await _client.post('/me/password', body: {
      'current_password': current,
      'password': next,
      'password_confirmation': next,
    });
  }

  @override
  Future<AppUser> uploadAvatar(String path) async {
    final r = await _client.postMultipartForm('/me/avatar', files: {'avatar': path}) as Map<String, dynamic>;
    return _userFromJson(r['data'] as Map<String, dynamic>);
  }

  @override
  Future<AppUser> removeAvatar() async {
    final r = await _client.delete('/me/avatar') as Map<String, dynamic>;
    return _userFromJson(r['data'] as Map<String, dynamic>);
  }

  AppUser _userFromJson(Map<String, dynamic> json) {
    final profile = (json['profile'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      lastname: json['lastname'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      emailVerified: json['email_verified'] == true,
      sellerVerified: json['seller_verified'] == true,
      canReviewDocuments: json['can_review_documents'] == true,
      intent: UserIntent.both,
      canModerate: json['can_moderate'] == true,
      twoFactorEnabled: json['two_factor_enabled'] == true,
      twoFactorRequired: json['two_factor_required'] == true,
      canManageRules: json['can_manage_rules'] == true,
      bio: profile['bio'] as String?,
      state: profile['state'] as String?,
      municipality: profile['municipality'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
    );
  }
}

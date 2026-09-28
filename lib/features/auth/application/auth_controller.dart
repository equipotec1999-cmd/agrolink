import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

enum UserIntent { buy, sell, both }

class AppUser {
  const AppUser({required this.id, required this.name, required this.email, required this.intent});
  final int id;
  final String name;
  final String email;
  final UserIntent intent;

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
  AppUser? build() => ref.read(initialAuthUserProvider);

  Future<void> login(String email, String password) async {
    state = await ref.read(authRepositoryProvider).login(email, password);
  }

  Future<void> register(String name, String email, String password, UserIntent intent) async {
    state = await ref.read(authRepositoryProvider).register(name, email, password, intent);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = null;
  }
}

final authProvider = NotifierProvider<AuthController, AppUser?>(AuthController.new);

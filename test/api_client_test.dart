import 'dart:convert';

import 'package:agrolink/core/network/api_client.dart';
import 'package:agrolink/core/network/api_exception.dart';
import 'package:agrolink/core/network/token_storage.dart';
import 'package:agrolink/features/auth/data/api_auth_repository.dart';
import 'package:agrolink/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<void> save(String t) async => token = t;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> clear() async => token = null;
}

http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  late FakeTokenStorage storage;

  setUp(() => storage = FakeTokenStorage());

  ApiClient clientWith(MockClient mock) =>
      ApiClient(tokenStorage: storage, baseUrl: 'http://test/api', client: mock);

  group('ApiClient', () {
    test('manda el token guardado como Bearer', () async {
      storage.token = 'abc';
      late http.Request seen;
      final api = clientWith(MockClient((req) async {
        seen = req;
        return jsonResponse({'ok': true});
      }));

      await api.get('/me');

      expect(seen.headers['Authorization'], 'Bearer abc');
      expect(seen.url.toString(), 'http://test/api/me');
    });

    test('un token explícito pisa al guardado (paso 2 de la verificación)', () async {
      storage.token = 'guardado';
      late http.Request seen;
      final api = clientWith(MockClient((req) async {
        seen = req;
        return jsonResponse({});
      }));

      await api.post('/two-factor/challenge', bearer: 'pendiente', body: {'code': '123456'});

      expect(seen.headers['Authorization'], 'Bearer pendiente');
      expect(jsonDecode(seen.body), {'code': '123456'});
    });

    test('sin sesión no manda Authorization', () async {
      late http.Request seen;
      final api = clientWith(MockClient((req) async {
        seen = req;
        return jsonResponse({});
      }));

      await api.post('/login', withAuth: false);

      expect(seen.headers.containsKey('Authorization'), isFalse);
    });

    test('un 422 de Laravel se convierte en el primer mensaje de validación', () async {
      final api = clientWith(MockClient((_) async => jsonResponse({
            'message': 'The given data was invalid.',
            'errors': {
              'email': ['Correo o contraseña incorrectos.'],
            },
          }, 422)));

      expect(
        () => api.post('/login'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Correo o contraseña incorrectos.')
            .having((e) => e.isValidation, 'isValidation', isTrue)),
      );
    });

    test('un 401 se marca como no autorizado', () async {
      final api = clientWith(MockClient((_) async => jsonResponse({'message': 'Unauthenticated.'}, 401)));

      expect(() => api.get('/me'), throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)));
    });

    test('un 204 sin cuerpo no truena', () async {
      final api = clientWith(MockClient((_) async => http.Response('', 204)));

      expect(await api.delete('/algo'), isNull);
    });
  });

  group('ApiAuthRepository', () {
    test('login normal guarda el token y regresa el usuario', () async {
      final api = clientWith(MockClient((_) async => jsonResponse({
            'token': 'tok',
            'user': {'id': 1, 'name': 'Ana', 'email': 'ana@x.com', 'can_moderate': true, 'two_factor_enabled': false},
          })));
      final repo = ApiAuthRepository(api, storage);

      final user = await repo.login('ana@x.com', 'Secreta123');

      expect(storage.token, 'tok');
      expect(user.name, 'Ana');
      expect(user.canModerate, isTrue);
    });

    test('con verificación en dos pasos lanza TwoFactorRequired y NO guarda token', () async {
      final api = clientWith(MockClient((_) async => jsonResponse({'requires_two_factor': true, 'challenge_token': 'pend'})));
      final repo = ApiAuthRepository(api, storage);

      await expectLater(
        repo.login('ana@x.com', 'Secreta123'),
        throwsA(isA<TwoFactorRequired>().having((e) => e.challengeToken, 'challengeToken', 'pend')),
      );
      expect(storage.token, isNull);
    });

    test('completar la verificación manda el token pendiente y guarda el completo', () async {
      late http.Request seen;
      final api = clientWith(MockClient((req) async {
        seen = req;
        return jsonResponse({
          'token': 'completo',
          'user': {'id': 1, 'name': 'Ana', 'email': 'ana@x.com', 'two_factor_enabled': true, 'two_factor_required': true},
        });
      }));
      final repo = ApiAuthRepository(api, storage);

      final user = await repo.completeTwoFactor('pend', code: '123456');

      expect(seen.headers['Authorization'], 'Bearer pend');
      expect(storage.token, 'completo');
      expect(user.twoFactorEnabled, isTrue);
      expect(user.twoFactorRequired, isTrue);
    });

    test('restaurar sesión con token vencido limpia el token', () async {
      storage.token = 'viejo';
      final api = clientWith(MockClient((_) async => jsonResponse({'message': 'Unauthenticated.'}, 401)));
      final repo = ApiAuthRepository(api, storage);

      expect(await repo.restoreSession(), isNull);
      expect(storage.token, isNull);
    });
  });
}

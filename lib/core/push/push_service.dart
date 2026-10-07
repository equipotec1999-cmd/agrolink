import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

/// Notificaciones push (Firebase Cloud Messaging). Es null cuando Firebase no está
/// configurado (sin `google-services.json`): la app funciona igual, solo sin push.
/// Se sobreescribe en main.dart.
final pushServiceProvider = Provider<PushService?>((ref) => null);

class PushService {
  PushService(this._client);

  final ApiClient _client;
  String? _token;
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openSub;
  Future<void>? _initialLoad;
  String? _pendingRoute;

  /// Pide permiso (Android 13+ muestra el diálogo del sistema), obtiene el token del
  /// celular y se lo manda al backend. Nunca lanza: sin push la app sigue funcionando.
  Future<void> register() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token == null) return;
      _token = token;
      await _send(token);

      // FCM puede rotar el token; el backend debe enterarse.
      _refreshSub ??= messaging.onTokenRefresh.listen((t) {
        _token = t;
        _send(t);
      });
    } catch (_) {}
  }

  Future<void> _send(String token) async {
    try {
      await _client.post('/devices', body: {'token': token, 'platform': 'android'});
    } catch (_) {}
  }

  /// Al cerrar sesión (con el token de sesión aún válido): este celular deja de recibir
  /// push de la cuenta y se descarta el token de FCM (se genera otro al volver a entrar).
  Future<void> unregister() async {
    final token = _token;
    try {
      if (token != null) await _client.post('/devices/unregister', body: {'token': token});
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _token = null;
    await _refreshSub?.cancel();
    _refreshSub = null;
  }

  /// Engancha lo que pasa cuando llega o se toca un push.
  /// [onForeground]: llegó con la app abierta (Android no muestra aviso del sistema).
  /// [onOpen]: el usuario tocó el aviso con la app en segundo plano.
  void listen({required void Function() onForeground, required void Function(String route) onOpen}) {
    _foregroundSub ??= FirebaseMessaging.onMessage.listen((_) => onForeground());
    _openSub ??= FirebaseMessaging.onMessageOpenedApp.listen((m) {
      final route = _routeOf(m);
      if (route != null) onOpen(route);
    });
    // Si la app estaba CERRADA y se abrió tocando el aviso, la ruta espera al splash.
    _initialLoad ??= FirebaseMessaging.instance.getInitialMessage().then((m) {
      if (m != null) _pendingRoute = _routeOf(m);
    }).catchError((_) {});
  }

  /// Ruta de la notificación con la que se abrió la app (una sola vez).
  Future<String?> takePendingRoute() async {
    await _initialLoad;
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  String? _routeOf(RemoteMessage m) {
    final conversation = m.data['conversation_id'];
    return (conversation is String && conversation.isNotEmpty) ? '/chat/$conversation' : null;
  }
}

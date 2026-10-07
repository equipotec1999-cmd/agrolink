import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Envoltorio delgado sobre `package:http`: agrega el token Bearer si hay sesión,
/// decodifica JSON, y convierte cualquier respuesta de error de Laravel (422 de
/// validación, 401, 404, 500...) en un ApiException con mensaje listo para UI.
/// Deliberadamente NO usa Dio: no necesitamos interceptores/cancelación compleja
/// todavía y `http` ya cubre JSON + multipart (Fase 5, subir fotos) sin dependencia extra.
class ApiClient {
  ApiClient({required this.tokenStorage, String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? Env.apiBaseUrl,
        _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  // Sin límite, si el servidor no es alcanzable (otra red WiFi, firewall, IP
  // equivocada) la petición se queda colgada minutos y la app parece congelada.
  static const _timeout = Duration(seconds: 15);
  static const _uploadTimeout = Duration(seconds: 90);

  /// Ejecuta la petición con tiempo límite y convierte los fallos de red en un
  /// ApiException con un mensaje que se entiende (en vez del SocketException crudo).
  Future<http.Response> _send(Future<http.Response> Function() request, {Duration? timeout}) async {
    try {
      return await request().timeout(timeout ?? _timeout);
    } on TimeoutException {
      throw ApiException(
        'El servidor no respondió a tiempo ($baseUrl). Revisa que el backend esté '
        'corriendo y que el celular esté en la misma red WiFi que la PC.',
      );
    } on http.ClientException catch (e) {
      // package:http envuelve aquí los SocketException (sin red, conexión rechazada…).
      throw ApiException('No se pudo conectar con el servidor ($baseUrl): ${e.message}');
    }
  }

  Future<Map<String, String>> _headers({bool withAuth = true, String? bearer}) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (bearer != null) {
      // Token explícito (p. ej. el token pendiente del paso de verificación en dos pasos).
      headers['Authorization'] = 'Bearer $bearer';
    } else if (withAuth) {
      final token = await tokenStorage.read();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
    final headers = await _headers();
    final response = await _send(() => _client.get(uri, headers: headers));
    return _decode(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool withAuth = true, String? bearer}) async {
    final headers = await _headers(withAuth: withAuth, bearer: bearer);
    final response = await _send(() => _client.post(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: jsonEncode(body ?? {}),
        ));
    return _decode(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    final response = await _send(() => _client.put(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: jsonEncode(body ?? {}),
        ));
    return _decode(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    final response = await _send(() => _client.patch(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: jsonEncode(body ?? {}),
        ));
    return _decode(response);
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    final response = await _send(() => _client.delete(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ));
    return _decode(response);
  }

  /// Sube un archivo (multipart/form-data) — usado para subir fotos de
  /// publicaciones. No reutiliza `_headers()` tal cual porque el
  /// Content-Type de multipart lo arma `http` solo (con su boundary).
  Future<dynamic> postMultipart(String path, {required String fieldName, required String filePath}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    final headers = await _headers();
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    final response = await _send(
      () async => http.Response.fromStream(await _client.send(request)),
      timeout: _uploadTimeout,
    );
    return _decode(response);
  }

  /// Varios campos y archivos en una sola petición multipart (p. ej. documentos de verificación).
  Future<dynamic> postMultipartForm(
    String path, {
    Map<String, String> fields = const {},
    Map<String, String> files = const {},
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    final headers = await _headers();
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    request.fields.addAll(fields);
    for (final e in files.entries) {
      request.files.add(await http.MultipartFile.fromPath(e.key, e.value));
    }

    final response = await _send(
      () async => http.Response.fromStream(await _client.send(request)),
      timeout: _uploadTimeout,
    );
    return _decode(response);
  }

  /// Descarga un archivo binario (p. ej. un documento de verificación) con la sesión actual.
  Future<Uint8List> getBytes(String path) async {
    final headers = await _headers();
    final response = await _send(() => _client.get(Uri.parse('$baseUrl$path'), headers: headers), timeout: _uploadTimeout);
    if (response.statusCode >= 200 && response.statusCode < 300) return response.bodyBytes;
    _decode(response); // lanza el ApiException con el mensaje de Laravel
    throw ApiException('No se pudo descargar el archivo (${response.statusCode}).', statusCode: response.statusCode);
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final map = body is Map<String, dynamic> ? body : <String, dynamic>{};
    final errors = map['errors'] as Map<String, dynamic>?;
    final firstError = errors?.values.first is List ? (errors!.values.first as List).first as String? : null;

    throw ApiException(
      firstError ?? map['message'] as String? ?? 'Ocurrió un error inesperado (${response.statusCode}).',
      statusCode: response.statusCode,
      errors: errors,
    );
  }
}

/// Error de red/API con el mensaje que ya viene listo para mostrarle al usuario
/// (tomado de `message` o del primer error de `errors` que manda Laravel en un 422).
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  bool get isValidation => statusCode == 422;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

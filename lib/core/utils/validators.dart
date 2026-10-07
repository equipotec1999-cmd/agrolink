/// Validaciones de cliente (solo UX). El backend SIEMPRE vuelve a validar.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? notEmpty(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Escribe tu correo';
    if (!_emailRegex.hasMatch(v.trim())) return 'Correo no válido';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Escribe tu contraseña';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  /// Para registro: debe calzar con la regla real del backend
  /// (Password::min(8)->mixedCase()->numbers() en RegisterRequest), para no dejar que el
  /// usuario llene el formulario y se entere del rechazo hasta que la API responda.
  static String? newPassword(String? v) {
    final base = password(v);
    if (base != null) return base;
    if (!RegExp(r'[a-z]').hasMatch(v!) || !RegExp(r'[A-Z]').hasMatch(v)) {
      return 'Usa mayúsculas y minúsculas';
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Incluye al menos un número';
    return null;
  }

  /// Teléfono MX: 10 dígitos (puede traer +52, espacios, guiones). El servidor vuelve a validar.
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Escribe tu teléfono';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 15) return 'Teléfono no válido';
    return null;
  }

  static String? positiveNumber(String? v) {
    final n = double.tryParse((v ?? '').replaceAll(',', ''));
    if (n == null || n <= 0) return 'Ingresa un número mayor a 0';
    return null;
  }
}

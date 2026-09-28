/// Configuración de entorno. La URL de la API se puede sobreescribir sin tocar código:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api
///
/// Default: 10.0.2.2 es cómo el EMULADOR de Android ve el "localhost" de tu máquina
/// (no funciona en un celular físico; ahí usa la IP de tu red local con --dart-define).
class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
}

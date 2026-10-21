/// Configuración de entorno. La URL de la API se puede sobreescribir sin tocar código:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api
///
/// Default: la API desplegada en Render. Para probar contra tu máquina desde el EMULADOR de
/// Android usa `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api` (en un celular físico,
/// la IP de tu red local).
class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://agrolink-api-wug5.onrender.com/api',
  );
}

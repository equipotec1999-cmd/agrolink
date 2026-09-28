import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

/// Envoltorio delgado sobre `geolocator`: pide permiso solo cuando hace falta
/// (publicar, o calcular distancia real en el feed) y nunca truena la app si
/// el usuario lo niega o el GPS está apagado — regresa null y quien llama
/// decide qué mostrar (Fase 1 §6: la app funciona sin compartir ubicación,
/// solo se degrada la precisión de "distancia").
class DeviceLocation {
  /// Intenta obtener la posición actual. Pide permiso si aún no se ha
  /// concedido; si se niega, se deniega para siempre, o el servicio de
  /// ubicación del teléfono está apagado, regresa null en vez de lanzar.
  static Future<Position?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
    } catch (_) {
      return null;
    }
  }

  /// Última posición conocida, sin pedir permiso ni prender el GPS — para no
  /// interrumpir con un diálogo de permiso solo por ver el feed. Si nunca se
  /// concedió permiso (p.ej. el usuario nunca ha publicado), regresa null.
  static Future<Position?> lastKnown() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// Distancia en línea recta (km) por la fórmula de Haversine.
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // radio de la Tierra en km
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180);
}

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Datos de dirección obtenidos de unas coordenadas.
class PlaceInfo {
  const PlaceInfo({this.state, this.municipality, this.postalCode});
  final String? state;
  final String? municipality;
  final String? postalCode;
}

/// Geocodificación inversa con OpenStreetMap (Nominatim): no necesita llaves ni plugins nativos.
/// Si no hay red o no responde en 8 s regresa null y el usuario escribe los datos a mano.
Future<PlaceInfo?> reverseGeocode(double lat, double lng) async {
  try {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': '$lat',
      'lon': '$lng',
      'zoom': '14',
      'addressdetails': '1',
      'accept-language': 'es',
    });
    final res = await http
        .get(uri, headers: {'User-Agent': 'AgroLink/1.0 (mx.agrolink)'})
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final a = (jsonDecode(res.body) as Map<String, dynamic>)['address'] as Map<String, dynamic>?;
    if (a == null) return null;
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = a[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    return PlaceInfo(
      state: pick(['state']),
      // En México Nominatim pone el municipio en "municipality"/"county"; si no, la localidad.
      municipality: pick(['municipality', 'county', 'city', 'town', 'village']),
      postalCode: pick(['postcode']),
    );
  } catch (_) {
    return null;
  }
}

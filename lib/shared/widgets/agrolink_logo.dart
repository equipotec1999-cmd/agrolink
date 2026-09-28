import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Logo oficial de AgroLink (emblema: abeja, toro/caballo, gallo y planta sobre
/// surcos, dentro del sello circular). Los PNG en assets/brand/ son BLANCOS con
/// transparencia, así que se tiñen del color que toque: tinta sobre fondo claro,
/// hueso sobre fondo oscuro.
abstract final class BrandAssets {
  static const emblem = 'assets/brand/logo_emblem.png';
  static const wordmark = 'assets/brand/logo_wordmark.png';
  static const full = 'assets/brand/logo_full.png';
}

Widget _tinted(String asset, {double? height, double? width, required Color color}) {
  return Image.asset(
    asset,
    height: height,
    width: width,
    color: color,
    colorBlendMode: BlendMode.srcIn,
    filterQuality: FilterQuality.medium,
    // Si por algo el asset no está (p.ej. no se corrió `flutter pub get` tras
    // actualizar pubspec), que no truene la pantalla: un hueco del mismo tamaño.
    errorBuilder: (context, error, stack) => SizedBox(height: height, width: width),
  );
}

/// Isotipo (solo el emblema). `size` es la ALTURA; el ancho sale de la proporción.
class AgroLinkMark extends StatelessWidget {
  const AgroLinkMark({super.key, this.size = 48, this.color = AppColors.ink});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _tinted(BrandAssets.emblem, height: size, color: color);
}

/// Logotipo (letras "AGROLINK" grabadas). `size` es la ALTURA de las letras.
class AgroLinkWordmark extends StatelessWidget {
  const AgroLinkWordmark({super.key, this.size = 26, this.color = AppColors.ink});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _tinted(BrandAssets.wordmark, height: size, color: color);
}

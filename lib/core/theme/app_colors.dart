import 'package:flutter/material.dart';

/// Paleta AgroLink (rediseño rústico): grises cálidos tipo papel/piedra + verdes
/// de monte apagados. Los nombres de los campos se conservan para no romper
/// ninguna pantalla; lo que cambió son los valores.
abstract final class AppColors {
  // LITE: paleta INVERTIDA respecto a la oficial (fondo oscuro, texto claro) para que se
  // note de un vistazo que es la versión Lite. Los nombres de los campos son los mismos.
  static const text = Color(0xFFECEAE4); // texto principal (antes oscuro, ahora claro)
  static const ink = Color(0xFF2B3A31); // paneles / botones oscuros sobre el fondo
  static const forest = Color(0xFF5E9272); // primario: verde monte más claro para fondo oscuro
  static const leaf = Color(0xFF86A98F);
  static const lime = Color(0xFFC9D4B8);
  static const bone = Color(0xFFE9E4D8);
  static const honey = Color(0xFFCDAE72);
  static const clay = Color(0xFFC98468);
  static const sky = Color(0xFF8AA7B7);
  static const cream = Color(0xFF121714); // fondo
  static const sand = Color(0xFF232B26);
  static const surface = Color(0xFF1C231F); // tarjetas
  static const muted = Color(0xFFA3AAA2);
  static const line = Color(0xFF35403A);
  static const danger = Color(0xFFE0766A);
  static const success = Color(0xFF6BAE79);
}

/// Colores por categoría raíz. La categoría llega del backend con un `colorKey`;
/// aquí solo se traduce a colores (la UI nunca decide lógica por nombre de categoría).
/// Cada categoría conserva un acento cálido TENUE para poder distinguirlas de un
/// vistazo, pero todo dentro de la gama gris/verde.
class CategoryPalette {
  const CategoryPalette(this.soft, this.strong, this.deep);
  final Color soft;
  final Color strong;
  final Color deep;
}

CategoryPalette paletteFor(String colorKey) {
  switch (colorKey) {
    case 'animales':
      return const CategoryPalette(Color(0xFF6E5A48), Color(0xFFC2AE9A), Color(0xFFE7E1D9));
    case 'apicultura':
      return const CategoryPalette(Color(0xFF6F6036), Color(0xFFC8B78A), Color(0xFFE9E4D2));
    case 'agricultura':
      return const CategoryPalette(Color(0xFF3F5A45), Color(0xFFA7B597), Color(0xFFDFE4D8));
    default:
      return const CategoryPalette(Color(0xFF3B5444), Color(0xFFB3B9B0), Color(0xFFE4E6E1));
  }
}

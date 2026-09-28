import 'package:flutter/material.dart';

/// Paleta AgroLink (rediseño rústico): grises cálidos tipo papel/piedra + verdes
/// de monte apagados. Los nombres de los campos se conservan para no romper
/// ninguna pantalla; lo que cambió son los valores.
abstract final class AppColors {
  static const ink = Color(0xFF1E2420); // carbón con tinte verde (texto / superficies oscuras)
  static const forest = Color(0xFF3B5444); // primario: verde monte apagado
  static const leaf = Color(0xFF5E7A64);
  // "lime" era el acento neón; ahora es un salvia pálido. Se usa sobre fondos
  // oscuros (chips seleccionados, navbar) y como fondo de badges.
  static const lime = Color(0xFFC9D4B8);
  static const bone = Color(0xFFE9E4D8); // hueso: emblemas/logo sobre fondo oscuro
  static const honey = Color(0xFFB8975A); // ocre apagado
  static const clay = Color(0xFFA8674A); // terracota apagada
  static const sky = Color(0xFF6A8595); // pizarra
  static const cream = Color(0xFFECEAE4); // fondo: gris cálido tipo papel
  static const sand = Color(0xFFDEDAD1);
  static const surface = Color(0xFFF7F6F2); // tarjetas
  static const muted = Color(0xFF6C716B);
  static const line = Color(0xFFD2CEC4);
  // Rojo/verde de estado se quedan: son funcionales (error/éxito), no decorativos.
  static const danger = Color(0xFFB04A3F);
  static const success = Color(0xFF4C7A55);
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
      return const CategoryPalette(Color(0xFFE7E1D9), Color(0xFFC2AE9A), Color(0xFF6E5A48));
    case 'apicultura':
      return const CategoryPalette(Color(0xFFE9E4D2), Color(0xFFC8B78A), Color(0xFF6F6036));
    case 'agricultura':
      return const CategoryPalette(Color(0xFFDFE4D8), Color(0xFFA7B597), Color(0xFF3F5A45));
    default:
      return const CategoryPalette(Color(0xFFE4E6E1), Color(0xFFB3B9B0), Color(0xFF3B5444));
  }
}

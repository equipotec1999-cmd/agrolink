import 'package:flutter/material.dart';

/// Símbolos oficiales de la marca para las categorías y tipos de producto del
/// catálogo (PNG blanco con transparencia en assets/brand/glyphs/; se tiñen en
/// código al color que toque). Sustituyen a los emojis de colores.
///
/// La clave es el `icono` que manda el backend. 'bee' (que usan la categoría
/// Apicultura y el tipo Núcleos) se muestra como panal; 'crown' (Abeja reina)
/// como la abeja con corona.
const _glyphAssets = {
  'cow': 'cow', 'horse': 'horse', 'sheep': 'sheep', 'goat': 'goat', 'pig': 'pig', // animales
  'hive': 'hive', 'bee': 'comb', 'crown': 'crown', 'honey': 'honey', // apicultura
  'chili': 'chili', 'fruit': 'fruit', 'leaf': 'leaf', 'sprout': 'sprout', // agricultura
};

bool isGlyphKey(String value) => _glyphAssets.containsKey(value);

/// Si `value` es una clave reconocida, dibuja el símbolo de la marca. Si no,
/// se asume que ya es un emoji suelto (adornos de UI que no vienen del
/// catálogo, p.ej. una etiqueta de chip) y se muestra tal cual como texto —
/// así `AgroChip`/`ProductArt` sirven para ambos casos sin cambiar sus llamadas.
class CategoryGlyph extends StatelessWidget {
  const CategoryGlyph({super.key, required this.value, this.size = 32, this.color = Colors.white});

  final String value;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!isGlyphKey(value)) {
      return Text(value, style: TextStyle(fontSize: size, height: 1));
    }
    return Image.asset(
      'assets/brand/glyphs/${_glyphAssets[value]}.png',
      width: size,
      height: size,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stack) => SizedBox(width: size, height: size),
    );
  }
}

/// Emblema ilustrado de una categoría RAÍZ (Animales / Apicultura / Agricultura),
/// del set oficial de la marca. Solo para tamaños grandes (tarjetas de categoría):
/// a tamaño chip el detalle se pierde, ahí se sigue usando [CategoryGlyph].
///
/// Se busca por el id de la categoría (no por su clave de ícono) porque las claves
/// 'cow'/'bee'/'chili' también las usan tipos de producto individuales.
const _emblemAssets = {
  'animales': 'assets/brand/emblem_animales.png',
  'apicultura': 'assets/brand/emblem_apicultura.png',
  'agricultura': 'assets/brand/emblem_agricultura.png',
};

bool hasCategoryEmblem(String categoryId) => _emblemAssets.containsKey(categoryId);

class CategoryEmblem extends StatelessWidget {
  const CategoryEmblem({super.key, required this.categoryId, this.height = 80, this.color = Colors.white});

  final String categoryId;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final asset = _emblemAssets[categoryId];
    if (asset == null) return SizedBox(height: height);
    return Image.asset(
      asset,
      height: height,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stack) => SizedBox(height: height),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Iconos de línea minimalistas dibujados a mano con Canvas (sin depender de
/// un paquete de iconos externo ni de assets SVG) para las categorías y tipos
/// de producto del catálogo — sustituyen a los emojis de colores, que se
/// veían poco profesionales al lado del resto de la interfaz.
const _glyphKeys = {
  'cow', 'horse', 'sheep', 'goat', 'pig', // animales
  'hive', 'bee', 'crown', 'honey', // apicultura
  'chili', 'fruit', 'leaf', 'sprout', // agricultura
};

bool isGlyphKey(String value) => _glyphKeys.contains(value);

/// Si `value` es una clave reconocida, dibuja el glifo vectorial. Si no,
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
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GlyphPainter(value, color)),
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

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.value, this.color);
  final String value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    Offset p(double x, double y) => Offset(x * s, y * s);

    // A los 15px de un AgroChip, el 0.075 proporcional da un trazo de ~1.1px —
    // se pierde contra la pantalla. Se pone un piso absoluto para que el
    // glifo se siga leyendo aunque se dibuje chico (chips, tabs).
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(size.width * 0.08, 2.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    void dotAt(double x, double y, double r) => canvas.drawCircle(p(x, y), r * s, dot);

    switch (value) {
      case 'cow':
        // Cabeza de toro estilo glifo (círculo + cuernos), como el símbolo de Tauro.
        canvas.drawCircle(p(50, 60), 18 * s, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(40 * s, 46 * s)
            ..quadraticBezierTo(20 * s, 35 * s, 27 * s, 12 * s),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(60 * s, 46 * s)
            ..quadraticBezierTo(80 * s, 35 * s, 73 * s, 12 * s),
          stroke,
        );
        dotAt(44, 64, 2.2);
        dotAt(56, 64, 2.2);
        break;
      case 'goat':
        canvas.drawCircle(p(50, 58), 16 * s, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(41 * s, 44 * s)
            ..lineTo(31 * s, 16 * s)
            ..quadraticBezierTo(27 * s, 8 * s, 35 * s, 7 * s),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(59 * s, 44 * s)
            ..lineTo(69 * s, 16 * s)
            ..quadraticBezierTo(73 * s, 8 * s, 65 * s, 7 * s),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(45 * s, 73 * s)
            ..lineTo(50 * s, 86 * s)
            ..lineTo(55 * s, 73 * s),
          stroke,
        );
        dotAt(43, 62, 2.2);
        dotAt(57, 62, 2.2);
        break;
      case 'sheep':
        final wool = Path()..moveTo(30 * s, 50 * s);
        for (final cx in [42.0, 54.0, 66.0, 78.0]) {
          wool.arcToPoint(p(cx, 50), radius: Radius.circular(8 * s), clockwise: false);
        }
        wool.lineTo(78 * s, 66 * s);
        wool.quadraticBezierTo(54 * s, 80 * s, 30 * s, 66 * s);
        wool.close();
        canvas.drawPath(wool, stroke);
        canvas.drawCircle(p(24, 62), 11 * s, stroke);
        dotAt(20, 60, 1.8);
        break;
      case 'horse':
        final head = Path()
          ..moveTo(27 * s, 82 * s)
          ..lineTo(27 * s, 48 * s)
          ..quadraticBezierTo(29 * s, 22 * s, 47 * s, 14 * s)
          ..lineTo(51 * s, 6 * s)
          ..lineTo(56 * s, 20 * s)
          ..quadraticBezierTo(66 * s, 24 * s, 74 * s, 38 * s)
          ..quadraticBezierTo(82 * s, 48 * s, 80 * s, 58 * s)
          ..quadraticBezierTo(76 * s, 64 * s, 66 * s, 62 * s)
          ..lineTo(58 * s, 68 * s)
          ..lineTo(52 * s, 82 * s);
        canvas.drawPath(head, stroke);
        dotAt(72, 52, 2.2);
        break;
      case 'pig':
        canvas.drawCircle(p(50, 52), 20 * s, stroke);
        canvas.drawOval(Rect.fromCenter(center: p(50, 60), width: 20 * s, height: 14 * s), stroke);
        dotAt(45, 60, 1.8);
        dotAt(55, 60, 1.8);
        canvas.drawPath(
          Path()
            ..moveTo(32 * s, 36 * s)
            ..lineTo(28 * s, 24 * s)
            ..lineTo(40 * s, 30 * s),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(68 * s, 36 * s)
            ..lineTo(72 * s, 24 * s)
            ..lineTo(60 * s, 30 * s),
          stroke,
        );
        break;
      case 'hive':
        canvas.drawLine(p(18, 85), p(82, 85), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(18 * s, 85 * s)
            ..quadraticBezierTo(18 * s, 22 * s, 50 * s, 14 * s)
            ..quadraticBezierTo(82 * s, 22 * s, 82 * s, 85 * s),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(30 * s, 46 * s)
            ..quadraticBezierTo(50 * s, 38 * s, 70 * s, 46 * s),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(23 * s, 66 * s)
            ..quadraticBezierTo(50 * s, 56 * s, 77 * s, 66 * s),
          stroke,
        );
        canvas.drawCircle(p(50, 78), 5 * s, stroke);
        break;
      case 'bee':
        // Rediseño: antes la cabeza y las alas se encimaban (misma zona en Y)
        // y a tamaño chico se veía como una mancha. Ahora cada parte vive en
        // su propia franja vertical — antenas arriba, cabeza, alas a los
        // lados de los hombros, cuerpo abajo — para que se lean por separado.
        canvas.drawLine(p(45, 20), p(40, 9), stroke);
        canvas.drawLine(p(55, 20), p(60, 9), stroke);
        canvas.drawCircle(p(50, 27), 9 * s, stroke);
        canvas.save();
        canvas.translate(26 * s, 46 * s);
        canvas.rotate(-0.3);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 15 * s, height: 26 * s), stroke);
        canvas.restore();
        canvas.save();
        canvas.translate(74 * s, 46 * s);
        canvas.rotate(0.3);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 15 * s, height: 26 * s), stroke);
        canvas.restore();
        canvas.save();
        canvas.translate(50 * s, 66 * s);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 34 * s, height: 40 * s), stroke);
        for (final dy in [-11.0, 1.0, 13.0]) {
          canvas.drawLine(Offset(-15 * s, dy * s), Offset(15 * s, dy * s), stroke);
        }
        canvas.restore();
        break;
      case 'crown':
        canvas.drawPath(
          Path()
            ..moveTo(26 * s, 72 * s)
            ..lineTo(24 * s, 46 * s)
            ..lineTo(37 * s, 60 * s)
            ..lineTo(50 * s, 34 * s)
            ..lineTo(63 * s, 60 * s)
            ..lineTo(76 * s, 46 * s)
            ..lineTo(74 * s, 72 * s)
            ..close(),
          stroke,
        );
        break;
      case 'honey':
        final hex = Path();
        for (var i = 0; i < 6; i++) {
          final angle = (60.0 * i - 90) * math.pi / 180;
          final x = 50 + 24 * math.cos(angle);
          final y = 42 + 24 * math.sin(angle);
          if (i == 0) {
            hex.moveTo(x * s, y * s);
          } else {
            hex.lineTo(x * s, y * s);
          }
        }
        hex.close();
        canvas.drawPath(hex, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(50 * s, 62 * s)
            ..quadraticBezierTo(63 * s, 76 * s, 50 * s, 88 * s)
            ..quadraticBezierTo(37 * s, 76 * s, 50 * s, 62 * s)
            ..close(),
          stroke,
        );
        break;
      case 'chili':
        // Rediseño: la versión anterior era una sola línea delgada en forma
        // de "S" — sin volumen se leía como un garabato, no como un chile.
        // Ahora es una silueta cerrada (contorno grueso de una vaina curva)
        // más un cáliz/tallo claro arriba, como el emoji 🌶️.
        canvas.drawPath(
          Path()
            ..moveTo(37 * s, 20 * s)
            ..lineTo(46 * s, 13 * s)
            ..lineTo(54 * s, 20 * s),
          stroke,
        );
        canvas.drawLine(p(46, 20), p(46, 27), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(46 * s, 27 * s)
            ..quadraticBezierTo(80 * s, 32 * s, 76 * s, 58 * s)
            ..quadraticBezierTo(72 * s, 82 * s, 50 * s, 87 * s)
            ..quadraticBezierTo(38 * s, 88 * s, 40 * s, 74 * s)
            ..quadraticBezierTo(41 * s, 64 * s, 46 * s, 58 * s)
            ..quadraticBezierTo(30 * s, 56 * s, 30 * s, 42 * s)
            ..quadraticBezierTo(30 * s, 31 * s, 46 * s, 27 * s)
            ..close(),
          stroke,
        );
        break;
      case 'fruit':
        canvas.drawOval(Rect.fromCenter(center: p(50, 58), width: 44 * s, height: 46 * s), stroke);
        canvas.drawLine(p(50, 35), p(50, 22), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(50 * s, 26 * s)
            ..quadraticBezierTo(64 * s, 20 * s, 66 * s, 30 * s)
            ..quadraticBezierTo(56 * s, 32 * s, 50 * s, 26 * s)
            ..close(),
          stroke,
        );
        break;
      case 'leaf':
        canvas.drawPath(
          Path()
            ..moveTo(50 * s, 14 * s)
            ..quadraticBezierTo(86 * s, 36 * s, 50 * s, 86 * s)
            ..quadraticBezierTo(14 * s, 36 * s, 50 * s, 14 * s)
            ..close(),
          stroke,
        );
        canvas.drawLine(p(50, 22), p(50, 78), stroke);
        break;
      case 'sprout':
        canvas.drawLine(p(50, 86), p(50, 46), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(50 * s, 58 * s)
            ..quadraticBezierTo(26 * s, 54 * s, 21 * s, 30 * s)
            ..quadraticBezierTo(38 * s, 40 * s, 50 * s, 58 * s)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(50 * s, 52 * s)
            ..quadraticBezierTo(74 * s, 46 * s, 79 * s, 24 * s)
            ..quadraticBezierTo(64 * s, 34 * s, 50 * s, 52 * s)
            ..close(),
          stroke,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

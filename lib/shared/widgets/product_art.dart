import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'category_glyphs.dart';

/// Arte de producto generado (gradiente por categoría + surcos + emoji).
/// Si se da `imageUrl`, se muestra la foto real (Fase 4) y este arte queda de
/// placeholder mientras carga o si la foto falla/no existe.
class ProductArt extends StatelessWidget {
  const ProductArt({
    super.key,
    required this.emoji,
    required this.colorKey,
    this.imageUrl,
    this.emojiSize = 64,
    this.radius = 24,
    this.heroTag,
    this.variant = 0,
  });

  final String emoji;
  final String colorKey;
  final String? imageUrl;
  final double emojiSize;
  final double radius;
  final Object? heroTag;
  final int variant;

  @override
  Widget build(BuildContext context) {
    final p = paletteFor(colorKey);
    final alignments = [
      (Alignment.topLeft, Alignment.bottomRight),
      (Alignment.topRight, Alignment.bottomLeft),
      (Alignment.bottomLeft, Alignment.topRight),
    ];
    final (begin, end) = alignments[variant % alignments.length];

    final art = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: begin, end: end, colors: [p.soft, p.strong]),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _FurrowPainter(p.deep.withValues(alpha: 0.12), variant)),
            Center(
              child: isGlyphKey(emoji)
                  // Tono profundo de la categoría (no blanco): con la paleta
                  // apagada el blanco casi no contrasta contra el fondo claro.
                  ? CategoryGlyph(value: emoji, size: emojiSize, color: p.deep.withValues(alpha: 0.8))
                  : Text(
                      emoji,
                      style: TextStyle(
                        fontSize: emojiSize,
                        height: 1,
                        shadows: [
                          Shadow(
                            color: p.deep.withValues(alpha: 0.35),
                            blurRadius: emojiSize * 0.35,
                            offset: Offset(0, emojiSize * 0.12),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    var content = art;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          // Mientras carga o si la URL falla (foto borrada del disco, sin red,
          // etc.), se ve el arte generado en vez de un ícono roto.
          loadingBuilder: (context, child, progress) => progress == null ? child : art,
          errorBuilder: (context, error, stack) => art,
        ),
      );
    }

    if (heroTag == null) return content;
    return Hero(
      tag: heroTag!,
      child: Material(type: MaterialType.transparency, child: content),
    );
  }
}

class _FurrowPainter extends CustomPainter {
  _FurrowPainter(this.color, this.variant);

  final Color color;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final origin = variant.isEven
        ? Offset(size.width * 1.05, size.height * 1.1)
        : Offset(-size.width * 0.05, size.height * 1.1);
    final step = math.max(size.shortestSide * 0.16, 10.0);
    // Antes eran 9 anillos + 10 puntos — se veía recargado al lado de los
    // nuevos glifos de línea, planos. Menos elementos = más "minimalista".
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(origin, step * i, paint);
    }
    final dot = Paint()..color = color;
    final rnd = math.Random(variant + 7);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.6),
        1.5 + rnd.nextDouble() * 2,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FurrowPainter old) => old.color != color || old.variant != variant;
}

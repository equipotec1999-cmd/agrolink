import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografía (rediseño rústico): Cinzel — serif de inscripción, como los rótulos
/// del logo y los emblemas — para titulares; Plus Jakarta Sans para lectura,
/// precios y todo lo que tiene que leerse rápido a tamaño chico.
///
/// Cinzel dibuja las minúsculas como versalitas, así que los títulos se leen
/// como rótulo grabado sin tener que escribirlos en mayúsculas en el código.
/// A diferencia de la fuente anterior, necesita espaciado POSITIVO entre letras.
abstract final class AppText {
  static const display = 'Cinzel';
  static const body = 'PlusJakartaSans';

  static const hero = TextStyle(
    fontFamily: display,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: 0.6,
    color: AppColors.ink,
  );
  static const h1 = TextStyle(
    fontFamily: display,
    fontSize: 25,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: 0.8,
    color: AppColors.ink,
  );
  static const h2 = TextStyle(
    fontFamily: display,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.6,
    color: AppColors.ink,
  );
  static const h3 = TextStyle(
    fontFamily: display,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.6,
    color: AppColors.ink,
  );
  // Precio en sans: los números en Cinzel son bonitos pero más lentos de leer.
  static const price = TextStyle(
    fontFamily: body,
    fontSize: 19,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );
  static const title = TextStyle(
    fontFamily: body,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const bodyStrong = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  static const bodyText = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.ink,
  );
  static const muted = TextStyle(
    fontFamily: body,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );
  static const label = TextStyle(
    fontFamily: body,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.ink,
  );
  // Rótulo chico tipo "— ANIMALES —" de los emblemas.
  static const overline = TextStyle(
    fontFamily: display,
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.2,
    color: AppColors.muted,
  );
}

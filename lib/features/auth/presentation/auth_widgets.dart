import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/agrolink_logo.dart';

/// Cabecera de autenticación (rediseño rústico): fondo carbón plano con el
/// emblema oficial grande y muy tenue como marca de agua. Antes eran emojis
/// flotando sobre un degradado; se quitó todo el movimiento para un look sobrio.
/// El nombre se conserva para no tocar a quien la usa.
class FloatingProduceHeader extends StatelessWidget {
  const FloatingProduceHeader({super.key, required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ColoredBox(
        color: AppColors.ink,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -height * 0.28,
              top: -height * 0.06,
              child: AgroLinkMark(size: height * 1.05, color: AppColors.bone.withValues(alpha: 0.05)),
            ),
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}

/// Hoja clara que sube sobre la cabecera.
class AuthSheet extends StatelessWidget {
  const AuthSheet({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      child: child,
    );
  }
}

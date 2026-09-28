import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'category_glyphs.dart';
import 'motion.dart';

enum ButtonTone { dark, lime, light }

class AgroButton extends StatelessWidget {
  const AgroButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.tone = ButtonTone.dark,
    this.loading = false,
    this.expand = true,
    this.height = 58,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final ButtonTone tone;
  final bool loading;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final (bg, fg) = switch (tone) {
      ButtonTone.dark => (AppColors.ink, AppColors.bone),
      ButtonTone.lime => (AppColors.lime, AppColors.ink),
      ButtonTone.light => (AppColors.surface, AppColors.ink),
    };
    return Pressable(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: height,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        // Rústico/minimalista: plano, sin sombra, esquina moderada.
        decoration: BoxDecoration(
          color: disabled ? bg.withValues(alpha: 0.35) : bg,
          borderRadius: BorderRadius.circular(14),
          border: tone == ButtonTone.light ? Border.all(color: AppColors.line, width: 1.2) : null,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: fg),
              )
            else ...[
              if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: 10)],
              Text(label, style: AppText.title.copyWith(color: fg)),
            ],
          ],
        ),
      ),
    );
  }
}

class AgroTextField extends StatefulWidget {
  const AgroTextField({
    super.key,
    required this.label,
    this.icon,
    this.hint,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.suffixText,
    this.maxLines = 1,
    this.textInputAction,
  });

  final String label;
  final IconData? icon;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? suffixText;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  State<AgroTextField> createState() => _AgroTextFieldState();
}

class _AgroTextFieldState extends State<AgroTextField> {
  late bool _hidden = widget.obscure;

  OutlineInputBorder _border(Color c, [double w = 1.2]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(widget.label, style: AppText.label),
        ),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          onChanged: widget.onChanged,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          obscureText: _hidden,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          textInputAction: widget.textInputAction,
          style: AppText.bodyStrong,
          cursorColor: AppColors.forest,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppText.muted,
            filled: true,
            fillColor: AppColors.surface,
            suffixText: widget.suffixText,
            suffixStyle: AppText.muted,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            prefixIcon: widget.icon == null ? null : Icon(widget.icon, color: AppColors.muted, size: 20),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                  )
                : null,
            enabledBorder: _border(AppColors.line),
            focusedBorder: _border(AppColors.forest, 2),
            errorBorder: _border(AppColors.danger),
            focusedErrorBorder: _border(AppColors.danger, 2),
            errorStyle: AppText.muted.copyWith(color: AppColors.danger, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Chip seleccionable con animación (categorías, filtros, opciones de atributos).
class AgroChip extends StatelessWidget {
  const AgroChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: dense ? 14 : 18, vertical: dense ? 9 : 12),
        // Chip tipo etiqueta (esquina chica), no píldora.
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.ink : AppColors.line, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              CategoryGlyph(value: emoji!, size: 15, color: selected ? AppColors.lime : AppColors.ink),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppText.label.copyWith(
                color: selected ? AppColors.lime : AppColors.ink,
                fontSize: dense ? 12 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppText.h3)),
        if (action != null)
          Pressable(
            onTap: onAction,
            child: Row(
              children: [
                Text(action!, style: AppText.label.copyWith(color: AppColors.forest)),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.forest),
              ],
            ),
          ),
      ],
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.background = AppColors.surface,
    this.color = AppColors.ink,
    this.size = 46,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color color;
  final double size;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: size * 0.46),
            if (badge)
              Positioned(
                top: size * 0.24,
                right: size * 0.26,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.clay,
                    shape: BoxShape.circle,
                    border: Border.all(color: background, width: 1.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(label, style: AppText.label.copyWith(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sello circular con borde, como el marco de los emblemas.
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 1.4),
            ),
            child: Icon(icon, size: 36, color: AppColors.forest),
          ),
          const SizedBox(height: 18),
          Text(title, style: AppText.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const RusticDivider(width: 90),
          const SizedBox(height: 8),
          Text(message, style: AppText.muted, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// Divisor ornamental "— ◇ —" del set de marca (va bajo títulos de emblemas,
/// estados vacíos y el logo). Con `label` queda "— ◇ RÓTULO ◇ —".
class RusticDivider extends StatelessWidget {
  const RusticDivider({super.key, this.color = AppColors.line, this.width = 120, this.label});

  final Color color;
  final double width;
  final String? label;

  @override
  Widget build(BuildContext context) {
    Widget diamond() => Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(border: Border.all(color: color, width: 1.4)),
          ),
        );
    Widget rule(double w) => Container(width: w, height: 1.2, color: color);

    if (label == null) {
      final side = (width - 7 - 16) / 2;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [rule(side), const SizedBox(width: 8), diamond(), const SizedBox(width: 8), rule(side)],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        rule(26),
        const SizedBox(width: 8),
        diamond(),
        const SizedBox(width: 10),
        Text(label!, style: AppText.overline.copyWith(color: color, fontSize: 11)),
        const SizedBox(width: 10),
        diamond(),
        const SizedBox(width: 8),
        rule(26),
      ],
    );
  }
}

void showAgroSnack(BuildContext context, String message, {String emoji = '🌱'}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        content: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: AppText.bodyStrong.copyWith(color: AppColors.bone))),
          ],
        ),
      ),
    );
}

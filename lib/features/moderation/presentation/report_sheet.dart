import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../data/moderation_repository.dart';

/// Hoja para capturar un reporte: motivo (chip) + descripción obligatoria (texto).
/// Devuelve (motivo, descripción) o null si se cancela. El backend exige la descripción.
Future<(String, String)?> showReportSheet(BuildContext context, {required String title}) {
  return showModalBottomSheet<(String, String)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(21))),
    builder: (sheet) => _ReportSheet(title: title),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.title});
  final String title;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _reason;
  final _desc = TextEditingController();

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final text = _desc.text.trim();
    final canSend = _reason != null && text.length >= 10;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppText.h2),
                const SizedBox(height: 4),
                const Text('Un moderador revisará tu reporte. La descripción es obligatoria.', style: AppText.muted),
                const SizedBox(height: 16),
                const Text('Motivo', style: AppText.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in reportReasons.entries)
                      AgroChip(
                        dense: true,
                        label: r.value,
                        selected: _reason == r.key,
                        onTap: () => setState(() => _reason = r.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                AgroTextField(
                  label: 'Describe lo que pasó',
                  hint: 'Cuenta con detalle (mínimo 10 caracteres)',
                  controller: _desc,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                AgroButton(
                  label: 'Enviar reporte',
                  icon: Icons.flag_outlined,
                  onTap: canSend ? () => Navigator.of(context).pop((_reason!, text)) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

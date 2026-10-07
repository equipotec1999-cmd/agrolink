import 'package:flutter/material.dart';

/// Diálogo simple para pedir un texto con un título y un hint. Devuelve null si se cancela.
/// Usado por acciones de moderación: motivo del rechazo, nota del reporte, etc.
Future<String?> askText(BuildContext context, {required String title, required String hint, bool required = true, int minLength = 3}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (dialog, setState) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 300,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: required && controller.text.trim().length < minLength
                ? null
                : () => Navigator.of(dialog).pop(controller.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ),
  );
}

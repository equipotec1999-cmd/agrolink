import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../data/verification_repository.dart';

/// Verificación de vendedor: estado de la solicitud y formulario para pedirla (o reenviarla).
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(verificationStatusProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Row(
              children: [
                CircleIconButton(icon: Icons.arrow_back_rounded, background: AppColors.cream, onTap: () => context.pop()),
                const SizedBox(width: 12),
                const Expanded(child: Text('Vendedor verificado', style: AppText.h1)),
              ],
            ),
            const SizedBox(height: 20),
            status.when(
              loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => EmptyState(icon: Icons.wifi_off_rounded, title: 'No pudimos cargar', message: '$e'),
              data: (s) {
                if (s.isVerified) return const _VerifiedCard();
                if (s.isPending) return const _PendingCard();
                return _RequestForm(rejectionReason: s.isRejected ? s.rejectionReason : null);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedCard extends StatelessWidget {
  const _VerifiedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(18)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_rounded, size: 40, color: AppColors.forest),
          SizedBox(height: 10),
          Text('Ya eres vendedor verificado', style: AppText.h2),
          SizedBox(height: 6),
          Text('Tus publicaciones y tu perfil muestran la insignia de verificación. Eso da confianza a los compradores.', style: AppText.muted),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top_rounded, size: 36, color: AppColors.honey),
          SizedBox(height: 10),
          Text('Solicitud en revisión', style: AppText.h2),
          SizedBox(height: 6),
          Text('Un moderador está revisando tus documentos. Te avisaremos aquí y con una notificación cuando haya respuesta.', style: AppText.muted),
        ],
      ),
    );
  }
}

class _RequestForm extends ConsumerStatefulWidget {
  const _RequestForm({this.rejectionReason});

  final String? rejectionReason;

  @override
  ConsumerState<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends ConsumerState<_RequestForm> {
  final _business = TextEditingController();
  String? _idPath;
  String? _activityPath;
  bool _sending = false;

  @override
  void dispose() {
    _business.dispose();
    super.dispose();
  }

  Future<String?> _pick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(sheet).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(sheet).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 2000);
    return file?.path;
  }

  Future<void> _send() async {
    if (_idPath == null || _activityPath == null) {
      showAgroSnack(context, 'Agrega la foto de tu identificación y de tu comprobante', emoji: '⚠️');
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(verificationRepositoryProvider).submit(
            businessName: _business.text,
            idPath: _idPath!,
            activityPath: _activityPath!,
          );
      ref.invalidate(verificationStatusProvider);
      if (mounted) showAgroSnack(context, 'Solicitud enviada', emoji: '✅');
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.rejectionReason != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Text(
              'Tu solicitud anterior fue rechazada: ${widget.rejectionReason}. Puedes corregirla y enviarla otra vez.',
              style: AppText.label.copyWith(color: AppColors.danger, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text('Gana la confianza de los compradores', style: AppText.h3),
        const SizedBox(height: 6),
        const Text(
          'Sube fotos claras de tus documentos. Solo las ve el equipo de moderación y se usan únicamente para verificarte.',
          style: AppText.muted,
        ),
        const SizedBox(height: 18),
        AgroTextField(
          label: 'Nombre del rancho o negocio (opcional)',
          icon: Icons.storefront_outlined,
          controller: _business,
          hint: user?.name,
        ),
        const SizedBox(height: 14),
        _DocPicker(
          label: 'Identificación oficial (INE)',
          path: _idPath,
          onPick: () async {
            final p = await _pick();
            if (p != null) setState(() => _idPath = p);
          },
        ),
        const SizedBox(height: 10),
        _DocPicker(
          label: 'Comprobante de actividad (UPP, REEMO, factura…)',
          path: _activityPath,
          onPick: () async {
            final p = await _pick();
            if (p != null) setState(() => _activityPath = p);
          },
        ),
        const SizedBox(height: 22),
        AgroButton(label: 'Enviar solicitud', icon: Icons.send_rounded, loading: _sending, onTap: _send),
      ],
    );
  }
}

class _DocPicker extends StatelessWidget {
  const _DocPicker({required this.label, required this.path, required this.onPick});

  final String label;
  final String? path;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: path == null ? AppColors.line : AppColors.success, width: 1.4),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: path == null
                    ? const ColoredBox(color: AppColors.sand, child: Icon(Icons.add_a_photo_outlined, color: AppColors.muted))
                    : Image.file(File(path!), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.bodyStrong),
                  Text(path == null ? 'Toca para agregar una foto' : 'Listo · toca para cambiarla', style: AppText.muted),
                ],
              ),
            ),
            if (path != null) const Icon(Icons.check_circle_rounded, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../../../shared/widgets/motion.dart';
import '../../auth/application/auth_controller.dart';
import '../../settings/data/account_repository.dart';

/// Edición completa del perfil: foto, nombre, apellidos, bio, lugar y teléfono.
/// Guarda al tocar "Guardar"; cada campo que no cambia no se envía al backend.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _lastname;
  late final TextEditingController _phone;
  late final TextEditingController _bio;
  late final TextEditingController _state;
  late final TextEditingController _municipality;
  bool _saving = false;
  bool _changingPhoto = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authProvider);
    _name = TextEditingController(text: u?.name ?? '');
    _lastname = TextEditingController(text: u?.lastname ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _bio = TextEditingController(text: u?.bio ?? '');
    _state = TextEditingController(text: u?.state ?? '');
    _municipality = TextEditingController(text: u?.municipality ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _lastname.dispose();
    _phone.dispose();
    _bio.dispose();
    _state.dispose();
    _municipality.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(21))),
      builder: (dialog) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.of(dialog).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.of(dialog).pop(ImageSource.gallery),
          ),
          if ((ref.read(authProvider)?.avatarUrl ?? '').isNotEmpty)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Quitar foto', style: TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.of(dialog).pop(null),
              onLongPress: null,
            ),
        ]),
      ),
    );
    if (!mounted) return;

    setState(() => _changingPhoto = true);
    try {
      final repo = ref.read(accountRepositoryProvider);
      AppUser fresh;
      if (src == null) {
        // Si no eligió fuente pero la hoja se cerró con "Quitar foto".
        fresh = await repo.removeAvatar();
      } else {
        final picked = await picker.pickImage(source: src, imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
        if (picked == null) {
          setState(() => _changingPhoto = false);
          return;
        }
        fresh = await repo.uploadAvatar(picked.path);
      }
      ref.read(authProvider.notifier).setUser(fresh);
      if (mounted) showAgroSnack(context, 'Foto actualizada', emoji: '✅');
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _changingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      showAgroSnack(context, 'El nombre no puede estar vacío', emoji: '⚠️');
      return;
    }
    setState(() => _saving = true);
    try {
      // Solo manda los campos que cambiaron: evita avisar al backend de todo cada vez.
      final u = ref.read(authProvider);
      final edit = ProfileEdit(
        name: _name.text.trim() == (u?.name ?? '') ? null : _name.text.trim(),
        lastname: _lastname.text.trim() == (u?.lastname ?? '') ? null : _lastname.text.trim(),
        phone: _phone.text.trim() == (u?.phone ?? '') ? null : _phone.text.trim(),
        bio: _bio.text.trim() == (u?.bio ?? '') ? null : _bio.text.trim(),
        state: _state.text.trim() == (u?.state ?? '') ? null : _state.text.trim(),
        municipality: _municipality.text.trim() == (u?.municipality ?? '') ? null : _municipality.text.trim(),
      );
      final fresh = await ref.read(accountRepositoryProvider).updateProfile(edit);
      ref.read(authProvider.notifier).setUser(fresh);
      if (mounted) {
        showAgroSnack(context, 'Perfil actualizado', emoji: '✅');
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final avatar = user?.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
              child: Row(children: [
                CircleIconButton(icon: Icons.arrow_back_rounded, background: AppColors.cream, onTap: () => context.pop()),
                const SizedBox(width: 12),
                const Text('Editar perfil', style: AppText.h1),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: AppColors.lime,
                          backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          child: avatar == null || avatar.isEmpty
                              ? Text(
                                  (user?.name.isNotEmpty == true ? user!.name : '?').substring(0, 1).toUpperCase(),
                                  style: AppText.h1.copyWith(fontSize: 40),
                                )
                              : null,
                        ),
                        Pressable(
                          onTap: _changingPhoto ? () {} : _pickPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.cream, width: 2),
                            ),
                            child: _changingPhoto
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(user?.email ?? '', style: AppText.muted.copyWith(fontSize: 12.5)),
                  ),
                  const SizedBox(height: 24),
                  AgroTextField(label: 'Nombre', icon: Icons.person_outline_rounded, controller: _name),
                  const SizedBox(height: 14),
                  AgroTextField(label: 'Apellidos', icon: Icons.badge_outlined, controller: _lastname),
                  const SizedBox(height: 14),
                  AgroTextField(
                    label: 'Teléfono',
                    icon: Icons.phone_outlined,
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: AgroTextField(label: 'Estado', icon: Icons.map_outlined, controller: _state)),
                    const SizedBox(width: 12),
                    Expanded(child: AgroTextField(label: 'Municipio', controller: _municipality)),
                  ]),
                  const SizedBox(height: 14),
                  AgroTextField(
                    label: 'Sobre mí',
                    hint: 'Ej. productor de miel con 8 años en el campo',
                    controller: _bio,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 6),
                  Text('Hasta 280 caracteres. Se muestra en tu perfil público.', style: AppText.muted.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: AgroButton(
                label: _saving ? 'Guardando…' : 'Guardar cambios',
                tone: ButtonTone.lime,
                height: 50,
                onTap: _saving ? () {} : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

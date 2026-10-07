import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/agro_widgets.dart';
import '../data/my_listings_repository.dart';

/// Edición básica de una publicación propia: título, descripción, precio, cantidad y negociable.
class EditListingScreen extends ConsumerStatefulWidget {
  const EditListingScreen({super.key, required this.listing});

  final MyListing listing;

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  late final _title = TextEditingController(text: widget.listing.title);
  late final _description = TextEditingController(text: widget.listing.description);
  late final _price = TextEditingController(text: _num(widget.listing.price));
  late final _quantity = TextEditingController(text: _num(widget.listing.quantity));
  late bool _negotiable = widget.listing.negotiable;
  bool _saving = false;

  static String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final price = double.tryParse(_price.text.replaceAll(',', '.').trim());
    final quantity = double.tryParse(_quantity.text.replaceAll(',', '.').trim());
    if (title.length < 3) return showAgroSnack(context, 'Escribe un título', emoji: '⚠️');
    if (price == null || price < 0) return showAgroSnack(context, 'Precio no válido', emoji: '⚠️');
    if (quantity == null || quantity <= 0) return showAgroSnack(context, 'Cantidad no válida', emoji: '⚠️');

    setState(() => _saving = true);
    try {
      await ref.read(myListingsRepositoryProvider).update(
            widget.listing.id,
            title: title,
            description: _description.text.trim(),
            price: price,
            quantity: quantity,
            negotiable: _negotiable,
          );
      if (!mounted) return;
      showAgroSnack(context, 'Cambios guardados', emoji: '✅');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) showAgroSnack(context, e.message, emoji: '⚠️');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Row(
              children: [
                CircleIconButton(icon: Icons.arrow_back_rounded, background: AppColors.cream, onTap: () => context.pop()),
                const SizedBox(width: 12),
                const Text('Editar publicación', style: AppText.h1),
              ],
            ),
            const SizedBox(height: 20),
            AgroTextField(label: 'Título', controller: _title),
            const SizedBox(height: 14),
            AgroTextField(label: 'Descripción', controller: _description, maxLines: 4),
            const SizedBox(height: 14),
            AgroTextField(
              label: 'Precio',
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffixText: 'MXN',
            ),
            const SizedBox(height: 14),
            AgroTextField(
              label: 'Cantidad',
              controller: _quantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffixText: widget.listing.unit,
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Precio negociable'),
              value: _negotiable,
              onChanged: (v) => setState(() => _negotiable = v),
            ),
            const SizedBox(height: 14),
            AgroButton(label: 'Guardar cambios', icon: Icons.check_rounded, loading: _saving, onTap: _save),
          ],
        ),
      ),
    );
  }
}

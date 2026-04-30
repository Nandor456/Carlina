import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/vehicles_provider.dart';

class AddVehicleBottomSheet extends ConsumerStatefulWidget {
  const AddVehicleBottomSheet({super.key});

  @override
  ConsumerState<AddVehicleBottomSheet> createState() =>
      _AddVehicleBottomSheetState();
}

class _AddVehicleBottomSheetState
    extends ConsumerState<AddVehicleBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await ref.read(vehiclesProvider.notifier).addVehicle({
      'licensePlate': _plateCtrl.text.trim().toUpperCase(),
      'make': _makeCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _saving = false);
      if (result != null) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Add Vehicle',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _plateCtrl,
              decoration: const InputDecoration(
                labelText: 'License Plate',
                hintText: 'CJ 01 ABC',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final pattern = RegExp(
                  r'^(?:[A-Z]{1,2}\s\d{2,3}\s[A-Z]{3}|[A-Z]{3}-\d{3}|[A-Z]{2}\s[A-Z]{2}-\d{3})$',
                );
                if (!pattern.hasMatch(v.trim().toUpperCase())) {
                  return 'Format: CJ 01 ABC OR ABC-123';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _makeCtrl,
              decoration: const InputDecoration(
                labelText: 'Make',
                hintText: 'e.g. Dacia',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Required',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modelCtrl,
              decoration: const InputDecoration(
                labelText: 'Model',
                hintText: 'e.g. Logan',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
              validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Required',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Add Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}

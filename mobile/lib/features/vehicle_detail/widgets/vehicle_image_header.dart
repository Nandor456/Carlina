import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/vehicle_image_provider.dart';
import '../../dashboard/providers/vehicles_provider.dart';

class VehicleImageHeader extends ConsumerWidget {
  const VehicleImageHeader({super.key, required this.vehicleId});

  final String vehicleId;

  static const double _height = 200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(vehicleImageNotifierProvider(vehicleId));
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: _height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Image or placeholder ───────────────────────────
          imageState.when(
            loading: () => Container(
              color: cs.surfaceContainerLow,
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => _Placeholder(cs: cs),
            data: (bytes) => bytes != null && bytes.isNotEmpty
                ? Image.memory(bytes, fit: BoxFit.cover)
                : _Placeholder(cs: cs),
          ),

          // ── Gradient overlay ───────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(140)],
                ),
              ),
            ),
          ),

          // ── Action buttons ─────────────────────────────────
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              children: [
                _ActionButton(
                  icon: Icons.camera_alt_rounded,
                  tooltip: 'Upload photo',
                  onPressed: () => _pickAndUpload(context, ref),
                ),
                if (imageState.valueOrNull != null) ...[
                  const SizedBox(width: 6),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Remove photo',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;

    try {
      await ref
          .read(vehicleImageNotifierProvider(vehicleId).notifier)
          .upload(File(picked.path));
      // Refresh vehicle list so dashboard thumbnail updates
      await ref.read(vehiclesProvider.notifier).loadVehicles();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove photo?'),
        content: const Text('The vehicle photo will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(vehicleImageNotifierProvider(vehicleId).notifier)
          .delete();
      await ref.read(vehiclesProvider.notifier).loadVehicles();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove image')),
        );
      }
    }
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
        color: cs.surfaceContainerLow,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_rounded, size: 64, color: cs.outline),
            const SizedBox(height: 8),
            Text(
              'Tap camera icon to add a photo',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
}

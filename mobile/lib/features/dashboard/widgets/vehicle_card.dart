import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../core/models/document_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../vehicle_detail/providers/vehicle_image_provider.dart';

class VehicleCard extends ConsumerWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    required this.onDelete,
  });

  final VehicleModel vehicle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = vehicle.overallStatus;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────
              Row(
                children: [
                  // Vehicle thumbnail (if image exists)
                  if (vehicle.hasImage) ...[
                    _VehicleThumbnail(vehicleId: vehicle.id),
                    const SizedBox(width: 12),
                  ] else ...[
                    // Status indicator dot (fallback when no photo)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle.make} ${vehicle.model}',
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          vehicle.licensePlate,
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Overall status chip
                  _StatusChip(status: status),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: cs.error,
                    onPressed: onDelete,
                    tooltip: 'Remove vehicle',
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Document status dots ─────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: DocumentType.values.map((type) {
                  final doc = vehicle.documents
                      .where((d) => d.documentType == type)
                      .firstOrNull;
                  return _DocStatusItem(type: type, doc: doc);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleThumbnail extends ConsumerWidget {
  const _VehicleThumbnail({required this.vehicleId});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(vehicleImageNotifierProvider(vehicleId));
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 52,
        height: 52,
        child: imageState.when(
          loading: () => Container(
            color: cs.surfaceContainerLow,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => _iconFallback(cs),
          data: (bytes) => bytes != null && bytes.isNotEmpty
              ? Image.memory(bytes, fit: BoxFit.cover)
              : _iconFallback(cs),
        ),
      ),
    );
  }

  Widget _iconFallback(ColorScheme cs) => Container(
        color: cs.surfaceContainerLow,
        child: Icon(Icons.directions_car_rounded, color: cs.outline, size: 28),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.lightColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocStatusItem extends StatelessWidget {
  const _DocStatusItem({required this.type, required this.doc});

  final DocumentType type;
  final DocumentModel? doc;

  @override
  Widget build(BuildContext context) {
    final status = doc?.status ?? DocumentStatus.expired;
    final color = doc == null
        ? Theme.of(context).colorScheme.outline
        : status.color;

    return Column(
      children: [
        Icon(
          doc == null ? Icons.remove_circle_outline : status.icon,
          color: color,
          size: 22,
        ),
        const SizedBox(height: 4),
        Text(
          type.label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

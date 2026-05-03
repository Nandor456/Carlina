import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/family_member_model.dart';
import '../../../core/models/document_model.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/family_vehicles_provider.dart';

class FamilyMemberCard extends ConsumerStatefulWidget {
  const FamilyMemberCard({
    super.key,
    required this.member,
    required this.onViewCars,
    required this.onRemove,
  });

  final FamilyMemberModel member;
  final VoidCallback onViewCars;
  final VoidCallback onRemove;

  @override
  ConsumerState<FamilyMemberCard> createState() => _FamilyMemberCardState();
}

class _FamilyMemberCardState extends ConsumerState<FamilyMemberCard> {
  @override
  void initState() {
    super.initState();
    // Family tab refresh already triggers vehicle loads — only fetch here as a
    // safety net if no data is present (e.g. card mounted in isolation).
    Future.microtask(() {
      final s = ref.read(familyVehiclesProvider(widget.member.id));
      if (s.vehicles.isEmpty && !s.isLoading) {
        ref.read(familyVehiclesProvider(widget.member.id).notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final vehiclesState = ref.watch(familyVehiclesProvider(widget.member.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Member header ─────────────────────────────────
            Row(
              children: [
                _Avatar(member: widget.member),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.member.displayName,
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (widget.member.fullName != null)
                        Text(
                          widget.member.email,
                          style: textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_remove_outlined, size: 20),
                  color: cs.error,
                  tooltip: 'Remove from family',
                  onPressed: widget.onRemove,
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Vehicles summary ──────────────────────────────
            if (vehiclesState.isLoading && vehiclesState.vehicles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (vehiclesState.error != null)
              Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: cs.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      vehiclesState.error!,
                      style: textTheme.bodySmall?.copyWith(color: cs.error),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(familyVehiclesProvider(widget.member.id).notifier)
                        .load(),
                    child: const Text('Retry'),
                  ),
                ],
              )
            else if (vehiclesState.vehicles.isEmpty)
              Text(
                'No vehicles yet',
                style: textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              )
            else
              _VehiclesSummary(vehicles: vehiclesState.vehicles),

            const SizedBox(height: 12),

            // ── View all button ───────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onViewCars,
                icon: const Icon(Icons.directions_car_rounded, size: 16),
                label: const Text('View Cars'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member});
  final FamilyMemberModel member;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = member.displayName.isNotEmpty
        ? member.displayName[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 24,
      backgroundColor: cs.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _VehiclesSummary extends StatelessWidget {
  const _VehiclesSummary({required this.vehicles});
  final List<VehicleModel> vehicles;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: vehicles.map((v) {
        final status = v.overallStatus;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${v.make} ${v.model}',
                  style: textTheme.bodyMedium,
                ),
              ),
              Text(
                v.licensePlate,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              // Doc status icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: DocumentType.values.map((type) {
                  final doc = v.documents
                      .where((d) => d.documentType == type)
                      .firstOrNull;
                  final color = doc == null
                      ? cs.outline
                      : doc.status.color;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Tooltip(
                      message: type.label,
                      child: Icon(
                        doc == null
                            ? Icons.remove_circle_outline
                            : doc.status.icon,
                        color: color,
                        size: 16,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

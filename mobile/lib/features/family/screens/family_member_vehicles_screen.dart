import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../core/models/document_model.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/family_vehicles_provider.dart';

class FamilyMemberVehiclesScreen extends ConsumerStatefulWidget {
  const FamilyMemberVehiclesScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  final String memberId;
  final String memberName;

  @override
  ConsumerState<FamilyMemberVehiclesScreen> createState() =>
      _FamilyMemberVehiclesScreenState();
}

class _FamilyMemberVehiclesScreenState
    extends ConsumerState<FamilyMemberVehiclesScreen> {
  @override
  void initState() {
    super.initState();
    // Only fetch if we have no data yet — the Family tab usually pre-loads it.
    Future.microtask(() {
      final s = ref.read(familyVehiclesProvider(widget.memberId));
      if (s.vehicles.isEmpty && !s.isLoading) {
        ref.read(familyVehiclesProvider(widget.memberId).notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyVehiclesProvider(widget.memberId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.memberName}'s Cars"),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(familyVehiclesProvider(widget.memberId).notifier).load(),
        child: _buildBody(state, cs),
      ),
    );
  }

  Widget _buildBody(FamilyVehiclesState state, ColorScheme cs) {
    if (state.isLoading && state.vehicles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
            const SizedBox(height: 8),
            Text(state.error!),
            TextButton(
              onPressed: () => ref
                  .read(familyVehiclesProvider(widget.memberId).notifier)
                  .load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined, size: 72, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              'No vehicles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: state.vehicles.length,
      itemBuilder: (_, i) {
        final v = state.vehicles[i];
        return _ReadOnlyVehicleCard(
          vehicle: v,
          onTap: () => _showVehicleDetail(context, v),
        );
      },
    );
  }

  void _showVehicleDetail(BuildContext context, VehicleModel vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _VehicleDetailSheet(vehicle: vehicle),
    );
  }
}

// ── Read-only vehicle card ────────────────────────────────────────────────────

class _ReadOnlyVehicleCard extends StatelessWidget {
  const _ReadOnlyVehicleCard({
    required this.vehicle,
    required this.onTap,
  });

  final VehicleModel vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                  _StatusChip(status: status),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

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
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── Vehicle detail bottom sheet ───────────────────────────────────────────────

class _VehicleDetailSheet extends StatelessWidget {
  const _VehicleDetailSheet({required this.vehicle});
  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            '${vehicle.make} ${vehicle.model}',
            style: textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            vehicle.licensePlate,
            style: textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 1.2),
          ),
          if (vehicle.year != null)
            Text(
              '${vehicle.year}',
              style: textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),

          const SizedBox(height: 24),
          Text(
            'Documents',
            style: textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...DocumentType.values.map((type) {
            final doc = vehicle.documents
                .where((d) => d.documentType == type)
                .firstOrNull;
            return _DocumentRow(type: type, doc: doc);
          }),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.type, required this.doc});
  final DocumentType type;
  final DocumentModel? doc;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final status = doc?.status ?? DocumentStatus.expired;
    final color = doc == null ? cs.outline : status.color;
    final lightColor = doc == null ? cs.surfaceContainerLow : status.lightColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            doc == null ? Icons.remove_circle_outline : status.icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.label,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(type.description,
                    style: textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (doc != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  status.label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
                Text(
                  _formatDate(doc!.expirationDate),
                  style: textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (doc!.daysLeft >= 0)
                  Text(
                    '${doc!.daysLeft}d left',
                    style: TextStyle(fontSize: 11, color: color),
                  )
                else
                  Text(
                    '${-doc!.daysLeft}d ago',
                    style: TextStyle(fontSize: 11, color: color),
                  ),
              ],
            ),
          ] else
            Text(
              'Not added',
              style: textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

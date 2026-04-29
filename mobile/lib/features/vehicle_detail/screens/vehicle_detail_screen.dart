import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/document_model.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/providers/vehicles_provider.dart';
import '../providers/documents_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/add_document_bottom_sheet.dart';

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesState = ref.watch(vehiclesProvider);
    final docsState = ref.watch(documentsProvider(vehicleId));

    final vehicle = vehiclesState.vehicles
        .where((v) => v.id == vehicleId)
        .firstOrNull;

    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vehicle')),
        body: const Center(child: Text('Vehicle not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${vehicle.make} ${vehicle.model}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _VehicleSubtitle(vehicle: vehicle),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(documentsProvider(vehicleId).notifier).loadDocuments(),
        child: docsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _DocumentList(
                vehicleId: vehicleId,
                documents: docsState.documents,
              ),
      ),
    );
  }
}

// ── Vehicle subtitle banner ────────────────────────────────────

class _VehicleSubtitle extends StatelessWidget {
  const _VehicleSubtitle({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = vehicle.overallStatus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Icon(Icons.pin_outlined, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            vehicle.licensePlate,
            style: TextStyle(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          if (vehicle.year != null) ...[
            Text(' • ', style: TextStyle(color: cs.onSurfaceVariant)),
            Text(
              '${vehicle.year}',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
          const Spacer(),
          // Overall status chip
          Container(
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
          ),
        ],
      ),
    );
  }
}

// ── Document list ─────────────────────────────────────────────

class _DocumentList extends ConsumerWidget {
  const _DocumentList({
    required this.vehicleId,
    required this.documents,
  });

  final String vehicleId;
  final List<DocumentModel> documents;

  void _showSheet(
    BuildContext context, {
    required DocumentType type,
    DocumentModel? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddDocumentBottomSheet(
        vehicleId: vehicleId,
        existingDocument: existing,
        preselectedType: type,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      children: [
        // ── Section header ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
          child: Text(
            'Mandatory Documents',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
          ),
        ),

        // ── One card per document type ─────────────────────
        ...DocumentType.values.map((type) {
          final doc =
              documents.where((d) => d.documentType == type).firstOrNull;

          return Dismissible(
            key: ValueKey('${type.name}-${doc?.id}'),
            direction: doc != null
                ? DismissDirection.endToStart
                : DismissDirection.none,
            background: Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: cs.onErrorContainer),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Delete ${type.label}?'),
                  content: const Text(
                      'This will remove the document record permanently.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                          backgroundColor: cs.error),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) {
              if (doc != null) {
                ref
                    .read(documentsProvider(vehicleId).notifier)
                    .deleteDocument(doc.id);
              }
            },
            child: DocumentCard(
              documentType: type,
              document: doc,
              onTap: () => _showSheet(context, type: type, existing: doc),
            ),
          );
        }),

        // ── Help text ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Text(
            'Swipe left on a document to delete it. Tap to add or edit.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

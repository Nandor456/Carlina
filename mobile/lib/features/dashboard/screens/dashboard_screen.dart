import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/vehicles_provider.dart';
import '../widgets/vehicle_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../_add_vehicle_bottom_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(vehiclesProvider.notifier).loadVehicles(),
    );
  }

  Future<void> _confirmDelete(String vehicleId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Vehicle'),
        content: Text('Remove $name from your garage?'),
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
    if (confirmed == true) {
      await ref.read(vehiclesProvider.notifier).removeVehicle(vehicleId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehiclesProvider);
    final auth = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garage'),
        actions: [
          if (auth.user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sign out',
                onPressed: () =>
                    ref.read(authProvider.notifier).logout(),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(vehiclesProvider.notifier).loadVehicles(),
        child: _buildBody(state, cs),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => const AddVehicleBottomSheet(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Vehicle'),
      ),
    );
  }

  Widget _buildBody(VehiclesState state, ColorScheme cs) {
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
              onPressed: () =>
                  ref.read(vehiclesProvider.notifier).loadVehicles(),
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
              'No vehicles yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add your first car',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: state.vehicles.length,
      itemBuilder: (_, i) {
        final v = state.vehicles[i];
        return VehicleCard(
          vehicle: v,
          onTap: () => context.push('/vehicle/${v.id}'),
          onDelete: () => _confirmDelete(v.id, '${v.make} ${v.model}'),
        );
      },
    );
  }
}

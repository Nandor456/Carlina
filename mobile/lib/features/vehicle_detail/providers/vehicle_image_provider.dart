import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Fetches the raw image bytes for a vehicle, keyed by vehicleId.
/// Returns an empty Uint8List when no image exists (hasImage = false).
final vehicleImageProvider =
    FutureProvider.family<Uint8List, String>((ref, vehicleId) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchVehicleImage(vehicleId);
});

class VehicleImageNotifier extends StateNotifier<AsyncValue<Uint8List?>> {
  VehicleImageNotifier(this._api, this._vehicleId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final ApiService _api;
  final String _vehicleId;

  Future<void> _load() async {
    try {
      final bytes = await _api.fetchVehicleImage(_vehicleId);
      state = AsyncValue.data(bytes.isEmpty ? null : bytes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> upload(File file) async {
    await _api.uploadVehicleImage(_vehicleId, file);
    await _load();
  }

  Future<void> delete() async {
    await _api.deleteVehicleImage(_vehicleId);
    state = const AsyncValue.data(null);
  }
}

final vehicleImageNotifierProvider = StateNotifierProvider.family<
    VehicleImageNotifier, AsyncValue<Uint8List?>, String>(
  (ref, vehicleId) =>
      VehicleImageNotifier(ref.read(apiServiceProvider), vehicleId),
);

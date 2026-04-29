import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../core/network/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class VehiclesState {
  const VehiclesState({
    this.vehicles = const [],
    this.isLoading = false,
    this.error,
  });

  final List<VehicleModel> vehicles;
  final bool isLoading;
  final String? error;

  VehiclesState copyWith({
    List<VehicleModel>? vehicles,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      VehiclesState(
        vehicles: vehicles ?? this.vehicles,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class VehiclesNotifier extends StateNotifier<VehiclesState> {
  VehiclesNotifier(this._api) : super(const VehiclesState());

  final ApiService _api;

  Future<void> loadVehicles() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final vehicles = await _api.getVehicles();
      state = state.copyWith(vehicles: vehicles, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load vehicles',
      );
    }
  }

  Future<VehicleModel?> addVehicle(Map<String, dynamic> data) async {
    try {
      final vehicle = await _api.createVehicle(data);
      state = state.copyWith(vehicles: [...state.vehicles, vehicle]);
      return vehicle;
    } catch (e) {
      state = state.copyWith(error: 'Failed to add vehicle');
      return null;
    }
  }

  Future<void> removeVehicle(String id) async {
    try {
      await _api.deleteVehicle(id);
      state = state.copyWith(
        vehicles: state.vehicles.where((v) => v.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete vehicle');
    }
  }
}

final vehiclesProvider =
    StateNotifierProvider<VehiclesNotifier, VehiclesState>(
  (ref) => VehiclesNotifier(ref.read(apiServiceProvider)),
);

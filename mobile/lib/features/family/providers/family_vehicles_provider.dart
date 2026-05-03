import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../core/network/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class FamilyVehiclesState {
  const FamilyVehiclesState({
    this.vehicles = const [],
    this.isLoading = false,
    this.error,
  });

  final List<VehicleModel> vehicles;
  final bool isLoading;
  final String? error;

  FamilyVehiclesState copyWith({
    List<VehicleModel>? vehicles,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      FamilyVehiclesState(
        vehicles: vehicles ?? this.vehicles,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class FamilyVehiclesNotifier
    extends StateNotifier<FamilyVehiclesState> {
  FamilyVehiclesNotifier(this._api, this._memberId)
      : super(const FamilyVehiclesState());

  final ApiService _api;
  final String _memberId;

  Future<void> load() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final vehicles = await _api.getFamilyMemberVehicles(_memberId);
      state = state.copyWith(vehicles: vehicles, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load vehicles',
      );
    }
  }
}

final familyVehiclesProvider = StateNotifierProviderFamily<
    FamilyVehiclesNotifier, FamilyVehiclesState, String>(
  (ref, memberId) =>
      FamilyVehiclesNotifier(ref.read(apiServiceProvider), memberId),
);

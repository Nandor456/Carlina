import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/family_member_model.dart';
import '../../../core/network/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'family_vehicles_provider.dart';

class FamilyState {
  const FamilyState({
    this.members = const [],
    this.receivedInvites = const [],
    this.sentInvites = const [],
    this.isLoading = false,
    this.error,
  });

  final List<FamilyMemberModel> members;
  final List<FamilyMemberModel> receivedInvites;
  final List<FamilyMemberModel> sentInvites;
  final bool isLoading;
  final String? error;

  FamilyState copyWith({
    List<FamilyMemberModel>? members,
    List<FamilyMemberModel>? receivedInvites,
    List<FamilyMemberModel>? sentInvites,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      FamilyState(
        members: members ?? this.members,
        receivedInvites: receivedInvites ?? this.receivedInvites,
        sentInvites: sentInvites ?? this.sentInvites,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class FamilyNotifier extends StateNotifier<FamilyState> {
  FamilyNotifier(this._api, this._ref) : super(const FamilyState());

  final ApiService _api;
  final Ref _ref;

  Future<void> load() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final results = await Future.wait([
        _api.getFamilyMembers(),
        _api.getReceivedInvites(),
        _api.getSentInvites(),
      ]);
      final members = results[0];
      state = state.copyWith(
        members: members,
        receivedInvites: results[1],
        sentInvites: results[2],
        isLoading: false,
      );
      // Fetch fresh vehicles for each member in parallel.
      for (final m in members) {
        // ignore: discarded_futures
        _ref.read(familyVehiclesProvider(m.id).notifier).load();
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load family');
    }
  }

  Future<String?> sendInvite(String email) async {
    try {
      await _api.sendFamilyInvite(email);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to send invite';
    }
  }

  Future<void> acceptInvite(String linkId) async {
    try {
      await _api.acceptFamilyInvite(linkId);
      await load();
    } catch (_) {
      state = state.copyWith(error: 'Failed to accept invite');
    }
  }

  Future<void> declineInvite(String linkId) async {
    try {
      await _api.declineFamilyInvite(linkId);
      state = state.copyWith(
        receivedInvites:
            state.receivedInvites.where((m) => m.linkId != linkId).toList(),
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to decline invite');
    }
  }

  Future<void> removeMember(String linkId) async {
    try {
      await _api.removeFamilyMember(linkId);
      state = state.copyWith(
        members: state.members.where((m) => m.linkId != linkId).toList(),
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to remove member');
    }
  }
}

final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyState>(
  (ref) => FamilyNotifier(ref.read(apiServiceProvider), ref),
);

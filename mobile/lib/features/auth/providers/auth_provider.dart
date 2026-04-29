import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_service.dart';

// ── Singleton API service ────────────────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ── Auth state ───────────────────────────────────────────────
class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});

  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    Map<String, dynamic>? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) =>
      AuthState(
        user: clearUser ? null : user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api) : super(const AuthState()) {
    _loadCurrentUser();
  }

  final ApiService _api;

  Future<void> _loadCurrentUser() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final user = await _api.getMe();
      state = state.copyWith(user: user, isLoading: false);
    } catch (_) {
      // Not authenticated yet — that's fine
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final user = await _api.login(email: email, password: password);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String? fullName) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final user = await _api.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    state = const AuthState();
  }

  String _extractError(Object e) =>
      e.toString().contains('409') ? 'Email already in use' : 'An error occurred. Please try again.';
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(apiServiceProvider)),
);

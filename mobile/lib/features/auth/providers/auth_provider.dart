import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_service.dart';

// ── Cookie jar (overridden in main() with PersistCookieJar) ──
final cookieJarProvider = Provider<CookieJar>(
  (ref) => throw UnimplementedError('cookieJarProvider must be overridden'),
);

// ── Singleton API service ────────────────────────────────────
final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(cookieJar: ref.watch(cookieJarProvider)),
);

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  final clientId = kIsWeb
      ? ApiConstants.googleWebClientId
      : switch (defaultTargetPlatform) {
          TargetPlatform.iOS ||
          TargetPlatform.macOS => ApiConstants.googleIosClientId,
          _ => '',
        };

  return GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: clientId.isEmpty ? null : clientId,
    serverClientId: ApiConstants.googleWebClientId.isEmpty
        ? null
        : ApiConstants.googleWebClientId,
  );
});

// ── Auth state ───────────────────────────────────────────────
@immutable
class AuthState {
  const AuthState({
    this.user,
    this.isInitializing = true,
    this.isLoading = false,
    this.error,
  });

  /// Current user, or null if anonymous.
  final UserModel? user;

  /// True until the initial /me check completes. Used to gate routing.
  final bool isInitializing;

  /// True while a login/register/logout call is in flight.
  final bool isLoading;

  /// Last error message from a failed auth call (null on success).
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool clearUser = false,
    bool? isInitializing,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => AuthState(
    user: clearUser ? null : (user ?? this.user),
    isInitializing: isInitializing ?? this.isInitializing,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api, this._googleSignIn) : super(const AuthState()) {
    _bootstrap();
  }

  final ApiService _api;
  final GoogleSignIn _googleSignIn;

  /// Called once on app start. Reads any persisted session cookie and tries
  /// to fetch the current user. Whether it succeeds or fails, isInitializing
  /// flips to false so the router can decide where to send the user.
  Future<void> _bootstrap() async {
    try {
      final json = await _api.getMe();
      state = state.copyWith(
        user: json == null ? null : UserModel.fromJson(json),
        clearUser: json == null,
        isInitializing: false,
      );
    } catch (_) {
      state = state.copyWith(clearUser: true, isInitializing: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final json = await _api.login(email: email, password: password);
      state = state.copyWith(user: UserModel.fromJson(json), isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.statusCode == 401 ? 'Wrong email or password' : e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error — is the API running?',
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String? fullName) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final json = await _api.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = state.copyWith(user: UserModel.fromJson(json), isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.statusCode == 409 ? 'Email already in use' : e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error — is the API running?',
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Google sign-in did not return an ID token',
        );
        return false;
      }

      final json = await _api.loginWithGoogle(idToken: idToken);
      state = state.copyWith(user: UserModel.fromJson(json), isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Google sign-in failed');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Ignore — we want to clear local state regardless
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore — local API session state is the source of truth.
    }
    state = const AuthState(isInitializing: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(googleSignInProvider),
  ),
);

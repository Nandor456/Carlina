import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_service.dart';

// ── Token storage ────────────────────────────────────────────

class TokenStorage {
  const TokenStorage(this._storage);
  final FlutterSecureStorage _storage;
  static const _key = 'auth_token';

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<void> delete() => _storage.delete(key: _key);
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => throw UnimplementedError('tokenStorageProvider must be overridden'),
);

// ── Singleton API service ────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

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

  final UserModel? user;
  final bool isInitializing;
  final bool isLoading;
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
  AuthNotifier(this._api, this._tokenStorage, this._googleSignIn)
      : super(const AuthState()) {
    _bootstrap();
  }

  final ApiService _api;
  final TokenStorage _tokenStorage;
  final GoogleSignIn _googleSignIn;

  /// On app start: load any persisted token, validate it via /me, then ungate routing.
  Future<void> _bootstrap() async {
    try {
      final token = await _tokenStorage.read();
      if (token != null) {
        _api.setToken(token);
        final json = await _api.getMe();
        if (json != null) {
          state = state.copyWith(
            user: UserModel.fromJson(json),
            isInitializing: false,
          );
          unawaited(_registerFcmToken());
          return;
        }
        // Token rejected — clear it
        await _tokenStorage.delete();
        _api.setToken(null);
      }
    } catch (_) {}
    state = state.copyWith(clearUser: true, isInitializing: false);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final json = await _api.login(email: email, password: password);
      await _persistToken(json);
      state = state.copyWith(user: UserModel.fromJson(json), isLoading: false);
      unawaited(_registerFcmToken());
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

  Future<bool> register(
    String email,
    String password,
    String passwordConfirm,
    String? fullName,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final json = await _api.register(
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        fullName: fullName,
      );
      await _persistToken(json);
      state = state.copyWith(user: UserModel.fromJson(json), isLoading: false);
      unawaited(_registerFcmToken());
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
      await _persistToken(json);
      state = state.copyWith(user: UserModel.fromJson(json), isLoading: false);
      unawaited(_registerFcmToken());
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
    await _tokenStorage.delete();
    _api.setToken(null);
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    state = const AuthState(isInitializing: false);
  }

  Future<void> _persistToken(Map<String, dynamic> json) async {
    final token = json['accessToken'] as String?;
    if (token != null) {
      await _tokenStorage.write(token);
      _api.setToken(token);
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final fcmToken = await messaging.getToken();
      if (fcmToken != null) await _api.registerFcmToken(fcmToken);
    } catch (_) {}
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(googleSignInProvider),
  ),
);

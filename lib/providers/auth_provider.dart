import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/service_region.dart';
import '../models/worker_profile.dart';
import '../services/api_client.dart';
import '../services/job_socket_service.dart';
import '../services/mock_data_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  final socket = ref.watch(jobSocketServiceProvider);
  return AuthNotifier(api, socket);
});

class AuthState {
  final WorkerProfile? profile;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.profile,
    this.isAuthenticated = false,
    this.isLoading = true,
    this.error,
  });

  AuthState copyWith({
    WorkerProfile? profile,
    bool clearProfile = false,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      profile: clearProfile ? null : (profile ?? this.profile),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      // Preserve previous message unless explicitly replaced/cleared.
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  final JobSocketService _socket;

  AuthNotifier(this._api, this._socket) : super(const AuthState()) {
    _bootstrap();
  }

  /// Restore session from stored token -> GET /workers/me.
  Future<void> _bootstrap() async {
    try {
      final hasToken = await _api.hasToken.timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (!hasToken) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final profile = await _api.getProfile().timeout(const Duration(seconds: 4));
      state = state.copyWith(
        profile: profile,
        isAuthenticated: true,
        isLoading: false,
      );
      _connectSocket(profile.id);
    } catch (_) {
      await _api.clearToken();
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        clearError: true,
      );
    }
  }

  Future<bool> login(String phoneDigits, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _api.login(phoneDigits, password);
      final profile = await _resolveProfile(
        fallbackName: user?['name']?.toString() ?? 'Partner',
        fallbackPhone: phoneDigits,
      );
      state = state.copyWith(
        profile: profile,
        isAuthenticated: true,
        isLoading: false,
        clearError: true,
      );
      _connectSocket(profile.id);
      return true;
    } catch (e) {
      String msg = 'Login failed. Check your number and password.';
      if (_isConnectionError(e)) {
        msg = 'Cannot reach the server. Check your connection.';
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<bool> registerWorker({
    required String name,
    required String phoneDigits,
    required String password,
    List<String> skills = const [],
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.register(
        name,
        phoneDigits,
        password,
        skills: skills,
        lat: ServiceRegion.defaultCenterLat,
        lng: ServiceRegion.defaultCenterLng,
      );
      var profile = await _resolveProfile(
        fallbackName: name,
        fallbackPhone: phoneDigits,
        fallbackSkills: skills,
      );
      if (skills.isNotEmpty && profile.skills.isEmpty) {
        profile = profile.copyWith(skills: skills);
      }
      state = state.copyWith(
        profile: profile,
        isAuthenticated: true,
        isLoading: false,
        clearError: true,
      );
      _connectSocket(profile.id);
      return true;
    } catch (e) {
      String msg =
          'Registration failed. That number may already be registered.';
      if (_isConnectionError(e)) {
        msg = 'Cannot reach the server. Check your connection.';
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<WorkerProfile> _resolveProfile({
    required String fallbackName,
    required String fallbackPhone,
    List<String> fallbackSkills = const [],
  }) async {
    try {
      return await _api.getProfile();
    } catch (_) {
      // TokenResponse.user may arrive before a worker record exists.
      return WorkerProfile(
        id: 'w_${DateTime.now().millisecondsSinceEpoch}',
        name: fallbackName,
        phone: fallbackPhone,
        skills: fallbackSkills,
        latitude: ServiceRegion.defaultCenterLat,
        longitude: ServiceRegion.defaultCenterLng,
      );
    }
  }

  static bool _isConnectionError(Object e) =>
      e.toString().contains('Connection') ||
      e.toString().contains('SocketException');

  void _connectSocket(String workerId) {
    try {
      // Realtime dispatch requires the JWT handshake (server rejects
      // unauthenticated sockets); demo sessions have no token, so skip.
      _api.getToken().then((token) {
        if (token == null || token.isEmpty) return;
        _socket.connect(workerId, token: token);
      }).catchError((_) {/* realtime is best-effort */});
    } catch (_) {/* realtime is best-effort */}
  }

  /// Local demo session for offline presentations (no token).
  void enterDemoMode() {
    const demo = MockDataService.demoWorkerProfile;
    state = state.copyWith(
      profile: demo,
      isAuthenticated: true,
      isLoading: false,
      clearError: true,
    );
    _connectSocket(demo.id);
  }

  Future<void> logout() async {
    await _api.clearToken();
    _socket.disconnect();
    state = const AuthState(isLoading: false);
  }
}

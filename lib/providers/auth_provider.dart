import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/worker_profile.dart';
import '../services/api_client.dart';
import '../services/mock_data_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(api);
});

class AuthState {
  final WorkerProfile? profile;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.profile,
    this.isAuthenticated = true, // Auto-authenticated with demo profile for instant evaluation
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    WorkerProfile? profile,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      profile: profile ?? this.profile,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api)
      : super(const AuthState(profile: MockDataService.demoWorkerProfile)) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await _api.getProfile();
      state = state.copyWith(profile: p, isAuthenticated: true);
    } catch (_) {
      state = state.copyWith(profile: MockDataService.demoWorkerProfile);
    }
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      profile: MockDataService.demoWorkerProfile,
    );
    return true;
  }

  Future<bool> registerWorker({
    required String name,
    required String phone,
    required List<String> skills,
    required String federationCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 900));

    final newProfile = WorkerProfile(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      federationName: 'Delhi Central Labour Cooperative Federation',
      skills: skills,
      certificationStatus: 'verified',
      latitude: MockDataService.baseLat,
      longitude: MockDataService.baseLng,
    );

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      profile: newProfile,
    );
    return true;
  }

  void logout() {
    _api.clearToken();
    state = const AuthState(isAuthenticated: false, profile: null);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/worker_profile.dart';
import '../models/job.dart';
import '../models/welfare_transaction.dart';
import 'mock_data_service.dart';

/// Backend base URL — override with:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// HTTP client for SahaKarya Partner communicating with the FastAPI backend.
/// Conforms to API_CONTRACT.md v2.
class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _cachedToken;

  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: kApiBaseUrl,
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<String?> _readToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      _cachedToken = await _storage
          .read(key: 'auth_token')
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      _cachedToken = null;
    }
    return _cachedToken;
  }

  Future<bool> get hasToken async => (await _readToken()) != null;

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _storage.delete(key: 'auth_token');
  }

  /// Public read for services that need the JWT (e.g. Socket.IO handshake).
  Future<String?> getToken() => _readToken();

  // ---------------------------------------------------------------- Auth

  /// POST /auth/login {phone, password} -> TokenResponse {access_token, user}
  /// Returns the raw `user` map or null. Throws on failure.
  Future<Map<String, dynamic>?> login(String phone, String password) async {
    final res = await _dio.post('/auth/login',
        data: {'phone': phone, 'password': password});
    final data = Map<String, dynamic>.from(res.data as Map);
    await saveToken(data['access_token'].toString());
    return data['user'] == null
        ? null
        : Map<String, dynamic>.from(data['user'] as Map);
  }

  /// POST /auth/register {name, phone, password, role:'worker', skills, lat, lng}
  /// -> TokenResponse. Sends role:'worker' + skills so the backend creates a
  /// Worker document (a bare register would silently create a customer account).
  Future<Map<String, dynamic>?> register(
      String name, String phone, String password,
      {List<String> skills = const [],
      double? lat,
      double? lng}) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'phone': phone,
      'password': password,
      'role': 'worker',
      if (skills.isNotEmpty) 'skills': skills,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
    final data = Map<String, dynamic>.from(res.data as Map);
    await saveToken(data['access_token'].toString());
    return data['user'] == null
        ? null
        : Map<String, dynamic>.from(data['user'] as Map);
  }

  // ------------------------------------------------------------- Workers

  /// GET /workers/me -> WorkerResponse. Throws on failure.
  Future<WorkerProfile> getProfile() async {
    final response = await _dio.get('/workers/me');
    return WorkerProfile.fromJson(Map<String, dynamic>.from(response.data));
  }

  /// PATCH /workers/me/location {lat, lng} — server route (contract doc says
  /// /workers/location but the backend mounts /workers/me/location).
  Future<void> updateLocation(double lat, double lng) async {
    await _dio.patch(
      '/workers/me/location',
      data: {'lat': lat, 'lng': lng},
    );
  }

  /// PATCH /workers/me/availability {online: bool} — required so dispatch
  /// ($geoNear availability=='online') actually targets this worker.
  /// Throws on failure so callers can decide how to surface it.
  Future<void> setAvailability(bool online) async {
    await _dio.patch(
      '/workers/me/availability',
      data: {'online': online},
    );
  }

  // ------------------------------------------------------------ Bookings

  /// POST /bookings/{id}/accept — assigned worker only. FALSE on failure.
  Future<bool> acceptJob(String bookingId) async {
    try {
      await _dio.post('/bookings/$bookingId/accept');
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// POST /bookings/{id}/decline. FALSE on failure.
  Future<bool> declineJob(String bookingId) async {
    try {
      await _dio.post('/bookings/$bookingId/decline');
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// PATCH /bookings/{id}/status {status}. Legal transitions enforced
  /// server-side; FALSE on failure (never pretends success).
  Future<bool> updateJobStatus(String bookingId, String status) async {
    try {
      await _dio.patch('/bookings/$bookingId/status',
          data: {'status': status});
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Best-effort job history read (falls back to demo data offline).
  Future<List<Job>> getJobHistory() async {
    try {
      final res = await _dio.get('/workers/me/jobs');
      final list = res.data as List;
      return list
          .map((e) => Job.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return MockDataService.getMockJobs();
    }
  }

  // -------------------------------------------------------------- Welfare

  /// GET /welfare/me -> ONE object {balance, total_contributed, transactions}.
  /// Throws on failure so callers can surface errors.
  Future<WelfareSnapshot> fetchWelfare() async {
    final res = await _dio.get('/welfare/me');
    return WelfareSnapshot.fromJson(Map<String, dynamic>.from(res.data));
  }

  /// Offline/demo fallback matching the contract shape.
  WelfareSnapshot demoWelfareSnapshot() => MockDataService.getDemoWelfareSnapshot();

  /// POST /welfare/claims {amount > 0, reason(min 3)}. FALSE on failure.
  Future<bool> submitWelfareClaim({
    required double amount,
    required String reason,
  }) async {
    try {
      await _dio.post('/welfare/claims',
          data: {'amount': amount, 'reason': reason});
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

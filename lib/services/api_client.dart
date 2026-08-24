import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/worker_profile.dart';
import '../models/job.dart';
import '../models/welfare_transaction.dart';
import 'mock_data_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// HTTP client for SahaKarya Partner communicating with FastAPI backend.
class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _baseUrl = 'http://localhost:8000';
  bool useMockFallback = true;

  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
              headers: {'Content-Type': 'application/json'},
            )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<WorkerProfile> getProfile() async {
    try {
      final response = await _dio.get('/workers/me');
      return WorkerProfile.fromJson(response.data);
    } catch (_) {
      // DEMO DATA — fallback for offline demo presentations
      return MockDataService.demoWorkerProfile;
    }
  }

  Future<void> updateAvailability(bool isOnline) async {
    try {
      await _dio.patch('/workers/me/availability', data: {'online': isOnline});
    } catch (_) {
      // Ignore network errors in demo
    }
  }

  Future<void> updateLocation(double lat, double lng) async {
    try {
      await _dio.patch(
        '/workers/me/location',
        data: {'latitude': lat, 'longitude': lng},
      );
    } catch (_) {
      // Ignore network errors in demo
    }
  }

  Future<bool> acceptJob(String bookingId) async {
    try {
      await _dio.post('/bookings/$bookingId/accept');
      return true;
    } catch (_) {
      return true; // Demo fallback
    }
  }

  Future<bool> declineJob(String bookingId) async {
    try {
      await _dio.post('/bookings/$bookingId/decline');
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> updateJobStatus(String bookingId, String status) async {
    try {
      await _dio.patch('/bookings/$bookingId/status', data: {'status': status});
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<List<Job>> getJobHistory() async {
    try {
      final res = await _dio.get('/workers/me/jobs');
      final list = res.data as List;
      return list.map((e) => Job.fromJson(e)).toList();
    } catch (_) {
      return MockDataService.getMockJobs();
    }
  }

  Future<List<WelfareTransaction>> getWelfareTransactions() async {
    try {
      final res = await _dio.get('/welfare/me');
      final list = res.data as List;
      return list.map((e) => WelfareTransaction.fromJson(e)).toList();
    } catch (_) {
      return MockDataService.getMockWelfareTransactions();
    }
  }

  Future<bool> submitWelfareClaim({
    required String category,
    required double amount,
    required String reason,
  }) async {
    try {
      await _dio.post(
        '/welfare/me/claim',
        data: {'claim_category': category, 'amount': amount, 'description': reason},
      );
      return true;
    } catch (_) {
      return true;
    }
  }
}

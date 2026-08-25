import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/job.dart';
import 'api_client.dart';

final jobSocketServiceProvider = Provider<JobSocketService>((ref) {
  final service = JobSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Socket.IO realtime dispatch service (API_CONTRACT.md §Socket.IO).
///
/// - Connects to the same base URL as the REST API.
/// - Emits `join_worker` {worker_id} on EVERY successful connect/reconnect
///   so the server re-joins room `worker_{id}`.
/// - Listens for the exact server event `job_offer`.
/// - Retries with exponential backoff on disconnect/connect errors.
class JobSocketService {
  io.Socket? _socket;
  String? _workerId;
  String? _token;
  Timer? _retryTimer;
  int _retryAttempt = 0;
  bool _disposed = false;
  bool _shouldStayConnected = false;

  static const Duration _maxBackoff = Duration(seconds: 15);

  final StreamController<Job> _offerController =
      StreamController<Job>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<Job> get jobOffers => _offerController.stream;
  Stream<bool> get connectionState => _connectionController.stream;
  bool isConnected = false;

  /// Idempotent connect. Re-calling with the same worker id is a no-op while
  /// connected; calling after [disconnect] reconnects. The JWT travels in the
  /// Socket.IO handshake `auth` payload — the server refuses connections
  /// without a valid token.
  void connect(String workerId, {required String token}) {
    if (_disposed) return;
    if (_shouldStayConnected && _workerId == workerId && _token == token && _socket != null) {
      return;
    }
    _workerId = workerId;
    _token = token;
    _shouldStayConnected = true;
    _retryAttempt = 0;
    _openSocket();
  }

  void _openSocket() {
    _retryTimer?.cancel();
    try {
      _socket?.dispose();
    } catch (_) {}
    _socket = null;

    try {
      final socket = io.io(
        kApiBaseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': _token})
            .disableAutoConnect()
            .build(),
      );
      _socket = socket;

      socket.onConnect((_) {
        isConnected = true;
        _retryAttempt = 0;
        _connectionController.add(true);
        // Join the worker room after connect AND after every reconnect.
        socket.emit('join_worker', {'worker_id': _workerId});
      });

      // Exact server event name per contract: `job_offer`.
      socket.on('job_offer', (data) {
        if (data is Map) {
          try {
            final job = Job.fromJson(Map<String, dynamic>.from(data));
            _offerController.add(job);
          } catch (_) {/* malformed payload ignored */}
        }
      });

      socket.onDisconnect((_) {
        isConnected = false;
        _connectionController.add(false);
        _scheduleRetry();
      });

      socket.onConnectError((_) => _scheduleRetry());
      socket.onError((_) => _scheduleRetry());

      socket.connect();
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_disposed || !_shouldStayConnected) return;
    _retryTimer?.cancel();
    _retryAttempt += 1;
    final seconds = (0.5 * (1 << _retryAttempt.clamp(0, 5)))
        .clamp(0.5, _maxBackoff.inSeconds.toDouble());
    _retryTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () {
      if (!_disposed && _shouldStayConnected && !isConnected) {
        _openSocket();
      }
    });
  }

  void disconnect() {
    _shouldStayConnected = false;
    _token = null;
    _retryTimer?.cancel();
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    if (isConnected) {
      isConnected = false;
      _connectionController.add(false);
    }
  }

  /// Local demo hook — pushes a fake offer through the same stream as real ones.
  void simulateIncomingJob(Job job) => _offerController.add(job);

  void dispose() {
    _disposed = true;
    disconnect();
    _offerController.close();
    _connectionController.close();
  }
}

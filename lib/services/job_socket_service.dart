import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/job.dart';

final jobSocketServiceProvider = Provider<JobSocketService>((ref) {
  final service = JobSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Socket.IO service to receive real-time incoming job offers from the FastAPI server.
class JobSocketService {
  IO.Socket? _socket;
  final StreamController<Job> _jobOfferController =
      StreamController<Job>.broadcast();

  Stream<Job> get jobOffers => _jobOfferController.stream;
  bool isConnected = false;

  void connect(String workerId) {
    if (_socket != null && _socket!.connected) return;

    try {
      _socket = IO.io(
        'http://localhost:8000',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setQuery({'worker_id': workerId, 'role': 'worker'})
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        isConnected = true;
      });

      _socket?.on('new_job_offer', (data) {
        if (data != null && data is Map<String, dynamic>) {
          final job = Job.fromJson(data);
          _jobOfferController.add(job);
        }
      });

      _socket?.onDisconnect((_) {
        isConnected = false;
      });
    } catch (_) {
      // Offline fallback
    }
  }

  /// Manually dispatch a mock incoming job offer for interactive live demo testing
  void simulateIncomingJob(Job job) {
    _jobOfferController.add(job);
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _jobOfferController.close();
  }
}

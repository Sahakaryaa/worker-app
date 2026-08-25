import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job.dart';
import '../services/api_client.dart';
import '../services/job_socket_service.dart';
import '../services/mock_data_service.dart';
import 'active_job_provider.dart';

final incomingJobProvider =
    StateNotifierProvider<IncomingJobNotifier, JobOfferState>((ref) {
  final socket = ref.watch(jobSocketServiceProvider);
  final api = ref.watch(apiClientProvider);
  return IncomingJobNotifier(socket, api, ref);
});

class JobOfferState {
  final Job? currentOffer;
  final int secondsRemaining;
  final bool isCountingDown;

  /// Last action error, consumed + cleared by the UI (snackbar).
  final String? lastError;
  final int errorStamp;

  const JobOfferState({
    this.currentOffer,
    this.secondsRemaining = kOfferCountdownSeconds,
    this.isCountingDown = false,
    this.lastError,
    this.errorStamp = 0,
  });

  JobOfferState copyWith({
    Job? currentOffer,
    bool clearOffer = false,
    int? secondsRemaining,
    bool? isCountingDown,
    String? lastError,
    int? errorStamp,
    bool clearError = false,
  }) {
    return JobOfferState(
      currentOffer: clearOffer ? null : (currentOffer ?? this.currentOffer),
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isCountingDown: isCountingDown ?? this.isCountingDown,
      lastError: clearError ? null : (lastError ?? this.lastError),
      errorStamp: errorStamp ?? this.errorStamp,
    );
  }
}

const int kOfferCountdownSeconds = 60;

class IncomingJobNotifier extends StateNotifier<JobOfferState> {
  final JobSocketService _socket;
  final ApiClient _api;
  final Ref _ref;
  Timer? _countdownTimer;
  StreamSubscription<Job>? _socketSub;

  IncomingJobNotifier(this._socket, this._api, this._ref)
      : super(const JobOfferState()) {
    // Single app-wide listener — offers flow regardless of which tab is open.
    _socketSub = _socket.jobOffers.listen(receiveOffer);
  }

  /// Auto-decline ONLY when the countdown hits zero.
  void receiveOffer(Job job) {
    state = JobOfferState(
      currentOffer: job,
      secondsRemaining: kOfferCountdownSeconds,
    );
    _startCountdown(from: kOfferCountdownSeconds);
  }

  void triggerDemoOffer({bool isEmergency = false}) {
    receiveOffer(MockDataService.getDemoIncomingJob(isEmergency: isEmergency));
  }

  Future<void> acceptCurrentOffer() async {
    final job = state.currentOffer;
    if (job == null) return;
    _countdownTimer?.cancel();

    final isDemo = job.id.startsWith('job_') || job.bookingId.startsWith('b_');
    bool ok = true;
    if (!isDemo) {
      ok = await _api.acceptJob(job.bookingId);
    } else {
      // Best effort network call in demo mode
      _api.acceptJob(job.bookingId).ignore();
    }

    if (!ok) {
      // Surface failure; do NOT flip any state to accepted.
      // Resume the countdown so the worker can retry (auto-decline at zero).
      state = state.copyWith(
        lastError: 'Could not accept — check your connection.',
        errorStamp: DateTime.now().millisecondsSinceEpoch,
      );
      _startCountdown(from: state.secondsRemaining);
      return;
    }

    state = state.copyWith(clearOffer: true, isCountingDown: false);
    _ref.read(activeJobProvider.notifier).setActiveJob(
          job.copyWith(status: JobStatus.accepted),
        );
  }

  void _startCountdown({required int from}) {
    _countdownTimer?.cancel();
    var remaining = from <= 0 ? kOfferCountdownSeconds : from;
    state = state.copyWith(secondsRemaining: remaining, isCountingDown: true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isCountingDown) {
        timer.cancel();
        return;
      }
      if (remaining > 1) {
        remaining -= 1;
        state = state.copyWith(secondsRemaining: remaining);
      } else {
        timer.cancel();
        declineCurrentOffer(autoDeclined: true);
      }
    });
  }

  Future<void> declineCurrentOffer({bool autoDeclined = false}) async {
    final job = state.currentOffer;
    if (job == null) return;
    _countdownTimer?.cancel();
    state = state.copyWith(clearOffer: true, isCountingDown: false);

    final isDemo = job.id.startsWith('job_') || job.bookingId.startsWith('b_');
    if (!isDemo) {
      final ok = await _api.declineJob(job.bookingId);
      if (!ok && !autoDeclined) {
        state = state.copyWith(
          lastError: 'Could not reach server to decline the job.',
          errorStamp: DateTime.now().millisecondsSinceEpoch,
        );
      }
    } else {
      _api.declineJob(job.bookingId).ignore();
    }
  }

  void consumeError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _socketSub?.cancel();
    super.dispose();
  }
}

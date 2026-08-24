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

  const JobOfferState({
    this.currentOffer,
    this.secondsRemaining = 30,
    this.isCountingDown = false,
  });

  JobOfferState copyWith({
    Job? currentOffer,
    int? secondsRemaining,
    bool? isCountingDown,
    bool clearOffer = false,
  }) {
    return JobOfferState(
      currentOffer: clearOffer ? null : (currentOffer ?? this.currentOffer),
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isCountingDown: isCountingDown ?? this.isCountingDown,
    );
  }
}

class IncomingJobNotifier extends StateNotifier<JobOfferState> {
  final JobSocketService _socket;
  final ApiClient _api;
  final Ref _ref;
  Timer? _countdownTimer;
  StreamSubscription? _socketSub;

  IncomingJobNotifier(this._socket, this._api, this._ref)
      : super(const JobOfferState()) {
    _socketSub = _socket.jobOffers.listen((job) {
      receiveOffer(job);
    });
  }

  void receiveOffer(Job job) {
    _countdownTimer?.cancel();
    state = JobOfferState(
      currentOffer: job,
      secondsRemaining: 30,
      isCountingDown: true,
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining > 1) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      } else {
        declineCurrentOffer();
      }
    });
  }

  void triggerDemoOffer({bool isEmergency = false}) {
    final demoJob = MockDataService.getDemoIncomingJob(isEmergency: isEmergency);
    receiveOffer(demoJob);
  }

  Future<void> acceptCurrentOffer() async {
    final job = state.currentOffer;
    if (job == null) return;

    _countdownTimer?.cancel();
    state = state.copyWith(clearOffer: true, isCountingDown: false);

    await _api.acceptJob(job.bookingId);
    _ref.read(activeJobProvider.notifier).setActiveJob(
          job.copyWith(status: JobStatus.matched),
        );
  }

  Future<void> declineCurrentOffer() async {
    final job = state.currentOffer;
    _countdownTimer?.cancel();
    state = state.copyWith(clearOffer: true, isCountingDown: false);
    if (job != null) {
      await _api.declineJob(job.bookingId);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _socketSub?.cancel();
    super.dispose();
  }
}

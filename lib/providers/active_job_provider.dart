import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job.dart';
import '../services/api_client.dart';
import 'earnings_provider.dart';
import 'welfare_provider.dart';

final activeJobProvider =
    StateNotifierProvider<ActiveJobNotifier, ActiveJobState>((ref) {
  final api = ref.watch(apiClientProvider);
  return ActiveJobNotifier(api, ref);
});

class ActiveJobState {
  final Job? job;
  final bool busy;

  /// Last action error for snackbar surfacing (never silently swallowed).
  final String? error;
  final int errorStamp;
  final bool justCompleted;

  const ActiveJobState({
    this.job,
    this.busy = false,
    this.error,
    this.errorStamp = 0,
    this.justCompleted = false,
  });

  ActiveJobState copyWith({
    Job? job,
    bool clearJob = false,
    bool? busy,
    String? error,
    int? errorStamp,
    bool clearError = false,
    bool? justCompleted,
    bool clearJustCompleted = false,
  }) {
    return ActiveJobState(
      job: clearJob ? null : (job ?? this.job),
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      errorStamp: errorStamp ?? this.errorStamp,
      justCompleted:
          clearJustCompleted ? false : (justCompleted ?? this.justCompleted),
    );
  }
}

/// Full contract lifecycle: accepted -> en_route -> arrived -> started ->
/// completed. Server enforces legal transitions; we NEVER optimistically
/// flip state on failure — errors are surfaced via [ActiveJobState.error].
class ActiveJobNotifier extends StateNotifier<ActiveJobState> {
  final ApiClient _api;
  final Ref _ref;

  ActiveJobNotifier(this._api, this._ref) : super(const ActiveJobState());

  void setActiveJob(Job job) {
    state = ActiveJobState(job: job.copyWith(status: JobStatus.accepted));
  }

  Future<bool> startEnRoute() => _advance(JobStatus.enRoute);

  /// 'arrived' is a VALID contract status.
  Future<bool> markArrived() => _advance(JobStatus.arrived);

  Future<bool> startWork() => _advance(JobStatus.started);

  Future<bool> completeJob() async {
    final job = state.job;
    if (job == null || state.busy) return false;
    state = state.copyWith(busy: true, clearError: true);

    // Backend deducts the 5% welfare contribution at completion.
    final ok = await _api.updateJobStatus(
        job.bookingId, JobStatus.completed.apiValue);
    if (!ok) {
      _fail('Could not complete the job. Check your connection.');
      return false;
    }

    _ref.read(earningsProvider.notifier).recordCompletedJob(job);
    _ref.read(welfareProvider.notifier).recordContribution(
          job.welfareContribution,
          '5% welfare contribution • Booking #${_shortId(job.bookingId)}',
        );

    state = state.copyWith(
      clearJob: true,
      busy: false,
      justCompleted: true,
      errorStamp: DateTime.now().millisecondsSinceEpoch,
    );
    return true;
  }

  void acknowledgeCompletion() {
    state = state.copyWith(clearJustCompleted: true);
  }

  void cancelJob() {
    state = const ActiveJobState();
  }

  void consumeError() {
    state = state.copyWith(clearError: true);
  }

  // ---------------------------------------------------------------- internals

  Future<bool> _advance(JobStatus next) async {
    final job = state.job;
    if (job == null || state.busy) return false;
    state = state.copyWith(busy: true, clearError: true);

    final ok =
        await _api.updateJobStatus(job.bookingId, next.apiValue);
    if (!ok) {
      _fail('Could not update to "${next.label}". Check your connection.');
      return false;
    }
    state = state.copyWith(job: job.copyWith(status: next), busy: false);
    return true;
  }

  void _fail(String message) {
    state = state.copyWith(
      busy: false,
      error: message,
      errorStamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static String _shortId(String id) =>
      id.length <= 8 ? id : '${id.substring(0, 8)}…';
}

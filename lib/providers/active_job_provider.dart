import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../services/api_client.dart';
import 'earnings_provider.dart';

import 'welfare_provider.dart';

final activeJobProvider =
    StateNotifierProvider<ActiveJobNotifier, Job?>((ref) {
  final api = ref.watch(apiClientProvider);
  return ActiveJobNotifier(api, ref);
});

/// Manages active job state and status updates (arrived -> in_progress -> completed).
class ActiveJobNotifier extends StateNotifier<Job?> {
  final ApiClient _api;
  final Ref _ref;

  ActiveJobNotifier(this._api, this._ref) : super(null);

  void setActiveJob(Job job) {
    state = job;
  }

  Future<void> markArrived() async {
    if (state == null) return;
    final updated = state!.copyWith(status: JobStatus.arrived);
    state = updated;
    await _api.updateJobStatus(updated.bookingId, 'arrived');
  }

  Future<void> startWork() async {
    if (state == null) return;
    final updated = state!.copyWith(status: JobStatus.inProgress);
    state = updated;
    await _api.updateJobStatus(updated.bookingId, 'in_progress');
  }

  Future<void> completeJob() async {
    if (state == null) return;
    final completedJob = state!.copyWith(status: JobStatus.completed);
    await _api.updateJobStatus(completedJob.bookingId, 'completed');
    _ref.read(earningsProvider.notifier).recordCompletedJob(completedJob);
    _ref.read(welfareProvider.notifier).recordContribution(
          completedJob.welfareContribution,
          '1% Social Security Allocation for #${completedJob.bookingId}',
        );
    state = null;
  }

  void cancelJob() {
    state = null;
  }
}

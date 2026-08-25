import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job.dart';
import '../services/api_client.dart';
import '../services/mock_data_service.dart';

final earningsProvider =
    StateNotifierProvider<EarningsNotifier, EarningsState>((ref) {
  final api = ref.watch(apiClientProvider);
  return EarningsNotifier(api);
});

class EarningsState {
  final double todayTotal;
  final double weekTotal;
  final int completedJobsToday;
  final List<Job> jobHistory;
  final List<Map<String, dynamic>> weeklyChartData;
  final bool isLoading;

  const EarningsState({
    this.todayTotal = 0,
    this.weekTotal = 0,
    this.completedJobsToday = 0,
    this.jobHistory = const [],
    this.weeklyChartData = const [],
    this.isLoading = true,
  });

  EarningsState copyWith({
    double? todayTotal,
    double? weekTotal,
    int? completedJobsToday,
    List<Job>? jobHistory,
    List<Map<String, dynamic>>? weeklyChartData,
    bool? isLoading,
  }) {
    return EarningsState(
      todayTotal: todayTotal ?? this.todayTotal,
      weekTotal: weekTotal ?? this.weekTotal,
      completedJobsToday: completedJobsToday ?? this.completedJobsToday,
      jobHistory: jobHistory ?? this.jobHistory,
      weeklyChartData: weeklyChartData ?? this.weeklyChartData,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class EarningsNotifier extends StateNotifier<EarningsState> {
  final ApiClient _api;

  EarningsNotifier(this._api)
      : super(const EarningsState(
          weeklyChartData: MockDataService.demoWeeklyEarnings,
        )) {
    loadEarnings();
  }

  Future<void> loadEarnings() async {
    state = state.copyWith(isLoading: true);
    try {
      final jobs = await _api.getJobHistory();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // Rolling 7-day window to mirror the backend /workers/me/earnings.
      final weekStart = today.subtract(const Duration(days: 6));
      double todaySum = 0;
      double weekSum = 0;
      int completedToday = 0;
      for (final j in jobs) {
        final created = DateTime(
            j.createdAt.year, j.createdAt.month, j.createdAt.day);
        if (created.isBefore(weekStart)) continue;
        // Worker take-home = price minus the single 5% welfare contribution
        // (backend deducts at completion).
        final takeHome = j.price - j.welfareContribution;
        weekSum += takeHome;
        if (_sameDay(j.createdAt, now)) {
          todaySum += takeHome;
          completedToday += 1;
        }
      }
      state = state.copyWith(
        jobHistory: jobs,
        todayTotal: todaySum,
        weekTotal: weekSum,
        completedJobsToday: completedToday,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void recordCompletedJob(Job job) {
    final takeHome = job.price - job.welfareContribution;
    state = state.copyWith(
      todayTotal: state.todayTotal + takeHome,
      weekTotal: state.weekTotal + takeHome,
      completedJobsToday: state.completedJobsToday + 1,
      jobHistory: [job.copyWith(status: JobStatus.completed), ...state.jobHistory],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

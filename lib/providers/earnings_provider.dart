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
      final today = DateTime.now();
      final todays =
          jobs.where((j) => _sameDay(j.createdAt, today)).toList();
      double todaySum = 0;
      for (final j in todays) {
        // Worker take-home = price minus the single 5% welfare contribution
        // (backend deducts at completion).
        todaySum += j.price - j.welfareContribution;
      }
      double weekSum = todaySum;
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      for (final j in jobs) {
        if (j.createdAt.isBefore(weekStart) && !_sameDay(j.createdAt, today)) {
          continue;
        }
        if (_sameDay(j.createdAt, today)) continue;
        weekSum += j.price - j.welfareContribution;
      }
      state = state.copyWith(
        jobHistory: jobs,
        todayTotal: todaySum,
        weekTotal: weekSum,
        completedJobsToday: todays.length,
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

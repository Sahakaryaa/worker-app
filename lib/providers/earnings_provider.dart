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
    this.todayTotal = 1350.0,
    this.weekTotal = 8920.0,
    this.completedJobsToday = 3,
    this.jobHistory = const [],
    this.weeklyChartData = const [],
    this.isLoading = false,
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
      : super(EarningsState(
          jobHistory: MockDataService.getMockJobs(),
          weeklyChartData: MockDataService.getWeeklyEarnings(),
        )) {
    loadEarnings();
  }

  Future<void> loadEarnings() async {
    state = state.copyWith(isLoading: true);
    try {
      final jobs = await _api.getJobHistory();
      state = state.copyWith(
        jobHistory: jobs,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void recordCompletedJob(Job job) {
    final updatedList = [job, ...state.jobHistory];
    state = state.copyWith(
      todayTotal: state.todayTotal + job.price,
      weekTotal: state.weekTotal + job.price,
      completedJobsToday: state.completedJobsToday + 1,
      jobHistory: updatedList,
    );
  }
}

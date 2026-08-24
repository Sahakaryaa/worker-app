import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/welfare_transaction.dart';
import '../services/api_client.dart';
import '../services/mock_data_service.dart';

final welfareProvider =
    StateNotifierProvider<WelfareNotifier, WelfareState>((ref) {
  final api = ref.watch(apiClientProvider);
  return WelfareNotifier(api);
});

class WelfareState {
  final double currentBalance;
  final double totalContributed;
  final double totalClaimed;
  final List<WelfareTransaction> transactions;
  final bool isLoading;

  const WelfareState({
    this.currentBalance = 3450.0,
    this.totalContributed = 4950.0,
    this.totalClaimed = 1500.0,
    this.transactions = const [],
    this.isLoading = false,
  });

  WelfareState copyWith({
    double? currentBalance,
    double? totalContributed,
    double? totalClaimed,
    List<WelfareTransaction>? transactions,
    bool? isLoading,
  }) {
    return WelfareState(
      currentBalance: currentBalance ?? this.currentBalance,
      totalContributed: totalContributed ?? this.totalContributed,
      totalClaimed: totalClaimed ?? this.totalClaimed,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WelfareNotifier extends StateNotifier<WelfareState> {
  final ApiClient _api;

  WelfareNotifier(this._api)
      : super(WelfareState(
          transactions: MockDataService.getMockWelfareTransactions(),
        )) {
    loadWelfare();
  }

  Future<void> loadWelfare() async {
    state = state.copyWith(isLoading: true);
    try {
      final txs = await _api.getWelfareTransactions();
      state = state.copyWith(transactions: txs, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> submitClaim({
    required String category,
    required double amount,
    required String description,
  }) async {
    final newClaim = WelfareTransaction(
      id: 'wt_${DateTime.now().millisecondsSinceEpoch}',
      workerId: 'w_demo_ramesh',
      type: WelfareTransactionType.claim,
      amount: amount,
      status: WelfareClaimStatus.pending,
      createdAt: DateTime.now(),
      description: description,
      claimCategory: category,
    );

    state = state.copyWith(
      transactions: [newClaim, ...state.transactions],
    );

    await _api.submitWelfareClaim(
      category: category,
      amount: amount,
      reason: description,
    );

    return true;
  }

  void recordContribution(double amount, String description) {
    final newTx = WelfareTransaction(
      id: 'wt_${DateTime.now().millisecondsSinceEpoch}',
      workerId: 'w_demo_ramesh',
      type: WelfareTransactionType.contribution,
      amount: amount,
      status: WelfareClaimStatus.approved,
      createdAt: DateTime.now(),
      description: description,
    );
    state = state.copyWith(
      currentBalance: state.currentBalance + amount,
      totalContributed: state.totalContributed + amount,
      transactions: [newTx, ...state.transactions],
    );
  }
}

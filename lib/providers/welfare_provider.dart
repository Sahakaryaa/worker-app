import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/welfare_transaction.dart';
import '../services/api_client.dart';

final welfareProvider =
    StateNotifierProvider<WelfareNotifier, WelfareState>((ref) {
  final api = ref.watch(apiClientProvider);
  return WelfareNotifier(api);
});

class WelfareState {
  final double currentBalance;
  final double totalContributed;
  final List<WelfareTransaction> transactions;
  final bool isLoading;
  final bool submittingClaim;
  final String? error;
  final int errorStamp;

  const WelfareState({
    this.currentBalance = 0,
    this.totalContributed = 0,
    this.transactions = const [],
    this.isLoading = true,
    this.submittingClaim = false,
    this.error,
    this.errorStamp = 0,
  });

  double get totalClaimedApproved => transactions
      .where((t) =>
          t.type == WelfareTransactionType.claim &&
          t.status != WelfareClaimStatus.pending)
      .fold(0.0, (s, t) => s + t.amount);

  WelfareState copyWith({
    double? currentBalance,
    double? totalContributed,
    List<WelfareTransaction>? transactions,
    bool? isLoading,
    bool? submittingClaim,
    String? error,
    int? errorStamp,
    bool clearError = false,
  }) {
    return WelfareState(
      currentBalance: currentBalance ?? this.currentBalance,
      totalContributed: totalContributed ?? this.totalContributed,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      submittingClaim: submittingClaim ?? this.submittingClaim,
      error: clearError ? null : (error ?? this.error),
      errorStamp: errorStamp ?? this.errorStamp,
    );
  }
}

class WelfareNotifier extends StateNotifier<WelfareState> {
  final ApiClient _api;

  WelfareNotifier(this._api) : super(const WelfareState()) {
    loadWelfare();
  }

  /// GET /welfare/me -> one object per contract. Offline demo fallback keeps
  /// the passbook presentable without a backend.
  Future<void> loadWelfare() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snap = await _api.fetchWelfare();
      state = WelfareState(
        currentBalance: snap.balance,
        totalContributed: snap.totalContributed,
        transactions: snap.transactions,
        isLoading: false,
      );
    } catch (_) {
      if (!await _api.hasToken) {
        final demo = _api.demoWelfareSnapshot();
        state = WelfareState(
          currentBalance: demo.balance,
          totalContributed: demo.totalContributed,
          transactions: demo.transactions,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load welfare ledger. Pull to retry.',
          errorStamp: DateTime.now().millisecondsSinceEpoch,
        );
      }
    }
  }

  /// POST /welfare/claims {amount > 0, reason min 3 chars}.
  /// Optimistic pending entry ONLY after a confirmed server acceptance.
  Future<bool> submitClaim({
    required double amount,
    required String reason,
  }) async {
    if (amount <= 0 || reason.trim().length < 3) {
      state = state.copyWith(
        error: 'Enter an amount greater than ₹0 and a reason (min 3 letters).',
        errorStamp: DateTime.now().millisecondsSinceEpoch,
      );
      return false;
    }
    if (amount > state.currentBalance) {
      state = state.copyWith(
        error:
            'Claim exceeds your available balance of ₹${state.currentBalance.toStringAsFixed(0)}.',
        errorStamp: DateTime.now().millisecondsSinceEpoch,
      );
      return false;
    }

    state = state.copyWith(submittingClaim: true, clearError: true);
    final ok = await _api.submitWelfareClaim(
      amount: amount,
      reason: reason.trim(),
    );

    if (!ok) {
      state = state.copyWith(
        submittingClaim: false,
        error: 'Claim submission failed. Please try again.',
        errorStamp: DateTime.now().millisecondsSinceEpoch,
      );
      return false;
    }

    // Confirmed — reflect locally and reload authoritative ledger.
    state = state.copyWith(submittingClaim: false);
    await loadWelfare();
    return true;
  }

  void recordContribution(double amount, String reason) {
    final newTx = WelfareTransaction(
      id: 'wt_${DateTime.now().millisecondsSinceEpoch}',
      type: WelfareTransactionType.contribution,
      amount: amount,
      status: WelfareClaimStatus.completed,
      createdAt: DateTime.now(),
      reason: reason,
    );
    state = state.copyWith(
      currentBalance: state.currentBalance + amount,
      totalContributed: state.totalContributed + amount,
      transactions: [newTx, ...state.transactions],
    );
  }

  void consumeError() {
    state = state.copyWith(clearError: true);
  }
}

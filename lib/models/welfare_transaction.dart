enum WelfareTransactionType { contribution, claim }

/// Contract statuses ONLY: pending | approved | completed (no disbursed).
enum WelfareClaimStatus { pending, approved, completed }

 WelfareClaimStatus _parseStatus(String? raw) => switch (raw) {
      'pending' => WelfareClaimStatus.pending,
      'approved' => WelfareClaimStatus.approved,
      'completed' => WelfareClaimStatus.completed,
      // Legacy/unknown values map to approved rather than crashing.
      _ => WelfareClaimStatus.approved,
    };

extension WelfareClaimStatusX on WelfareClaimStatus {
  String get label => switch (this) {
        WelfareClaimStatus.pending => 'Pending',
        WelfareClaimStatus.approved => 'Approved',
        WelfareClaimStatus.completed => 'Completed',
      };
}

/// Federation Welfare Fund transaction per API_CONTRACT.md.
/// Text key is `reason` (NOT description).
class WelfareTransaction {
  final String id;
  final String workerId;
  final WelfareTransactionType type;
  final double amount;
  final WelfareClaimStatus status;
  final DateTime createdAt;
  final String reason;

  const WelfareTransaction({
    required this.id,
    this.workerId = '',
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.reason = '',
  });

  bool get isContribution => type == WelfareTransactionType.contribution;

  factory WelfareTransaction.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? 'contribution';
    return WelfareTransaction(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          'wt_${DateTime.now().millisecondsSinceEpoch}',
      workerId: json['worker_id']?.toString() ?? '',
      type: typeStr == 'claim'
          ? WelfareTransactionType.claim
          : WelfareTransactionType.contribution,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(json['status']?.toString()),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reason: json['reason']?.toString() ?? 'Welfare contribution',
    );
  }
}

/// Snapshot of GET /welfare/me — ONE object:
/// {worker_id, balance, total_contributed, transactions:[...]}
class WelfareSnapshot {
  final String workerId;
  final double balance;
  final double totalContributed;
  final List<WelfareTransaction> transactions;

  const WelfareSnapshot({
    this.workerId = '',
    this.balance = 0,
    this.totalContributed = 0,
    this.transactions = const [],
  });

  double get totalClaimedApproved => transactions
      .where((t) =>
          t.type == WelfareTransactionType.claim &&
          t.status != WelfareClaimStatus.pending)
      .fold(0.0, (sum, t) => sum + t.amount);

  factory WelfareSnapshot.fromJson(Map<String, dynamic> json) {
    final txs = (json['transactions'] as List?)
            ?.map((e) =>
                WelfareTransaction.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <WelfareTransaction>[];
    return WelfareSnapshot(
      workerId: json['worker_id']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      // Backend returns total_contributions; older contract docs said total_contributed.
      totalContributed: (json['total_contributed'] as num?)?.toDouble() ??
          (json['total_contributions'] as num?)?.toDouble() ??
          0.0,
      transactions: txs,
    );
  }
}

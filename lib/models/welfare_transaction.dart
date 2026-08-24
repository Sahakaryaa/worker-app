enum WelfareTransactionType { contribution, claim }

enum WelfareClaimStatus { pending, approved, disbursed, rejected }

/// Federation Welfare Fund Transaction model.
class WelfareTransaction {
  final String id;
  final String workerId;
  final WelfareTransactionType type;
  final double amount;
  final WelfareClaimStatus status;
  final DateTime createdAt;
  final String description;
  final String? claimCategory; // "Medical", "Tool Grant", "Accident Relief", "Pension"

  const WelfareTransaction({
    required this.id,
    required this.workerId,
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.description,
    this.claimCategory,
  });

  bool get isContribution => type == WelfareTransactionType.contribution;

  factory WelfareTransaction.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'contribution';
    final statusStr = json['status'] as String? ?? 'approved';

    return WelfareTransaction(
      id: json['_id'] as String? ?? json['id'] as String? ?? 'wt_${DateTime.now().millisecondsSinceEpoch}',
      workerId: json['worker_id'] as String? ?? '',
      type: typeStr == 'claim'
          ? WelfareTransactionType.claim
          : WelfareTransactionType.contribution,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: switch (statusStr) {
        'pending' => WelfareClaimStatus.pending,
        'approved' => WelfareClaimStatus.approved,
        'disbursed' => WelfareClaimStatus.disbursed,
        'rejected' => WelfareClaimStatus.rejected,
        _ => WelfareClaimStatus.approved,
      },
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      description: json['description'] as String? ?? '1% Welfare Contribution from Job',
      claimCategory: json['claim_category'] as String?,
    );
  }
}

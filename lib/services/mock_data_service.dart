import '../models/worker_profile.dart';
import '../models/job.dart';
import '../models/welfare_transaction.dart';

/// Mock data provider for SahaKarya Partner (सहकार्य साथी).
/// # DEMO DATA — replace before production
class MockDataService {
  // Demo baseline coordinates (Connaught Place, Central Delhi)
  static const double baseLat = 28.6304;
  static const double baseLng = 77.2177;

  /// Demo verified worker profile (backend model default is OFFLINE).
  static const WorkerProfile demoWorkerProfile = WorkerProfile(
    id: 'w_demo_ramesh',
    name: 'Ramesh Kumar',
    phone: '9811100001',
    skills: ['electrician', 'plumber'],
    serviceType: 'electrician',
    rating: 4.85,
    totalJobs: 840,
    latitude: baseLat,
    longitude: baseLng,
    isOnline: false,
    certification: 'verified',
    todayEarnings: 1350,
  );

  /// Demo incoming job offer triggered by customer or demo CTA
  static Job getDemoIncomingJob({bool isEmergency = false}) {
    final price = isEmergency ? 550.0 : 450.0;
    return Job(
      id: 'job_incoming_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: 'b_${DateTime.now().millisecondsSinceEpoch}',
      serviceType: isEmergency ? 'electrician' : 'plumber',
      customerName: 'Ananya Sharma',
      customerPhone: '+91 98765 43210',
      customerAddress: 'Flat 402, Block C, Connaught Place, New Delhi',
      customerLatitude: baseLat + 0.0042,
      customerLongitude: baseLng + 0.0031,
      price: price,
      welfareContribution: price * 0.05,
      distanceMeters: 850.0,
      status: JobStatus.pending,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(seconds: 60)),
    );
  }

  /// Demo completed job history (5% welfare contribution per contract).
  static List<Job> getMockJobs() {
    final now = DateTime.now();
    return [
      _demoJob('job_1', 'b_101', 'electrician', 'Vikram Mehta', 450, 620,
          now.subtract(const Duration(hours: 2))),
      _demoJob('job_2', 'b_102', 'electrician', 'Pooja Iyer', 500, 1400,
          now.subtract(const Duration(hours: 5))),
      _demoJob('job_3', 'b_103', 'plumber', 'Rahul Verma', 400, 1900,
          now.subtract(const Duration(hours: 7))),
      _demoJob('job_4', 'b_104', 'carpenter', 'Sanjay Gupta', 650, 2100,
          now.subtract(const Duration(days: 1))),
    ];
  }

  static Job _demoJob(String id, String bookingId, String serviceType,
      String customerName, double price, double distanceMeters, DateTime at) {
    return Job(
      id: id,
      bookingId: bookingId,
      serviceType: serviceType,
      customerName: customerName,
      customerAddress: 'New Delhi',
      customerLatitude: baseLat + 0.002,
      customerLongitude: baseLng + 0.003,
      price: price,
      welfareContribution: price * 0.05,
      distanceMeters: distanceMeters,
      status: JobStatus.completed,
      createdAt: at,
    );
  }

  /// Demo welfare ledger — contract statuses only (pending|approved|completed),
  /// key `reason`, 5% contributions.
  static WelfareSnapshot getDemoWelfareSnapshot() {
    final now = DateTime.now();
    const contributed = 4950.0;
    final transactions = [
      WelfareTransaction(
        id: 'wt_1',
        workerId: 'w_demo_ramesh',
        type: WelfareTransactionType.contribution,
        amount: 22.5,
        status: WelfareClaimStatus.completed,
        createdAt: now.subtract(const Duration(hours: 2)),
        reason: '5% welfare contribution • Booking #b_101',
      ),
      WelfareTransaction(
        id: 'wt_2',
        workerId: 'w_demo_ramesh',
        type: WelfareTransactionType.contribution,
        amount: 25.0,
        status: WelfareClaimStatus.completed,
        createdAt: now.subtract(const Duration(hours: 5)),
        reason: '5% welfare contribution • Booking #b_102',
      ),
      WelfareTransaction(
        id: 'wt_3',
        workerId: 'w_demo_ramesh',
        type: WelfareTransactionType.claim,
        amount: 2500.0,
        status: WelfareClaimStatus.completed,
        createdAt: now.subtract(const Duration(days: 12)),
        reason: 'Annual electrician tool grant (insulated drill & tester kit)',
      ),
      WelfareTransaction(
        id: 'wt_4',
        workerId: 'w_demo_ramesh',
        type: WelfareTransactionType.contribution,
        amount: 20.0,
        status: WelfareClaimStatus.completed,
        createdAt: now.subtract(const Duration(hours: 7)),
        reason: '5% welfare contribution • Booking #b_103',
      ),
      WelfareTransaction(
        id: 'wt_5',
        workerId: 'w_demo_ramesh',
        type: WelfareTransactionType.claim,
        amount: 1500.0,
        status: WelfareClaimStatus.pending,
        createdAt: now.subtract(const Duration(days: 2)),
        reason: 'OPD eye checkup & protective goggles reimbursement',
      ),
    ];
    return WelfareSnapshot(
      workerId: 'w_demo_ramesh',
      balance: 3450.0,
      totalContributed: contributed,
      transactions: transactions,
    );
  }

  /// Weekly earnings bar data for fl_chart
  static const List<Map<String, dynamic>> demoWeeklyEarnings = [
    {'day': 'Mon', 'amount': 1250.0, 'jobs': 3},
    {'day': 'Tue', 'amount': 1600.0, 'jobs': 4},
    {'day': 'Wed', 'amount': 900.0, 'jobs': 2},
    {'day': 'Thu', 'amount': 2100.0, 'jobs': 5},
    {'day': 'Fri', 'amount': 1750.0, 'jobs': 4},
    {'day': 'Sat', 'amount': 2400.0, 'jobs': 6},
    {'day': 'Sun', 'amount': 1350.0, 'jobs': 3},
  ];

  static List<Map<String, dynamic>> getWeeklyEarnings() => demoWeeklyEarnings;
}

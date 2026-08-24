import '../models/worker_profile.dart';
import '../models/job.dart';
import '../models/welfare_transaction.dart';

/// Mock data provider for SahaKarya Partner (सहकार्य साथी).
/// # DEMO DATA — replace before production
class MockDataService {
  // Demo baseline coordinates (Connaught Place, Central Delhi)
  static const double baseLat = 28.6304;
  static const double baseLng = 77.2177;

  /// Default verified demo worker profile
  static const WorkerProfile demoWorkerProfile = WorkerProfile(
    id: 'w_demo_ramesh',
    userId: 'u_ramesh',
    name: 'Ramesh Kumar',
    phone: '+91 98111 00001',
    federationName: 'Delhi Central Labour Cooperative Federation',
    skills: ['electrician', 'plumber'],
    certificationStatus: 'verified',
    latitude: baseLat,
    longitude: baseLng,
    ratingAvg: 4.85,
    totalRatings: 142,
    welfareFundBalance: 3450.0,
    availability: 'online',
    todayEarnings: 1350.0,
    completedJobsCount: 3,
  );

  /// Demo incoming job offer triggered by customer or demo CTA
  static Job getDemoIncomingJob({bool isEmergency = false}) {
    return Job(
      id: 'job_incoming_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: 'b_${DateTime.now().millisecondsSinceEpoch}',
      serviceType: isEmergency ? 'electrician' : 'plumber',
      customerName: 'Ananya Sharma',
      customerPhone: '+91 98765 43210',
      customerAddress: 'Flat 402, Block C, Connaught Place, New Delhi',
      customerLatitude: baseLat + 0.0042,
      customerLongitude: baseLng + 0.0031,
      price: isEmergency ? 550.0 : 450.0,
      welfareContribution: isEmergency ? 5.5 : 4.5,
      distanceMeters: 850.0,
      isEmergency: isEmergency,
      status: JobStatus.matched,
      createdAt: DateTime.now(),
      serviceNotes: isEmergency
          ? 'Emergency: Circuit breaker short-circuit sparks detected in kitchen.'
          : 'Water pressure low in bathroom overhead tank connection.',
    );
  }

  /// Demo completed job history
  static List<Job> getMockJobs() {
    final now = DateTime.now();
    return [
      Job(
        id: 'job_1',
        bookingId: 'b_101',
        serviceType: 'electrician',
        customerName: 'Vikram Mehta',
        customerPhone: '+91 98123 45678',
        customerAddress: 'House 14, Barakhamba Road, New Delhi',
        customerLatitude: baseLat - 0.003,
        customerLongitude: baseLng + 0.002,
        price: 450.0,
        welfareContribution: 4.5,
        distanceMeters: 620.0,
        status: JobStatus.completed,
        createdAt: now.subtract(const Duration(hours: 2)),
        serviceNotes: 'Ceiling fan capacitor replacement and wiring test.',
      ),
      Job(
        id: 'job_2',
        bookingId: 'b_102',
        serviceType: 'electrician',
        customerName: 'Pooja Iyer',
        customerPhone: '+91 98234 56789',
        customerAddress: 'Flat 8B, Kasturba Gandhi Marg, New Delhi',
        customerLatitude: baseLat + 0.005,
        customerLongitude: baseLng - 0.004,
        price: 500.0,
        welfareContribution: 5.0,
        distanceMeters: 1400.0,
        status: JobStatus.completed,
        createdAt: now.subtract(const Duration(hours: 5)),
        serviceNotes: 'Main MCB switch upgrade to 32A.',
      ),
      Job(
        id: 'job_3',
        bookingId: 'b_103',
        serviceType: 'plumber',
        customerName: 'Rahul Verma',
        customerPhone: '+91 98345 67890',
        customerAddress: 'Plot 31, Janpath, New Delhi',
        customerLatitude: baseLat - 0.008,
        customerLongitude: baseLng - 0.001,
        price: 400.0,
        welfareContribution: 4.0,
        distanceMeters: 1900.0,
        status: JobStatus.completed,
        createdAt: now.subtract(const Duration(hours: 7)),
        serviceNotes: 'Sink drainage pipe leak seal.',
      ),
      Job(
        id: 'job_4',
        bookingId: 'b_104',
        serviceType: 'electrician',
        customerName: 'Sanjay Gupta',
        customerPhone: '+91 98456 78901',
        customerAddress: '22 Tolstoy Marg, New Delhi',
        customerLatitude: baseLat + 0.002,
        customerLongitude: baseLng + 0.008,
        price: 650.0,
        welfareContribution: 6.5,
        distanceMeters: 2100.0,
        status: JobStatus.completed,
        createdAt: now.subtract(const Duration(days: 1)),
        serviceNotes: 'Inverter battery setup and earthing test.',
      ),
    ];
  }

  /// Demo welfare transactions ledger
  static List<WelfareTransaction> getMockWelfareTransactions() {
    final now = DateTime.now();
    return [
      WelfareTransaction(
        id: 'wt_1',
        workerId: 'w_demo_ramesh',
        type: WelfareTransactionType.contribution,
        amount: 4.5,
        status: WelfareClaimStatus.approved,
        createdAt: now.subtract(const Duration(hours: 2)),
        description: '1% Welfare Contribution • Booking #b_101',
      ),
      WelfareTransaction(
        id: 'wt_2',
        workerId: 'w_demo_ramesh',
        type: WelfareTransactionType.contribution,
        amount: 5.0,
        status: WelfareClaimStatus.approved,
        createdAt: now.subtract(const Duration(hours: 5)),
        description: '1% Welfare Contribution • Booking #b_102',
      ),
      WelfareTransaction(
        id: 'wt_3',
        workerId: 'w_demo_ramesh',
        type: WelfareTransactionType.claim,
        amount: 2500.0,
        status: WelfareClaimStatus.disbursed,
        createdAt: now.subtract(const Duration(days: 12)),
        description: 'Annual Electrician Tool Grant (Insulated Drill & Tester Kit)',
        claimCategory: 'Tool Grant',
      ),
      WelfareTransaction(
        id: 'wt_4',
        workerId: 'w_demo_ramesh',
        type: WelfareTransactionType.contribution,
        amount: 4.0,
        status: WelfareClaimStatus.approved,
        createdAt: now.subtract(const Duration(hours: 7)),
        description: '1% Welfare Contribution • Booking #b_103',
      ),
      WelfareTransaction(
        id: 'wt_5',
        workerId: 'w_demo_ramesh',
        type: WelfareTransactionType.claim,
        amount: 1500.0,
        status: WelfareClaimStatus.pending,
        createdAt: now.subtract(const Duration(days: 2)),
        description: 'OPD Eye Checkup & Protective Goggles Reimbursement',
        claimCategory: 'Medical',
      ),
    ];
  }

  /// Weekly earnings bar data for fl_chart
  static List<Map<String, dynamic>> getWeeklyEarnings() {
    return [
      {'day': 'Mon', 'amount': 1250.0, 'jobs': 3},
      {'day': 'Tue', 'amount': 1600.0, 'jobs': 4},
      {'day': 'Wed', 'amount': 900.0, 'jobs': 2},
      {'day': 'Thu', 'amount': 2100.0, 'jobs': 5},
      {'day': 'Fri', 'amount': 1750.0, 'jobs': 4},
      {'day': 'Sat', 'amount': 2400.0, 'jobs': 6},
      {'day': 'Sun', 'amount': 1350.0, 'jobs': 3},
    ];
  }
}

import 'package:latlong2/latlong.dart';
import '../config/service_region.dart';

/// Booking status enum per API_CONTRACT.md (exact strings):
/// pending | accepted | declined | en_route | arrived | started | completed | cancelled
enum JobStatus {
  pending,
  accepted,
  declined,
  enRoute,
  arrived,
  started,
  completed,
  cancelled;

  static JobStatus fromApi(String? raw) => switch (raw) {
        'pending' => JobStatus.pending,
        'accepted' => JobStatus.accepted,
        'declined' => JobStatus.declined,
        'en_route' => JobStatus.enRoute,
        'arrived' => JobStatus.arrived,
        'started' => JobStatus.started,
        'completed' => JobStatus.completed,
        'cancelled' => JobStatus.cancelled,
        _ => JobStatus.pending,
      };

  String get apiValue => switch (this) {
        JobStatus.pending => 'pending',
        JobStatus.accepted => 'accepted',
        JobStatus.declined => 'declined',
        JobStatus.enRoute => 'en_route',
        JobStatus.arrived => 'arrived',
        JobStatus.started => 'started',
        JobStatus.completed => 'completed',
        JobStatus.cancelled => 'cancelled',
      };

  String get label => switch (this) {
        JobStatus.pending => 'Offer Pending',
        JobStatus.accepted => 'Accepted',
        JobStatus.declined => 'Declined',
        JobStatus.enRoute => 'En Route',
        JobStatus.arrived => 'Arrived',
        JobStatus.started => 'Work Started',
        JobStatus.completed => 'Completed',
        JobStatus.cancelled => 'Cancelled',
      };
}

/// Job offer + active booking model.
/// Parses BOTH the Socket.IO `job_offer` payload and `BookingResponse`.
class Job {
  final String id;
  final String bookingId;
  final String serviceType;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double customerLatitude;
  final double customerLongitude;
  final double price;

  /// Contract money rule: exactly ONE figure anywhere = the 5% welfare
  /// contribution deducted from worker payout at completion.
  final double welfareContribution;
  final double distanceMeters;
  final bool isEmergency;
  final JobStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;

  /// Server-enforced accept window for live offers (`timeout_seconds` in the
  /// job_offer payload). Null for non-offer contexts (history/demo).
  final int? timeoutSeconds;
  final String? serviceNotes;

  const Job({
    required this.id,
    required this.bookingId,
    required this.serviceType,
    this.customerName = '',
    this.customerPhone = '',
    this.customerAddress = '',
    required this.customerLatitude,
    required this.customerLongitude,
    required this.price,
    double? welfareContribution,
    this.distanceMeters = 0,
    this.isEmergency = false,
    this.status = JobStatus.pending,
    required this.createdAt,
    this.expiresAt,
    this.timeoutSeconds,
    this.serviceNotes,
  }) : welfareContribution = welfareContribution ?? price * 0.05;

  LatLng get customerLocation => LatLng(customerLatitude, customerLongitude);

  String get distanceFormatted {
    if (distanceMeters <= 0) return '—';
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  Job copyWith({
    String? id,
    String? bookingId,
    String? serviceType,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    double? customerLatitude,
    double? customerLongitude,
    double? price,
    double? welfareContribution,
    double? distanceMeters,
    bool? isEmergency,
    JobStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? timeoutSeconds,
    String? serviceNotes,
  }) {
    return Job(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      serviceType: serviceType ?? this.serviceType,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerLatitude: customerLatitude ?? this.customerLatitude,
      customerLongitude: customerLongitude ?? this.customerLongitude,
      price: price ?? this.price,
      welfareContribution: welfareContribution ?? this.welfareContribution,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      isEmergency: isEmergency ?? this.isEmergency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      serviceNotes: serviceNotes ?? this.serviceNotes,
    );
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    // Coordinates are ALWAYS flat lat / lng per contract; the service-region
    // centre is the last-resort fallback (Godavari belt, not a metro city).
    final lat = (json['lat'] as num?)?.toDouble() ??
        (json['latitude'] as num?)?.toDouble() ??
        ServiceRegion.defaultCenterLat;
    final lng = (json['lng'] as num?)?.toDouble() ??
        (json['longitude'] as num?)?.toDouble() ??
        ServiceRegion.defaultCenterLng;

    final id = json['_id']?.toString() ??
        json['id']?.toString() ??
        'job_${DateTime.now().millisecondsSinceEpoch}';
    final bookingId = json['booking_id']?.toString() ?? id;

    final distanceKm = (json['distance_km'] as num?)?.toDouble();
    final distanceM = (json['distance_m'] as num?)?.toDouble();

    final priceVal = (json['price'] as num?)?.toDouble() ?? 0.0;

    return Job(
      id: id,
      bookingId: bookingId,
      serviceType: json['service_type']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      customerAddress:
          json['address']?.toString() ?? json['customer_address']?.toString() ?? '',
      customerLatitude: lat,
      customerLongitude: lng,
      price: priceVal,
      welfareContribution: priceVal * 0.05,
      distanceMeters: distanceKm != null
          ? distanceKm * 1000
          : distanceM ?? 0.0,
      isEmergency: json['is_emergency'] as bool? ?? false,
      status: JobStatus.fromApi(json['status']?.toString()),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      timeoutSeconds: (json['timeout_seconds'] as num?)?.toInt(),
      serviceNotes: json['description']?.toString() ??
          json['service_notes']?.toString(),
    );
  }
}

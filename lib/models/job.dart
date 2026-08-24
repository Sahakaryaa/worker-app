import 'package:latlong2/latlong.dart';

enum JobStatus {
  requested,
  matched,
  arrived,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case JobStatus.requested:
        return 'Offer Pending';
      case JobStatus.matched:
        return 'Dispatched';
      case JobStatus.arrived:
        return 'Arrived at Location';
      case JobStatus.inProgress:
        return 'Work in Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Job offer and active booking model for SahaKarya Partner.
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
  final double welfareContribution; // 1%
  final double distanceMeters;
  final bool isEmergency;
  final JobStatus status;
  final DateTime createdAt;
  final String? serviceNotes;

  const Job({
    required this.id,
    required this.bookingId,
    required this.serviceType,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.price,
    this.welfareContribution = 4.5,
    required this.distanceMeters,
    this.isEmergency = false,
    this.status = JobStatus.matched,
    required this.createdAt,
    this.serviceNotes,
  });

  LatLng get customerLocation => LatLng(customerLatitude, customerLongitude);

  String get distanceFormatted {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km away';
    }
    return '${distanceMeters.round()} m away';
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
      serviceNotes: serviceNotes ?? this.serviceNotes,
    );
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    double lat = 28.6328;
    double lng = 77.2197;
    if (json['location'] != null && json['location']['coordinates'] != null) {
      final coords = json['location']['coordinates'] as List;
      lng = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    } else {
      lat = (json['latitude'] as num?)?.toDouble() ?? 28.6328;
      lng = (json['longitude'] as num?)?.toDouble() ?? 77.2197;
    }

    final statusStr = json['status'] as String? ?? 'matched';
    final parsedStatus = switch (statusStr) {
      'requested' => JobStatus.requested,
      'matched' => JobStatus.matched,
      'arrived' => JobStatus.arrived,
      'in_progress' => JobStatus.inProgress,
      'completed' => JobStatus.completed,
      'cancelled' => JobStatus.cancelled,
      _ => JobStatus.matched,
    };

    final priceVal = (json['price'] as num?)?.toDouble() ?? 450.0;

    return Job(
      id: json['_id'] as String? ?? json['id'] as String? ?? 'job_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: json['booking_id'] as String? ?? json['id'] as String? ?? 'b_${DateTime.now().millisecondsSinceEpoch}',
      serviceType: json['service_type'] as String? ?? 'electrician',
      customerName: json['customer_name'] as String? ?? 'Ananya Sharma',
      customerPhone: json['customer_phone'] as String? ?? '+91 98765 43210',
      customerAddress: json['customer_address'] as String? ?? 'Flat 402, Block C, Connaught Place, New Delhi',
      customerLatitude: lat,
      customerLongitude: lng,
      price: priceVal,
      welfareContribution: (priceVal * 0.01),
      distanceMeters: (json['distance_m'] as num?)?.toDouble() ?? 1200.0,
      isEmergency: json['is_emergency'] as bool? ?? false,
      status: parsedStatus,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      serviceNotes: json['service_notes'] as String? ?? 'Main switchboard tripping repeatedly when AC turns on.',
    );
  }
}

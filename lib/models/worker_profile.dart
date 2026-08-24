import 'package:latlong2/latlong.dart';

/// Worker profile model for the partner app.
class WorkerProfile {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? federationId;
  final String federationName;
  final List<String> skills;
  final String certificationStatus; // "pending" | "verified" | "rejected"
  final double latitude;
  final double longitude;
  final double ratingAvg;
  final int totalRatings;
  final double welfareFundBalance;
  final String availability; // "online" | "offline"
  final String? profilePhotoUrl;
  final double todayEarnings;
  final int completedJobsCount;

  const WorkerProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.federationId,
    this.federationName = 'Delhi Central Labour Cooperative Federation',
    required this.skills,
    this.certificationStatus = 'verified',
    required this.latitude,
    required this.longitude,
    this.ratingAvg = 4.8,
    this.totalRatings = 142,
    this.welfareFundBalance = 3450.0,
    this.availability = 'online',
    this.profilePhotoUrl,
    this.todayEarnings = 1350.0,
    this.completedJobsCount = 3,
  });

  bool get isVerified => certificationStatus == 'verified';
  bool get isOnline => availability == 'online';
  LatLng get coordinates => LatLng(latitude, longitude);

  WorkerProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? federationId,
    String? federationName,
    List<String>? skills,
    String? certificationStatus,
    double? latitude,
    double? longitude,
    double? ratingAvg,
    int? totalRatings,
    double? welfareFundBalance,
    String? availability,
    String? profilePhotoUrl,
    double? todayEarnings,
    int? completedJobsCount,
  }) {
    return WorkerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      federationId: federationId ?? this.federationId,
      federationName: federationName ?? this.federationName,
      skills: skills ?? this.skills,
      certificationStatus: certificationStatus ?? this.certificationStatus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      totalRatings: totalRatings ?? this.totalRatings,
      welfareFundBalance: welfareFundBalance ?? this.welfareFundBalance,
      availability: availability ?? this.availability,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      completedJobsCount: completedJobsCount ?? this.completedJobsCount,
    );
  }

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    double lat = 28.6304;
    double lng = 77.2177;
    if (json['location'] != null && json['location']['coordinates'] != null) {
      final coords = json['location']['coordinates'] as List;
      lng = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    } else {
      lat = (json['latitude'] as num?)?.toDouble() ?? 28.6304;
      lng = (json['longitude'] as num?)?.toDouble() ?? 77.2177;
    }

    return WorkerProfile(
      id: json['_id'] as String? ?? json['id'] as String? ?? 'w_demo',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Ramesh Kumar',
      phone: json['phone'] as String? ?? '+91 98111 00001',
      federationId: json['federation_id'] as String?,
      federationName: json['federation_name'] as String? ??
          'Delhi Central Labour Cooperative Federation',
      skills: List<String>.from(json['skills'] as List? ?? ['electrician', 'plumber']),
      certificationStatus: json['certification_status'] as String? ?? 'verified',
      latitude: lat,
      longitude: lng,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 4.8,
      totalRatings: json['total_ratings'] as int? ?? 142,
      welfareFundBalance: (json['welfare_fund_balance'] as num?)?.toDouble() ?? 3450.0,
      availability: json['availability'] as String? ?? 'online',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      todayEarnings: (json['today_earnings'] as num?)?.toDouble() ?? 1350.0,
      completedJobsCount: json['completed_jobs_count'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'federation_id': federationId,
      'federation_name': federationName,
      'skills': skills,
      'certification_status': certificationStatus,
      'latitude': latitude,
      'longitude': longitude,
      'rating_avg': ratingAvg,
      'total_ratings': totalRatings,
      'welfare_fund_balance': welfareFundBalance,
      'availability': availability,
      'profile_photo_url': profilePhotoUrl,
      'today_earnings': todayEarnings,
      'completed_jobs_count': completedJobsCount,
    };
  }
}

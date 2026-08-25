import 'package:latlong2/latlong.dart';

import '../config/service_region.dart';
import '../utils/formatting.dart';

/// Worker profile model mapped to `WorkerResponse` per API_CONTRACT.md:
/// {id, name, phone, skills:[string], service_type, rating: float,
///  total_jobs: int, lat: float, lng: float, is_online: bool,
///  certification: "pending"|"verified"|"rejected", federation_id}
class WorkerProfile {
  final String id;
  final String name;
  final String phone;
  final List<String> skills;
  final String serviceType;
  final double rating;
  final int totalJobs;
  final double latitude;
  final double longitude;
  final bool isOnline;
  final String certification; // pending | verified | rejected
  final String? federationId;

  // Client-side display extras (not part of WorkerResponse).
  final double todayEarnings;

  static const String defaultFederationName =
      ServiceRegion.federationName;

  const WorkerProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.skills = const [],
    this.serviceType = '',
    this.rating = 0,
    this.totalJobs = 0,
    required this.latitude,
    required this.longitude,
    this.isOnline = false,
    this.certification = 'pending',
    this.federationId,
    this.todayEarnings = 0,
  });

  bool get isVerified => certification == 'verified';
  LatLng get coordinates => LatLng(latitude, longitude);
  String get initials => initialsOf(name);
  String get federationName => defaultFederationName;

  WorkerProfile copyWith({
    String? id,
    String? name,
    String? phone,
    List<String>? skills,
    String? serviceType,
    double? rating,
    int? totalJobs,
    double? latitude,
    double? longitude,
    bool? isOnline,
    String? certification,
    String? federationId,
    double? todayEarnings,
  }) {
    return WorkerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      skills: skills ?? this.skills,
      serviceType: serviceType ?? this.serviceType,
      rating: rating ?? this.rating,
      totalJobs: totalJobs ?? this.totalJobs,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOnline: isOnline ?? this.isOnline,
      certification: certification ?? this.certification,
      federationId: federationId ?? this.federationId,
      todayEarnings: todayEarnings ?? this.todayEarnings,
    );
  }

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble() ??
        (json['latitude'] as num?)?.toDouble() ??
        ServiceRegion.defaultCenterLat;
    final lng = (json['lng'] as num?)?.toDouble() ??
        (json['longitude'] as num?)?.toDouble() ??
        ServiceRegion.defaultCenterLng;

    return WorkerProfile(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          'w_unknown',
      name: json['name']?.toString() ?? 'Partner',
      phone: json['phone']?.toString() ?? '',
      skills: (json['skills'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      serviceType: json['service_type']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalJobs: (json['total_jobs'] as num?)?.toInt() ?? 0,
      latitude: lat,
      longitude: lng,
      isOnline: json['is_online'] as bool? ?? false,
      certification: json['certification']?.toString() ?? 'pending',
      federationId: json['federation_id']?.toString(),
    );
  }
}

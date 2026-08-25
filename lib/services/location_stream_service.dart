import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../config/service_region.dart';
import 'api_client.dart';

final locationStreamServiceProvider = Provider<LocationStreamService>((ref) {
  final api = ref.watch(apiClientProvider);
  final service = LocationStreamService(api);
  ref.onDispose(() => service.stopStreaming());
  return service;
});

/// Streams worker GPS coordinates to the backend periodically while online.
/// Chain: live GPS -> last known -> service-region default (Anaparthi centre).
class LocationStreamService {
  final ApiClient _api;
  Timer? _locationTimer;

  /// Last-resort fallback — the Godavari service-region centre.
  static const LatLng fallbackLocation = ServiceRegion.defaultCenter;
  LatLng _currentLocation = fallbackLocation;

  LocationStreamService(this._api);

  LatLng get currentLocation => _currentLocation;

  void startStreaming() {
    _locationTimer?.cancel();
    _broadcastLocation();
    // Throttled broadcast (2s minimum per spec; we use a relaxed 12s cadence
    // for background dispatch updates).
    _locationTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _broadcastLocation();
    });
  }

  void stopStreaming() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _broadcastLocation() async {
    try {
      LatLng? pos;
      try {
        final live = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            timeLimit: Duration(seconds: 3),
          ),
        );
        pos = LatLng(live.latitude, live.longitude);
      } catch (_) {
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) pos = LatLng(last.latitude, last.longitude);
        } catch (_) {}
      }
      pos ??= _currentLocation == fallbackLocation ? null : _currentLocation;
      if (pos == null) return; // stay on cached default; no spam

      _currentLocation = pos;
      // PATCH /workers/location {lat, lng} — flat keys per contract.
      await _api.updateLocation(pos.latitude, pos.longitude);
    } catch (_) {
      // Non-fatal: dispatch keeps working with last known location.
    }
  }
}

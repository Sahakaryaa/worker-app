import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'api_client.dart';

final locationStreamServiceProvider = Provider<LocationStreamService>((ref) {
  final api = ref.watch(apiClientProvider);
  final service = LocationStreamService(api);
  ref.onDispose(() => service.stopStreaming());
  return service;
});

/// Streams worker GPS coordinates to the backend periodically when online.
class LocationStreamService {
  final ApiClient _api;
  Timer? _locationTimer;
  LatLng _currentLocation = const LatLng(28.6304, 77.2177);

  LocationStreamService(this._api);

  LatLng get currentLocation => _currentLocation;

  void startStreaming() {
    _locationTimer?.cancel();
    _broadcastLocation();
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
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 2),
        ),
      );
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      await _api.updateLocation(pos.latitude, pos.longitude);
    } catch (_) {
      // Keep baseline coordinates in demo
    }
  }
}

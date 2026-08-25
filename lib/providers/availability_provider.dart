import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/location_stream_service.dart';

final availabilityProvider =
    StateNotifierProvider<AvailabilityNotifier, bool>((ref) {
  final locStream = ref.watch(locationStreamServiceProvider);
  final api = ref.watch(apiClientProvider);
  ref.onDispose(() => locStream.stopStreaming());
  // Start OFFLINE to match the backend model default (availability=offline).
  return AvailabilityNotifier(locStream, api, initialOnline: false);
});

/// Availability switch. Toggles are pushed to the backend via
/// PATCH /workers/me/availability so dispatch ($geoNear with
/// availability=='online') can target this worker. Going online also starts
/// GPS location streaming (PATCH /workers/me/location).
class AvailabilityNotifier extends StateNotifier<bool> {
  final LocationStreamService _locStream;
  final ApiClient _api;

  AvailabilityNotifier(this._locStream, this._api, {required bool initialOnline})
      : super(initialOnline);

  Future<void> toggle() async {
    final next = !state;
    final previous = state;
    state = next;
    if (next) {
      _locStream.startStreaming();
    } else {
      _locStream.stopStreaming();
    }
    try {
      // Server is source of truth for dispatch; revert locally on failure.
      await _api.setAvailability(next);
    } catch (_) {
      state = previous;
    }
  }

  Future<void> setOnline(bool online) async {
    state = online;
    if (online) {
      _locStream.startStreaming();
    } else {
      _locStream.stopStreaming();
    }
    try {
      await _api.setAvailability(online);
    } catch (_) {/* best-effort for programmatic syncs */}
  }
}

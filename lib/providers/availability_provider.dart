import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/location_stream_service.dart';

final availabilityProvider =
    StateNotifierProvider<AvailabilityNotifier, bool>((ref) {
  final locStream = ref.watch(locationStreamServiceProvider);
  ref.onDispose(() => locStream.stopStreaming());
  // Start OFFLINE to match the backend model default (is_online=false).
  return AvailabilityNotifier(locStream, initialOnline: false);
});

/// Availability switch. The contract has no dedicated toggle endpoint, so the
/// online flag is local-only for now; going online starts GPS location
/// streaming (PATCH /workers/location) so dispatch can target this worker.
class AvailabilityNotifier extends StateNotifier<bool> {
  final LocationStreamService _locStream;

  AvailabilityNotifier(this._locStream, {required bool initialOnline})
      : super(initialOnline);

  Future<void> toggle() async {
    final next = !state;
    state = next;
    if (next) {
      _locStream.startStreaming();
      // Best-effort immediate position push; no availability endpoint in
      // the current contract, so nothing else is sent.
    } else {
      _locStream.stopStreaming();
    }
  }

  void setOnline(bool online) {
    state = online;
    if (online) {
      _locStream.startStreaming();
    } else {
      _locStream.stopStreaming();
    }
  }
}

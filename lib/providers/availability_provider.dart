import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/location_stream_service.dart';

final availabilityProvider =
    StateNotifierProvider<AvailabilityNotifier, bool>((ref) {
  final api = ref.watch(apiClientProvider);
  final locStream = ref.watch(locationStreamServiceProvider);
  ref.onDispose(() => locStream.stopStreaming());
  return AvailabilityNotifier(api, locStream);
});

/// Hero availability state notifier — switches online/offline status and controls location streaming.
class AvailabilityNotifier extends StateNotifier<bool> {
  final ApiClient _api;
  final LocationStreamService _locStream;

  AvailabilityNotifier(this._api, this._locStream) : super(true);

  Future<void> toggle() async {
    final next = !state;
    state = next;
    await _api.updateAvailability(next);
    if (next) {
      _locStream.startStreaming();
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

  @override
  void dispose() {
    _locStream.stopStreaming();
    super.dispose();
  }
}

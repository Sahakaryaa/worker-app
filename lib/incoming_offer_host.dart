import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/incoming_job_provider.dart';
import 'router.dart';
import 'screens/incoming_job/incoming_job_sheet.dart';

/// App-root wrapper: keeps the incoming-offer listener alive on EVERY tab.
/// Shows the offer sheet through the root navigator and fires haptics on
/// arrival. Auto-decline is handled solely by the provider countdown (zero).
class IncomingOfferHost extends ConsumerStatefulWidget {
  final Widget child;

  const IncomingOfferHost({super.key, required this.child});

  @override
  ConsumerState<IncomingOfferHost> createState() => _IncomingOfferHostState();
}

class _IncomingOfferHostState extends ConsumerState<IncomingOfferHost> {
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    // Catch offers that arrived before first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offer = ref.read(incomingJobProvider).currentOffer;
      if (offer != null && mounted) _presentSheet();
    });
  }

  void _presentSheet() {
    if (_sheetOpen || !mounted) return;
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;
    _sheetOpen = true;
    HapticFeedback.heavyImpact();
    IncomingJobSheet.show(navContext).whenComplete(() => _sheetOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<JobOfferState>(incomingJobProvider, (prev, next) {
      final had = prev?.currentOffer != null;
      final has = next.currentOffer != null;
      if (!had && has) {
        if (!_sheetOpen) _presentSheet();
      }
      if (next.lastError != null) {
        ref.read(incomingJobProvider.notifier).consumeError();
        final navContext = rootNavigatorKey.currentContext ?? context;
        final messenger = ScaffoldMessenger.maybeOf(navContext);
        if (messenger != null) {
          messenger.clearSnackBars();
          messenger.showSnackBar(SnackBar(
            content: Text(next.lastError!),
            backgroundColor: AppSnackTone.error.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ));
        }
      }
    });

    return widget.child;
  }
}

enum AppSnackTone { error, warning, success, info }

extension AppSnackToneX on AppSnackTone {
  Color get color => switch (this) {
        AppSnackTone.error => const Color(0xFFEF4444),
        AppSnackTone.warning => const Color(0xFFF59E0B),
        AppSnackTone.success => const Color(0xFF16A34A),
        AppSnackTone.info => const Color(0xFF5B5FE9),
      };
}

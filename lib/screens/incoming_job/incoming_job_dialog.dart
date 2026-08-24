import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/incoming_job_provider.dart';
import '../../widgets/job_offer_card.dart';

/// Modal dialog presenting an incoming job offer with 30s countdown.
class IncomingJobDialog extends ConsumerWidget {
  const IncomingJobDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const IncomingJobDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerState = ref.watch(incomingJobProvider);
    final job = offerState.currentOffer;

    if (job == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: JobOfferCard(
        job: job,
        secondsRemaining: offerState.secondsRemaining,
        onAccept: () async {
          await ref.read(incomingJobProvider.notifier).acceptCurrentOffer();
          if (context.mounted) {
            Navigator.of(context).pop();
            context.push('/active-job');
          }
        },
        onDecline: () async {
          await ref.read(incomingJobProvider.notifier).declineCurrentOffer();
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }
}

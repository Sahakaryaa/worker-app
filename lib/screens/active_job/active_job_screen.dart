import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../models/job.dart';
import '../../providers/active_job_provider.dart';
import '../../config/service_region.dart';
import '../../services/location_stream_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatting.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/empty_state.dart';
import 'worker_chat_screen.dart';
import '../../widgets/map_widgets.dart';

/// Active job execution screen — dark embedded map, animated status timeline
/// (accepted→en_route→arrived→started→completed) and stage-appropriate CTA.
class ActiveJobScreen extends ConsumerStatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final CameraFlyer _flyer;
  // Initial position: service-region centre until the live location service
  // provides the worker's real coordinates (never a hardcoded metro city).
  LatLng _workerPos = ServiceRegion.defaultCenter;
  bool _followingRoute = false;

  @override
  void initState() {
    super.initState();
    _flyer = CameraFlyer(_mapController, this);
  }

  @override
  void dispose() {
    _flyer.dispose();
    super.dispose();
  }

  void _fitCamera(Job job, {bool force = false}) {
    if (!_followingRoute || force) {
      // Prefer the live/cached position from the location service.
      final loc = ref.read(locationStreamServiceProvider).currentLocation;
      setState(() => _workerPos = loc);
      _flyer.fitCoordinates([_workerPos, job.customerLocation]);
      setState(() => _followingRoute = true);
    }
  }

  Future<void> _onStageAction(Job job) async {
    final notifier = ref.read(activeJobProvider.notifier);
    bool ok;
    switch (job.status) {
      case JobStatus.accepted:
        ok = await notifier.startEnRoute();
        break;
      case JobStatus.enRoute:
        ok = await notifier.markArrived();
        break;
      case JobStatus.arrived:
        ok = await notifier.startWork();
        break;
      case JobStatus.started:
        ok = await notifier.completeJob();
        break;
      default:
        return;
    }
    if (!mounted) return;
    if (!ok) {
      AppSnackBar.show(context,
          ref.read(activeJobProvider).error ?? 'Action failed.',
          type: SnackType.error);
    } else if (job.status == JobStatus.started) {
      _showCompletionCelebration(job);
    }
  }

  ({String label, IconData icon}) _ctaFor(JobStatus status) => switch (status) {
        JobStatus.accepted => (label: 'Start En Route', icon: Icons.directions_rounded),
        JobStatus.enRoute => (label: "I've Arrived", icon: Icons.location_on_rounded),
        JobStatus.arrived => (label: 'Start Job', icon: Icons.play_arrow_rounded),
        JobStatus.started => (label: 'Complete Job', icon: Icons.check_circle_rounded),
        _ => (label: 'Update', icon: Icons.update_rounded),
      };

  void _showCompletionCelebration(Job job) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration:
                      const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                ).animate().scale(
                      begin: const Offset(0.3, 0.3),
                      curve: Curves.elasticOut,
                      duration: 700.ms,
                    ),
                const SizedBox(height: 16),
                Text(
                  'Job Completed!',
                  style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${(job.price - job.welfareContribution).toStringAsFixed(0)} credited to your payout.\n₹${job.welfareContribution.toStringAsFixed(1)} (5%) added to your welfare fund.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 13, height: 1.5, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: 'View Earnings',
                  icon: Icons.account_balance_wallet_rounded,
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.go('/earnings');
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.go('/home');
                  },
                  child: Text('Back to Dashboard',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeJobProvider);
    final job = state.job;

    // Surface provider errors once.
    if (state.error != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeJobProvider.notifier).consumeError();
      });
    }

    if (job == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text('Active Job',
              style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.ink,
          elevation: 0,
        ),
        body: EmptyState(
          icon: Icons.assignment_turned_in_outlined,
          title: 'No active job',
          subtitle:
              'You have no job in progress right now. Go online on the dashboard to receive dispatch offers in real time.',
          ctaLabel: 'Go to Dashboard',
          onCta: () => context.go('/home'),
        ),
      );
    }

    final custPos = job.customerLocation;
    final routePoints = [
      _workerPos,
      LatLng((_workerPos.latitude + custPos.latitude) / 2 + 0.0012,
          (_workerPos.longitude + custPos.longitude) / 2 - 0.0009),
      custPos,
    ];

    return Scaffold(
      backgroundColor: AppColors.night1,
      body: Column(
        children: [
          // ---------------- Dark map hero ----------------
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _workerPos,
                      initialZoom: 14.5,
                      onMapEvent: (event) {
                        // Ignore map events caused by our own programmatic
                        // camera flights, otherwise follow-mode disables
                        // itself the instant it enables.
                        if (_flyer.isAnimating) return;
                        if (_followingRoute) {
                          setState(() => _followingRoute = false);
                        }
                      },
                    ),
                    children: [
                      const CartoTiles(dark: true), // dark_all allowed in dark heroes
                      AnimatedDashPolyline(points: routePoints),
                      MarkerLayer(markers: [
                        Marker(
                          point: _workerPos,
                          width: 84,
                          height: 84,
                          child: const HaloPulseMarkerChild(),
                        ),
                        Marker(
                          point: custPos,
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          child: DestinationMarkerChild(
                            icon: Icons.home_rounded,
                            color: AppColors.indigo,
                          ).animate().scale(
                                begin: const Offset(0.2, 0.2),
                                curve: Curves.elasticOut,
                                duration: 650.ms,
                              ),
                        ),
                      ]),
                      const CartoAttribution(),
                    ],
                  ),
                ),

                // Top telemetry bar
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.pin_drop_rounded,
                                  color: AppColors.goldDark, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  job.customerAddress.isEmpty
                                      ? 'Customer location'
                                      : job.customerAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(job.distanceFormatted,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.goldDark)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Recenter FAB (crosshair) with follow indicator
                Positioned(
                  right: 16,
                  bottom: 18,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_fab',
                    backgroundColor: AppColors.surface,
                    foregroundColor:
                        _followingRoute ? AppColors.goldDark : AppColors.inkSoft,
                    elevation: 4,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _fitCamera(job, force: true);
                    },
                    child: AnimatedRotation(
                      turns: _followingRoute ? 0 : 0.125,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.gps_fixed_rounded, size: 20),
                    ),
                  ),
                ),

                // Status pill over map
                Positioned(
                  left: 16,
                  bottom: 18,
                  child: StatusPillForMap(status: job.status),
                ),
              ],
            ),
          ),

          // ---------------- Bottom control sheet ----------------
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.52,
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Customer contact row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 23,
                          backgroundColor:
                              AppColors.indigo.withValues(alpha: 0.1),
                          child: Text(
                            initialsOf(job.customerName),
                            style: GoogleFonts.sora(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.indigo),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.customerName.isEmpty
                                    ? 'Customer'
                                    : job.customerName,
                                style: GoogleFonts.sora(
                                    fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${titleCase(job.serviceType.isEmpty ? 'service' : job.serviceType)} • ₹${job.price.toStringAsFixed(0)} payout',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppColors.inkSoft),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.indigo.withValues(alpha: 0.1),
                            foregroundColor: AppColors.indigo,
                          ),
                          icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            AppSnackBar.show(context,
                                'Calling ${job.customerPhone.isEmpty ? "customer" : job.customerPhone}…',
                                type: SnackType.info);
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.indigo.withValues(alpha: 0.1),
                            foregroundColor: AppColors.indigo,
                          ),
                          icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => WorkerChatScreen(
                                bookingId: job.bookingId,
                                customerName: job.customerName.isEmpty
                                    ? 'Customer'
                                    : job.customerName,
                                serviceType: job.serviceType,
                              ),
                            ));
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Vertical animated timeline
                    StatusTimeline(current: job.status),

                    const SizedBox(height: 16),

                    // Stage CTA
                    AppButton(
                      key: ValueKey(job.status.apiValue),
                      label: _ctaFor(job.status).label,
                      icon: _ctaFor(job.status).icon,
                      isLoading: state.busy,
                      onPressed: state.busy ? null : () => _onStageAction(job),
                    ),
                    const SizedBox(height: 6),

                    // SOS row
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        AppSnackBar.show(context,
                            'SOS alert sent to the federation safety desk.',
                            type: SnackType.error);
                      },
                      icon: const Icon(Icons.shield_rounded,
                          color: AppColors.danger, size: 17),
                      label: Text('Federation Safety SOS',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.danger)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- widgets

class StatusPillForMap extends StatelessWidget {
  final JobStatus status;
  const StatusPillForMap({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      JobStatus.accepted => AppColors.indigo,
      JobStatus.enRoute => AppColors.info,
      JobStatus.arrived => AppColors.indigoDeep,
      JobStatus.started => AppColors.goldDark,
      _ => AppColors.success,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: .85)]),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route_rounded, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(status.label.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

/// Vertical animated status timeline w/ current-stage glow.
class StatusTimeline extends StatelessWidget {
  final JobStatus current;

  static const List<JobStatus> stages = [
    JobStatus.accepted,
    JobStatus.enRoute,
    JobStatus.arrived,
    JobStatus.started,
    JobStatus.completed,
  ];

  const StatusTimeline({super.key, required this.current});

  int get _currentIdx =>
      stages.contains(current) ? stages.indexOf(current) : 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          _StageRow(
            status: stages[i],
            isCurrent: i == _currentIdx,
            isDone: i < _currentIdx,
            isFirst: i == 0,
            isLast: i == stages.length - 1,
          ),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  final JobStatus status;
  final bool isCurrent;
  final bool isDone;
  final bool isFirst;
  final bool isLast;

  const _StageRow({
    required this.status,
    required this.isCurrent,
    required this.isDone,
    required this.isFirst,
    required this.isLast,
  });

  Color get _color => isCurrent
      ? AppColors.gold
      : isDone
          ? AppColors.success
          : AppColors.border;

  IconData get _icon {
    if (isDone) return Icons.check_rounded;
    return switch (status) {
      JobStatus.accepted => Icons.assignment_turned_in_rounded,
      JobStatus.enRoute => Icons.directions_rounded,
      JobStatus.arrived => Icons.location_on_rounded,
      JobStatus.started => Icons.construction_rounded,
      JobStatus.completed => Icons.flag_rounded,
      _ => Icons.circle_outlined,
    };
  }

  String get _label => switch (status) {
        JobStatus.accepted => 'Job accepted',
        JobStatus.enRoute => 'En route to customer',
        JobStatus.arrived => 'Arrived at location',
        JobStatus.started => 'Work started',
        JobStatus.completed => 'Job completed',
        _ => status.label,
      };

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 3, height: 10, color: _color.withValues(alpha: 0.5)),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.gold : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: _color, width: 2),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.55),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(_icon, size: 14,
                      color: isDone ? AppColors.success : (isCurrent ? Colors.white : AppColors.inkFaint)),
                ).animate(target: isCurrent ? 1 : 0, autoPlay: false)
                    .shimmer(duration: 1400.ms, color: Colors.white38),
                if (!isLast)
                  Container(width: 3, height: 10, color: _color.withValues(alpha: 0.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                    color: isCurrent
                        ? AppColors.ink
                        : isDone
                            ? AppColors.success
                            : AppColors.inkFaint,
                  ),
                  child: Text(_label),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

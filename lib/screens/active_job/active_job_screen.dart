import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_colors.dart';
import '../../providers/active_job_provider.dart';
import '../../models/job.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/cooperative_badge.dart';

/// Active Job Execution & Navigation Screen per 03-worker-app-flutter.md §5.
class ActiveJobScreen extends ConsumerStatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  final LatLng _workerPos = const LatLng(28.6304, 77.2177);

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _radarAnimation = CurvedAnimation(
      parent: _radarController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeJob = ref.watch(activeJobProvider);

    if (activeJob == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Active Job'),
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 64, color: AppColors.teal),
              const SizedBox(height: 16),
              Text(
                'No Active Job in Progress',
                style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Go online on Home Dashboard to receive nearby job offers.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkLight),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final custPos = activeJob.customerLocation;
    final routePoints = [
      _workerPos,
      LatLng((_workerPos.latitude + custPos.latitude) / 2 + 0.001,
          (_workerPos.longitude + custPos.longitude) / 2 - 0.001),
      custPos,
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Job: ${activeJob.customerName}',
              style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            Text(
              'Booking #${activeJob.bookingId}',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () => _mapController.move(_workerPos, 15.0),
          ),
        ],
      ),
      body: Column(
        children: [
          // Job Status Stepper Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Row(
              children: [
                _buildStepPill('1. Dispatched', activeJob.status.index >= 1, activeJob.status == JobStatus.matched),
                const SizedBox(width: 6),
                _buildStepPill('2. Arrived', activeJob.status.index >= 2, activeJob.status == JobStatus.arrived),
                const SizedBox(width: 6),
                _buildStepPill('3. Working', activeJob.status.index >= 3, activeJob.status == JobStatus.inProgress),
              ],
            ),
          ),

          // Live Route Map Viewport
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _workerPos,
                    initialZoom: 15.0,
                  ),
                  children: [
                    // Real Google Maps Roadmap Tile Layer
                    TileLayer(
                      urlTemplate:
                          'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                      subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                      userAgentPackageName: 'com.sahakarya.worker_app',
                      maxZoom: 20,
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          color: const Color(0xFF9A3412),
                          strokeWidth: 6.0,
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                        Polyline(
                          points: routePoints,
                          color: AppColors.orange,
                          strokeWidth: 4.0,
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        // Worker Location Marker
                        Marker(
                          point: _workerPos,
                          width: 50,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.orangeGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.orange.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
                          ),
                        ),

                        // Customer Destination Marker with Radar Pulse
                        Marker(
                          point: custPos,
                          width: 70,
                          height: 70,
                          child: AnimatedBuilder(
                            animation: _radarAnimation,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 30 + (34 * _radarAnimation.value),
                                    height: 30 + (34 * _radarAnimation.value),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.teal.withValues(
                                        alpha: (1.0 - _radarAnimation.value) * 0.35,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: AppColors.teal,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Floating Telemetry Card
                Positioned(
                  top: 12,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pin_drop_rounded, color: AppColors.orange, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            activeJob.customerAddress,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          activeJob.distanceFormatted,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Controller Sheet
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Customer Profile & Payout Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                      child: Text(
                        activeJob.customerName.split(' ').map((e) => e[0]).take(2).join(),
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                activeJob.customerName,
                                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 6),
                              const CooperativeBadge(isCompact: true),
                            ],
                          ),
                          Text(
                            '${activeJob.serviceType.toUpperCase()} • Payout: ₹${activeJob.price.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkLight, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    // Call customer action
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                        foregroundColor: AppColors.teal,
                      ),
                      icon: const Icon(Icons.phone_in_talk_rounded),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Calling ${activeJob.customerName} (${activeJob.customerPhone})...'),
                            backgroundColor: AppColors.teal,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Lifecycle Stepper Actions
                if (activeJob.status == JobStatus.matched)
                  PrimaryButton(
                    label: 'I Have Arrived at Location',
                    icon: Icons.location_on_rounded,
                    backgroundColor: AppColors.teal,
                    onPressed: () async {
                      await ref.read(activeJobProvider.notifier).markArrived();
                    },
                  )
                else if (activeJob.status == JobStatus.arrived)
                  PrimaryButton(
                    label: 'Start Work (Inspect & Repair)',
                    icon: Icons.play_arrow_rounded,
                    backgroundColor: AppColors.orange,
                    onPressed: () async {
                      await ref.read(activeJobProvider.notifier).startWork();
                    },
                  )
                else if (activeJob.status == JobStatus.inProgress)
                  PrimaryButton(
                    label: 'Complete Job & Collect ₹${activeJob.price.toStringAsFixed(0)}',
                    icon: Icons.check_circle_rounded,
                    backgroundColor: AppColors.success,
                    onPressed: () async {
                      await ref.read(activeJobProvider.notifier).completeJob();
                      if (context.mounted) {
                        _showCompletionCelebration(context, activeJob);
                      }
                    },
                  ),

                const SizedBox(height: 10),

                // Secondary Actions: SOS Alert
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.shield_rounded, color: AppColors.error, size: 18),
                        label: Text(
                          '24/7 Federation Safety SOS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('SOS Alert dispatched to SahaKarya Safety Desk & Emergency Services!'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPill(String title, bool isCompleted, bool isCurrent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.orange.withValues(alpha: 0.15)
              : isCompleted
                  ? AppColors.teal.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent
                ? AppColors.orange
                : isCompleted
                    ? AppColors.teal
                    : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isCurrent
                  ? AppColors.orange
                  : isCompleted
                      ? AppColors.teal
                      : AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }

  void _showCompletionCelebration(BuildContext context, Job job) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Job Successfully Completed!',
                style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '₹${job.price.toStringAsFixed(0)} has been credited to your account.\n+₹${job.welfareContribution.toStringAsFixed(1)} added to your Federation Welfare Fund.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkLight),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'View Earnings Breakdown',
                icon: Icons.account_balance_wallet_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/earnings');
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/home');
                },
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        );
      },
    );
  }
}

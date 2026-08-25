import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

/// CARTO basemaps per DESIGN_SPEC — NO Google API key anywhere.
/// Voyager for general use; dark_all allowed inside dark heroes.
class CartoTiles extends StatelessWidget {
  final bool dark;

  const CartoTiles({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: dark
          ? 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png'
          : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'app.sahakarya.worker',
      maxZoom: 19,
    );
  }
}

/// Required attribution overlay for CARTO/OSM tiles.
class CartoAttribution extends StatelessWidget {
  const CartoAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleAttributionWidget(
      backgroundColor: Colors.white.withValues(alpha: 0.85),
      source: Text(
        '© OpenStreetMap contributors © CARTO',
        style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700),
      ),
    );
  }
}

/// Self marker — circular white-bordered pin with pulsing gold halo ring.
class HaloPulseMarkerChild extends StatefulWidget {
  final IconData icon;
  final Color ringColor;
  final double size;

  const HaloPulseMarkerChild({
    super.key,
    this.icon = Icons.navigation_rounded,
    this.ringColor = AppColors.gold,
    this.size = 44,
  });

  @override
  State<HaloPulseMarkerChild> createState() => _HaloPulseMarkerChildState();
}

class _HaloPulseMarkerChildState extends State<HaloPulseMarkerChild>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return _core(0);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => _core(_c.value),
    );
  }

  Widget _core(double t) {
    final haloSize = widget.size * (1.0 + t * 0.9);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: haloSize,
          height: haloSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.ringColor.withValues(alpha: (1 - t) * 0.35),
          ),
        ),
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: widget.ringColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(widget.icon, color: widget.ringColor, size: widget.size * 0.5),
        ),
      ],
    );
  }
}

/// Destination marker — colored circular pin with service icon.
class DestinationMarkerChild extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const DestinationMarkerChild({
    super.key,
    required this.icon,
    this.color = AppColors.indigo,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.85)],
        ),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.52),
    );
  }
}

/// Route polyline with animated dash offset ("marching ants").
/// flutter_map has no dash-offset parameter, so we densify the path and
/// rebuild the visible dash segments each tick with a shifting phase.
class AnimatedDashPolyline extends StatefulWidget {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;
  final Duration period;

  const AnimatedDashPolyline({
    super.key,
    required this.points,
    this.color = AppColors.gold,
    this.strokeWidth = 4,
    this.period = const Duration(milliseconds: 1100),
  });

  @override
  State<AnimatedDashPolyline> createState() => _AnimatedDashPolylineState();
}

class _AnimatedDashPolylineState extends State<AnimatedDashPolyline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const int _samples = 160;
  static const int _dashOn = 7; // samples per dash
  static const int _gap = 6; // samples per gap

  late List<LatLng> _densified;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.period)..repeat();
    _densify();
  }

  @override
  void didUpdateWidget(covariant AnimatedDashPolyline old) {
    super.didUpdateWidget(old);
    if (old.points != widget.points) _densify();
  }

  void _densify() {
    final src = widget.points;
    if (src.length < 2) {
      _densified = src;
      return;
    }
    final dist = const Distance();
    double total = 0;
    for (var i = 0; i < src.length - 1; i++) {
      total += dist(src[i], src[i + 1]);
    }
    // Sample uniformly along cumulative distance.
    final out = <LatLng>[];
    var remainingStep = total / _samples;
    var acc = 0.0;
    out.add(src.first);
    for (var i = 0; i < src.length - 1; i++) {
      final segLen = dist(src[i], src[i + 1]);
      var walked = 0.0;
      while (segLen - walked >= remainingStep && segLen > 0) {
        walked += remainingStep;
        acc += remainingStep;
        final f = walked / segLen;
        out.add(LatLng(
          src[i].latitude +
              (src[i + 1].latitude - src[i].latitude) * f,
          src[i].longitude +
              (src[i + 1].longitude - src[i].longitude) * f,
        ));
      }
      remainingStep -= (segLen - walked);
      if (remainingStep <= 0) remainingStep = total / _samples;
    }
    while (acc < total && out.length < _samples + 2) {
      // pad to full sample count by interpolation between last two points
      out.add(out.last);
      break;
    }
    out.add(src.last);
    _densified = out;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_densified.length < 2) return const SizedBox.shrink();

    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return PolylineLayer(polylines: [
        Polyline(
          points: _densified,
          strokeWidth: widget.strokeWidth,
          color: widget.color.withValues(alpha: 0.8),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      ]);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          PolylineLayer(polylines: [_buildDashes(_controller.value)]),
    );
  }

  Polyline _buildDashes(double phase) {
    final cycle = _dashOn + _gap;
    final offset = ((phase % 1) * cycle).floor();
    final pts = <LatLng>[];
    var run = <LatLng>[];

    void flush() {
      if (run.length > 1) pts.addAll([...run]);
      run.clear();
    }

    for (var i = offset; i < _densified.length + cycle; i++) {
      final idx = i % cycle;
      final inDash = idx < _dashOn;
      if (i < _densified.length) {
        if (inDash) {
          run.add(_densified[i]);
        } else {
          flush();
        }
      } else {
        flush();
      }
    }
    flush();

    return Polyline(
      points: pts,
      strokeWidth: widget.strokeWidth,
      color: widget.color,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
  }
}

/// Eased camera mover — drives MapController.move() from an AnimationController
/// with easeOutCubic (spec: camera moves eased via AnimationController).
class CameraFlyer {
  final MapController mapController;
  final TickerProvider vsync;
  AnimationController? _ctrl;
  LatLng? _fromCenter;
  double? _fromZoom;
  LatLng? _toCenter;
  double? _toZoom;

  CameraFlyer(this.mapController, this.vsync);

  /// True while a programmatic camera animation is in flight — lets screens
  /// distinguish our own mapController.move() events from genuine user pans.
  bool get isAnimating => _ctrl != null && _ctrl!.isAnimating;

  void moveTo(LatLng target, {double? zoom, Duration duration = const Duration(milliseconds: 650)}) {
    _start(target, zoom, duration);
  }

  void fitCoordinates(List<LatLng> coords,
      {Duration duration = const Duration(milliseconds: 700)}) {
    if (coords.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(coords);
    final center =
        LatLng((bounds.south + bounds.north) / 2, (bounds.west + bounds.east) / 2);
    final zoom = _zoomForBounds(bounds);
    _start(center, zoom, duration);
  }

  double _zoomForBounds(LatLngBounds b) {
    final worldSpan = 360.0;
    // latlong2 LatLngBounds stores raw doubles: north/south/east/west.
    final latSpan = (b.north - b.south).abs().clamp(0.0001, worldSpan);
    final lngSpan = (b.east - b.west).abs().clamp(0.0001, worldSpan);
    final zoomLat = math.log(worldSpan / latSpan) / math.ln2;
    final zoomLng = math.log(worldSpan / lngSpan) / math.ln2;
    // Rough viewport correction then clamp to street level range.
    final z = math.min(zoomLat, zoomLng) - 0.6;
    return z.clamp(12.5, 16.5);
  }

  void _start(LatLng target, double? zoom, Duration duration) {
    _ctrl?.dispose();
    _ctrl = AnimationController(vsync: vsync, duration: duration);
    _fromCenter = _toCenter ?? target;
    _fromZoom = _toZoom ?? zoom ?? 14;
    _toCenter = target;
    _toZoom = zoom ?? _fromZoom!;

    final curved =
        CurvedAnimation(parent: _ctrl!, curve: Curves.easeOutCubic);
    void tick() {
      final c = LatLng(
        lerpDouble(_fromCenter!.latitude, _toCenter!.latitude, curved.value)!,
        lerpDouble(_fromCenter!.longitude, _toCenter!.longitude, curved.value)!,
      );
      final z = lerpDouble(_fromZoom!, _toZoom!, curved.value)!;
      try {
        mapController.move(c, z);
      } catch (_) {}
    }

    _ctrl!
      ..addListener(tick)
      ..forward().whenComplete(() => _ctrl?.removeListener(tick));
  }

  void dispose() {
    _ctrl?.dispose();
  }
}

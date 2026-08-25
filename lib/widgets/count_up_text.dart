import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Animated number count-up for money / ratings (Sora w800, tight spacing).
class CountUpText extends StatefulWidget {
  final double value;
  final String prefix;
  final int decimals;
  final TextStyle? style;
  final Duration duration;

  const CountUpText({
    super.key,
    required this.value,
    this.prefix = '₹',
    this.decimals = 0,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> {
  double _from = 0;

  @override
  void didUpdateWidget(covariant CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _from = oldWidget.value;
    }
  }

  String _format(double v) {
    final f = NumberFormat.decimalPattern('en_IN');
    if (widget.decimals > 0) {
      f.minimumFractionDigits = widget.decimals;
      f.maximumFractionDigits = widget.decimals;
    }
    return '${widget.prefix}${f.format(v)}';
  }

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context)
        .style
        .merge(widget.style ?? _defaultStyle(context));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _from, end: widget.value),
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        _format(v),
        style: effective,
      ),
    );
  }

  TextStyle _defaultStyle(BuildContext context) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: Theme.of(context).colorScheme.primary,
      );
}

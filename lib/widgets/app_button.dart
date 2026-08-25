import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Luxe primary button — gradient fill, loading spinner state,
/// press scale-to-0.97 with haptic feedback (DESIGN_SPEC.md).
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary; // outlined / tonal variant
  final Color? background;
  final Color? foreground;
  final IconData? icon;
  final double height;
  final double? width;
  final bool haptic;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.background,
    this.foreground,
    this.icon,
    this.height = 52,
    this.width,
    this.haptic = true,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final bg = widget.isSecondary ? Colors.transparent : (widget.background ?? AppColors.gold);
    final fg = widget.foreground ?? (widget.background == null ? Colors.white : AppColors.ink);
    final gradient = widget.background == null && !widget.isSecondary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: widget.width ?? double.infinity,
          height: widget.height,
          child: ElevatedButton(
            onPressed: enabled
                ? () {
                    if (widget.haptic) HapticFeedback.lightImpact();
                    widget.onPressed!();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              elevation: 0,
              backgroundColor: gradient ? null : bg,
              foregroundColor: fg,
              disabledBackgroundColor:
                  widget.isSecondary ? Colors.transparent : AppColors.surfaceAlt,
              disabledForegroundColor: AppColors.inkFaint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: widget.isSecondary
                    ? BorderSide(color: fg.withValues(alpha: 0.4), width: 1.4)
                    : BorderSide.none,
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: gradient ? AppColors.goldGradient : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(fg),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 20, color: fg),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: fg,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

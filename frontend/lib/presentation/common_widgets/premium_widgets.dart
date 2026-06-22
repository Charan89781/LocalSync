import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GlassCard — Backdrop blur + gradient border glass container
// ─────────────────────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final double borderWidth;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.blurSigma = 16,
    this.backgroundColor,
    this.borderColor,
    this.shadows,
    this.borderWidth = 1,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.neonCyan.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 0),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (backgroundColor ?? Colors.white).withValues(alpha: 0.12),
                      (backgroundColor ?? Colors.white).withValues(alpha: 0.05),
                    ],
                  ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.15),
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GradientButton — Animated gradient with shimmer pulse
// ─────────────────────────────────────────────────────────────────────────────

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double? width;
  final List<Color>? gradientColors;
  final double borderRadius;
  final IconData? prefixIcon;
  final TextStyle? textStyle;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.width,
    this.gradientColors,
    this.borderRadius = 16,
    this.prefixIcon,
    this.textStyle,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ??
        [AppColors.primaryBlue, AppColors.neonCyan];

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              height: widget.height,
              width: widget.width ?? double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.centerLeft,
                  end: Alignment.lerp(
                    Alignment.centerRight,
                    Alignment.topRight,
                    _pulseAnimation.value * 0.3,
                  )!,
                ),
                boxShadow: widget.onPressed != null
                    ? [
                        BoxShadow(
                          color: colors.first.withValues(alpha: 
                              0.35 + _pulseAnimation.value * 0.15),
                          blurRadius: 16 + _pulseAnimation.value * 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: widget.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.prefixIcon != null) ...[
                          Icon(widget.prefixIcon,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: widget.textStyle ??
                              GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatusBadge — Colored pill with icon
// ─────────────────────────────────────────────────────────────────────────────

enum StatusType { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final IconData? icon;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusType.info,
    this.icon,
    this.compact = false,
  });

  Color get _bgColor {
    switch (type) {
      case StatusType.success:
        return AppColors.successGreen.withValues(alpha: 0.15);
      case StatusType.warning:
        return AppColors.warningOrange.withValues(alpha: 0.15);
      case StatusType.error:
        return AppColors.errorRed.withValues(alpha: 0.15);
      case StatusType.info:
        return AppColors.neonCyan.withValues(alpha: 0.15);
      case StatusType.neutral:
        return Colors.grey.withValues(alpha: 0.15);
    }
  }

  Color get _fgColor {
    switch (type) {
      case StatusType.success:
        return AppColors.successGreen;
      case StatusType.warning:
        return AppColors.warningOrange;
      case StatusType.error:
        return AppColors.errorRed;
      case StatusType.info:
        return AppColors.neonCyan;
      case StatusType.neutral:
        return Colors.grey;
    }
  }

  IconData get _defaultIcon {
    switch (type) {
      case StatusType.success:
        return Icons.check_circle_rounded;
      case StatusType.warning:
        return Icons.warning_rounded;
      case StatusType.error:
        return Icons.cancel_rounded;
      case StatusType.info:
        return Icons.info_rounded;
      case StatusType.neutral:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _fgColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? _defaultIcon, color: _fgColor, size: compact ? 12 : 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _fgColor,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SectionHeader — Title + 'See All' action
// ─────────────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel = 'See All',
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.neonCyan],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.textDark,
                ),
              ),
            ],
          ),
          if (trailing != null)
            trailing!
          else if (onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel ?? 'See All',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AppColors.primaryBlue),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedCounter — Counts up to target value
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedCounter extends StatefulWidget {
  final int targetValue;
  final String? prefix;
  final String? suffix;
  final Duration duration;
  final TextStyle? textStyle;

  const AnimatedCounter({
    super.key,
    required this.targetValue,
    this.prefix,
    this.suffix,
    this.duration = const Duration(milliseconds: 1500),
    this.textStyle,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: widget.targetValue.toDouble())
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.targetValue.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final value = _animation.value.toInt();
        return Text(
          '${widget.prefix ?? ''}$value${widget.suffix ?? ''}',
          style: widget.textStyle ??
              GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.neonCyan,
                letterSpacing: -1,
              ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EmptyStateWidget — Illustration + message + action
// ─────────────────────────────────────────────────────────────────────────────

class EmptyStateWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeController;
  late Animation<double> _floatAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        (widget.iconColor ?? AppColors.primaryBlue)
                            .withValues(alpha: 0.15),
                        (widget.iconColor ?? AppColors.neonCyan)
                            .withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: (widget.iconColor ?? AppColors.primaryBlue)
                          .withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 48,
                    color: widget.iconColor ?? AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white54 : AppColors.textGray,
                  height: 1.5,
                ),
              ),
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(height: 28),
                GradientButton(
                  label: widget.actionLabel!,
                  onPressed: widget.onAction,
                  width: 180,
                  height: 48,
                  borderRadius: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LoadingCard — Shimmer placeholder
// ─────────────────────────────────────────────────────────────────────────────

class LoadingCard extends StatelessWidget {
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const LoadingCard({
    super.key,
    this.height = 120,
    this.borderRadius = 20,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.surfaceNavy
          : Colors.grey.shade200,
      highlightColor: isDark
          ? AppColors.secondaryNavy
          : Colors.grey.shade100,
      child: Container(
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceNavy : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class LoadingListCard extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const LoadingListCard({
    super.key,
    this.itemCount = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(itemCount, (index) {
          return Shimmer.fromColors(
            baseColor: isDark
                ? AppColors.surfaceNavy
                : Colors.grey.shade200,
            highlightColor: isDark
                ? AppColors.secondaryNavy
                : Colors.grey.shade100,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.surfaceNavy : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.secondaryNavy
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.secondaryNavy
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 140,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.secondaryNavy
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

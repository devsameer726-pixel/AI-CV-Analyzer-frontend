import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A frosted-glass container built on [BackdropFilter].
///
/// Paints a semi-transparent fill with a subtle white stroke and a soft drop
/// shadow, then blurs whatever is behind it. Use [GlassContainer.frosted] for
/// the default look, or pass a custom [decoration] for neon-bordered variants.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 18,
    this.opacity = 0.06,
    this.radius = AppTheme.kRadius,
    this.border,
    this.margin,
    this.padding,
    this.decoration,
    this.shadows,
  }) : _neon = false;

  /// Glass container with a glowing neon accent border.
  const GlassContainer.neon({
    super.key,
    required this.child,
    this.blur = 18,
    this.opacity = 0.06,
    this.radius = AppTheme.kRadius,
    this.margin,
    this.padding,
    this.shadows,
  })  : border = null,
        decoration = null,
        _neon = true;

  final Widget child;
  final double blur;
  final double opacity;
  final double radius;
  final Border? border;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  final List<BoxShadow>? shadows;
  final bool _neon;

  @override
  Widget build(BuildContext context) {
    final boxDecoration = decoration ??
        glassDecoration(
          color: Colors.white.withValues(alpha: opacity),
          border: border,
          shadows: shadows,
          radius: radius,
          gradient: _neon
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    AppColors.accent.withValues(alpha: 0.05),
                  ],
                )
              : null,
        );

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: boxDecoration.color,
              image: boxDecoration.image,
              border: _neon
                  ? Border.all(
                      color: AppColors.accent.withValues(alpha: 0.45),
                      width: 1.2,
                    )
                  : boxDecoration.border,
              borderRadius: boxDecoration.borderRadius,
              boxShadow: boxDecoration.boxShadow,
              gradient: boxDecoration.gradient,
              shape: boxDecoration.shape,
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

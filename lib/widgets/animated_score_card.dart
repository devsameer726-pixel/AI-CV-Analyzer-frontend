import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../theme/app_theme.dart';

/// Large animated circular ATS score indicator (0 → 100%).
///
/// Color shifts dynamically: red < 50%, yellow 50–75%, green > 75%. The ring
/// animates from 0 to [score] on first build and re-animates whenever [score]
/// changes.
class AnimatedScoreCard extends StatefulWidget {
  const AnimatedScoreCard({
    super.key,
    required this.score,
    this.label = 'Overall ATS Score',
    this.subtitle,
  });

  final double score;
  final String label;
  final String? subtitle;

  @override
  State<AnimatedScoreCard> createState() => _AnimatedScoreCardState();
}

class _AnimatedScoreCardState extends State<AnimatedScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _progress = Tween<double>(begin: 0, end: widget.score / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _progress = Tween<double>(
        begin: _progress.value,
        end: widget.score / 100,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(widget.score);
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final value = _progress.value;
        return CircularPercentIndicator(
          radius: 90,
          lineWidth: 14,
          percent: value.clamp(0.0, 1.0),
          animation: false,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          progressColor: color,
          backgroundColor: AppColors.bgElevated,
          circularStrokeCap: CircularStrokeCap.round,
        ).animate().shimmer(
              duration: 2400.ms,
              color: color.withValues(alpha: 0.25),
            );
      },
    );
  }
}

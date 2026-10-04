import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../theme/theme.dart';

/// The DineCircle mark: a table seen from above — two rings with three guests
/// seated around it. Drawn in code so it stays crisp at any size.
class DcLogo extends StatelessWidget {
  const DcLogo({
    super.key,
    this.size = 32,
    this.color,
    this.accentColor,
    this.filled = false,
  });

  final double size;

  /// Ring colour. Defaults to the theme ink.
  final Color? color;

  /// Guest-dot colour. Defaults to the brand clay.
  final Color? accentColor;

  /// Inverts the mark for placement on solid brand surfaces.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final ring = filled ? dc.onAccent : (color ?? dc.ink);
    final dots = filled ? dc.onAccent : (accentColor ?? dc.accent);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(ring: ring, dots: dots),
        isComplex: false,
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.ring, required this.dots});

  final Color ring;
  final Color dots;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    final outer = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.078
      ..strokeCap = StrokeCap.round;

    final inner = Paint()
      ..color = ring.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round;

    final dot = Paint()..color = dots;

    canvas.drawCircle(center, s * 0.395, outer);
    canvas.drawCircle(center, s * 0.165, inner);

    for (final angle in const [90.0, 210.0, 330.0]) {
      final radians = angle * math.pi / 180;
      final position = Offset(
        center.dx + math.cos(radians) * s * 0.283,
        center.dy - math.sin(radians) * s * 0.283,
      );
      canvas.drawCircle(position, s * 0.052, dot);
    }
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      oldDelegate.ring != ring || oldDelegate.dots != dots;
}

/// Circular progress used to show how full a host's tables are.
class DcRing extends StatelessWidget {
  const DcRing({
    super.key,
    required this.value,
    this.size = 92,
    this.strokeWidth = 9,
    this.label,
    this.caption,
  });

  /// 0 – 1 progress.
  final double value;

  final double size;
  final double strokeWidth;
  final String? label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: Motion.emphasized,
        builder: (context, animated, _) => CustomPaint(
          painter: _RingPainter(
            value: animated,
            track: dc.surfaceSunken,
            progress: dc.accent,
            strokeWidth: strokeWidth,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label ?? '${(animated * 100).round()}%',
                  style: AppType.serif(
                    size * 0.28,
                    weight: 600,
                    height: 1,
                    tracking: -0.4,
                    color: dc.ink,
                  ),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    style: AppType.sans(
                      10,
                      weight: 560,
                      tracking: 0.3,
                      color: dc.inkFaint,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.track,
    required this.progress,
    required this.strokeWidth,
  });

  final double value;
  final Color track;
  final Color progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, base);

    final arc = Paint()
      ..color = progress
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.track != track ||
      oldDelegate.progress != progress;
}

/// The mark paired with the DineCircle wordmark.
class DcWordmark extends StatelessWidget {
  const DcWordmark({
    super.key,
    this.markSize = 30,
    this.fontSize = 22,
    this.color,
    this.centered = false,
  });

  final double markSize;
  final double fontSize;
  final Color? color;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: centered
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DcLogo(size: markSize),
        SizedBox(width: markSize * 0.36),
        Flexible(
          child: Text(
            'DineCircle',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: AppType.serif(
              fontSize,
              weight: 580,
              height: 1,
              tracking: -0.5,
              color: color ?? dc.ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Monthly performance chart used on the host earnings dashboard.
class TrendBars extends StatelessWidget {
  const TrendBars({
    super.key,
    required this.points,
    this.height = 132,
    this.showValue = true,
  });

  final List<EarningsPoint> points;
  final double height;

  /// Prints the revenue figure above the most recent bar.
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    if (points.isEmpty) return const SizedBox.shrink();

    final maxRevenue = points.map((p) => p.revenue).reduce(math.max);
    final lastIndex = points.length - 1;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < points.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 5,
                  right: i == points.length - 1 ? 0 : 5,
                ),
                child: _Bar(
                  point: points[i],
                  factor: maxRevenue == 0 ? 0 : points[i].revenue / maxRevenue,
                  highlighted: i == lastIndex,
                  showValue: showValue,
                  maxBarHeight: height - 40,
                  color: i == lastIndex ? null : dc.surfaceSunken,
                  dc: dc,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.point,
    required this.factor,
    required this.highlighted,
    required this.showValue,
    required this.maxBarHeight,
    required this.color,
    required this.dc,
  });

  final EarningsPoint point;
  final double factor;
  final bool highlighted;
  final bool showValue;
  final double maxBarHeight;
  final Color? color;
  final DcTheme dc;

  @override
  Widget build(BuildContext context) {
    final barHeight = (maxBarHeight * (0.18 + factor * 0.82)).clamp(
      14.0,
      maxBarHeight,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showValue && highlighted)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '€${point.revenue.toStringAsFixed(0)}',
              style: AppType.sans(
                10.5,
                weight: 700,
                height: 1,
                color: dc.accent,
              ),
            ),
          ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: barHeight),
          duration: Motion.slow,
          curve: Motion.emphasized,
          builder: (context, value, _) => Container(
            height: value,
            width: double.infinity,
            decoration: BoxDecoration(
              color: highlighted ? null : color,
              gradient: highlighted ? dc.accentGradient : null,
              borderRadius: BorderRadius.circular(Radii.xs + 2),
            ),
          ),
        ),
        const SizedBox(height: Space.sm),
        Text(
          point.label,
          style: AppType.sans(
            11.5,
            weight: highlighted ? 700 : 520,
            height: 1,
            color: highlighted ? dc.ink : dc.inkFaint,
          ),
        ),
      ],
    );
  }
}

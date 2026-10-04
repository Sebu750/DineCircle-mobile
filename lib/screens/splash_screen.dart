import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/dc_brand.dart';
import '../widgets/dc_image.dart';

/// Brand-first launch screen. Purely presentational — [RootGate] owns the
/// hand-off to the next surface, so this widget holds no timers of its own.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  late final Animation<double> _enter = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.55, curve: Motion.emphasized),
  );

  late final Animation<double> _copy = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.28, 0.78, curve: Motion.enter),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Scaffold(
      backgroundColor: dc.canvas,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DcAurora(
              colors: [Color(0x2EC1613A), Color(0x1FC08A2E), Color(0x00FBF7F1)],
            ),
          ),
          Positioned(
            left: -90,
            top: -60,
            child: _Glow(color: dc.accent.withValues(alpha: 0.20), size: 320),
          ),
          Positioned(
            right: -110,
            bottom: 40,
            child: _Glow(color: dc.gold.withValues(alpha: 0.16), size: 300),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _enter,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.88, end: 1).animate(_enter),
                    child: _MarkReveal(progress: _controller),
                  ),
                ),
                const SizedBox(height: Space.xxl + 4),
                FadeTransition(
                  opacity: _copy,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.28),
                      end: Offset.zero,
                    ).animate(_copy),
                    child: Column(
                      children: [
                        Text(
                          'DineCircle',
                          style: AppType.serif(
                            42,
                            weight: 560,
                            height: 1,
                            tracking: -1.0,
                            color: dc.ink,
                          ),
                        ),
                        const SizedBox(height: Space.md),
                        SizedBox(
                          width: 34,
                          child: Divider(color: dc.line, height: 1),
                        ),
                        const SizedBox(height: Space.md),
                        Text(
                          'Create a table. Discover a table.',
                          textAlign: TextAlign.center,
                          style: AppType.serif(
                            16.5,
                            weight: 440,
                            height: 1.5,
                            tracking: -0.1,
                            color: dc.inkMuted,
                            style: FontStyle.italic,
                          ),
                        ),
                        Text(
                          'Meet people. Experience food.',
                          textAlign: TextAlign.center,
                          style: AppType.serif(
                            16.5,
                            weight: 440,
                            height: 1.5,
                            tracking: -0.1,
                            color: dc.inkMuted,
                            style: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: Space.xxl),
                child: FadeTransition(
                  opacity: _copy,
                  child: Center(
                    child: Text(
                      'SOCIAL DINING CLUB',
                      style: AppType.overline(color: dc.inkFaint, size: 10),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The mark inside a plate, wrapped by a sweeping progress ring.
class _MarkReveal extends StatelessWidget {
  const _MarkReveal({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    const ringSize = 148.0;
    const plateSize = 112.0;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, child) {
          final t = Curves.easeInOutCubic.transform(
            progress.value.clamp(0.0, 1.0),
          );
          return CustomPaint(
            painter: _SweepPainter(
              value: t,
              track: dc.line.withValues(alpha: 0.7),
              sweep: dc.accent,
            ),
            child: child,
          );
        },
        child: Center(
          child: Container(
            width: plateSize,
            height: plateSize,
            decoration: BoxDecoration(
              color: dc.surface,
              shape: BoxShape.circle,
              border: Border.all(color: dc.line, width: 1),
              boxShadow: dc.shadowMd,
            ),
            child: Center(child: DcLogo(size: 54)),
          ),
        ),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter({
    required this.value,
    required this.track,
    required this.sweep,
  });

  final double value;
  final Color track;
  final Color sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..color = sweep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SweepPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.track != track ||
      oldDelegate.sweep != sweep;
}

/// Soft radial colour wash used to keep the canvas from feeling flat.
class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

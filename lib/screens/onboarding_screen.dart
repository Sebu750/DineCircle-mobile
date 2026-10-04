import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_scope.dart';
import '../data/image_catalog.dart';
import '../theme/theme.dart';
import '../widgets/dc_brand.dart';
import '../widgets/dc_buttons.dart';
import '../widgets/dc_image.dart';

/// One slide of the introduction.
class _Slide {
  const _Slide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.image,
    required this.tint,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String image;
  final Color tint;
}

const List<_Slide> _slides = [
  _Slide(
    eyebrow: 'Create',
    title: 'Host a table worth\nremembering',
    body:
        'Pick the restaurant, set the date, choose the seats, the menu and the '
        'price. Your table, your rules.',
    image: Img.longTable,
    tint: Color(0xFF8C3A17),
  ),
  _Slide(
    eyebrow: 'Discover',
    title: 'Find dinners\naround the corner',
    body:
        'Curated tables from food creators, neighbourhood chefs and restaurant '
        'partners — all bookable in a couple of taps.',
    image: Img.rooftop,
    tint: Color(0xFF243B4A),
  ),
  _Slide(
    eyebrow: 'Belong',
    title: 'Sit with friends,\nor with strangers',
    body:
        'Join the people you follow, or take a chance on a table of new faces. '
        'Either way, you leave with a story.',
    image: Img.supperClub,
    tint: Color(0xFF4A2338),
  ),
];

/// Three-slide introduction shown once per install.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _footerHeight = 196.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _slides.length - 1) {
      _finish();
      return;
    }
    HapticFeedback.selectionClick();
    _controller.nextPage(duration: Motion.page, curve: Motion.emphasized);
  }

  void _finish() {
    HapticFeedback.mediumImpact();
    context.app.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (value) => setState(() => _index = value),
              itemCount: _slides.length,
              itemBuilder: (context, i) => _SlideView(
                slide: _slides[i],
                bottomInset:
                    _footerHeight + MediaQuery.viewPaddingOf(context).bottom,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.sm,
                  Space.md,
                  0,
                ),
                child: Row(
                  children: [
                    const _GlassWordmark(),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.md,
                          vertical: Space.sm,
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: AppType.sans(
                          13.5,
                          weight: 620,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewPaddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.huge,
                  Space.gutter,
                  Space.xxl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Dots(count: _slides.length, index: _index),
                    const SizedBox(height: Space.xxl),
                    DcButton(
                      last ? 'Create my account' : 'Continue',
                      size: DcButtonSize.large,
                      trailingIcon: last ? null : Icons.arrow_forward_rounded,
                      onPressed: _next,
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

/// The wordmark over photography, wrapped in a subtle glass pill.
class _GlassWordmark extends StatelessWidget {
  const _GlassWordmark();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.md, 7, Space.lg, 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DcLogo(size: 17, color: Colors.white, accentColor: AppColors.clay400),
          const SizedBox(width: 8),
          Text(
            'DineCircle',
            style: AppType.serif(
              15.5,
              weight: 560,
              height: 1,
              tracking: -0.3,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Motion.base,
            curve: Motion.emphasized,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: i == index ? 26 : 6,
            decoration: BoxDecoration(
              color: i == index
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
      ],
    );
  }
}

/// A single full-bleed slide with staggered copy.
class _SlideView extends StatefulWidget {
  const _SlideView({required this.slide, required this.bottomInset});

  final _Slide slide;
  final double bottomInset;

  @override
  State<_SlideView> createState() => _SlideViewState();
}

class _SlideViewState extends State<_SlideView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  Animation<double> _at(double begin, double end) => CurvedAnimation(
    parent: _controller,
    curve: Interval(begin, end, curve: Motion.emphasized),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;

    return Stack(
      fit: StackFit.expand,
      children: [
        DcImage(
          slide.image,
          fit: BoxFit.cover,
          scrim: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.42),
              Colors.black.withValues(alpha: 0.06),
              Colors.black.withValues(alpha: 0.55),
              Colors.black.withValues(alpha: 0.92),
            ],
            stops: const [0, 0.26, 0.62, 1],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            Space.gutter,
            0,
            Space.gutter,
            widget.bottomInset,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Reveal(
                animation: _at(0.05, 0.55),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: slide.tint.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(Radii.pill),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    slide.eyebrow.toUpperCase(),
                    style: AppType.overline(
                      size: 10,
                      tracking: 1.8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),
              _Reveal(
                animation: _at(0.14, 0.68),
                child: Text(
                  slide.title,
                  style: AppType.serif(
                    34,
                    weight: 520,
                    height: 1.14,
                    tracking: -1.0,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: Space.md),
              _Reveal(
                animation: _at(0.24, 0.8),
                child: Text(
                  slide.body,
                  style: AppType.sans(
                    14.5,
                    weight: 420,
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, inner) => Transform.translate(
          offset: Offset(0, 22 * (1 - animation.value)),
          child: inner,
        ),
        child: child,
      ),
    );
  }
}

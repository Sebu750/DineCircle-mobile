import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_scope.dart';
import '../theme/theme.dart';
import '../widgets/dc_buttons.dart';
import '../widgets/dc_controls.dart';
import '../widgets/dc_image.dart';
import '../widgets/dc_pills.dart';
import '../widgets/dc_surfaces.dart';

/// Which half of the sign-in flow is on screen.
enum _Step { phone, code }

const _countries = <(String, String, String)>[
  ('🇵🇹', 'Portugal', '+351'),
  ('🇪🇸', 'Spain', '+34'),
  ('🇫🇷', 'France', '+33'),
  ('🇮🇹', 'Italy', '+39'),
  ('🇬🇧', 'United Kingdom', '+44'),
  ('🇩🇪', 'Germany', '+49'),
  ('🇳🇱', 'Netherlands', '+31'),
  ('🇺🇸', 'United States', '+1'),
];

/// Phone-first sign in: number → one-time code. The prototype accepts any
/// six-digit code, so the whole flow can be walked through without a backend.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phone = TextEditingController(
    text: '912 345 678',
  );
  final TextEditingController _code = TextEditingController();
  final FocusNode _codeFocus = FocusNode();

  _Step _step = _Step.phone;
  bool _forward = true;
  int _dialIndex = 0;
  bool _sending = false;
  bool _verifying = false;

  Timer? _ticker;
  int _resendIn = 30;

  String get _dialCode => _countries[_dialIndex].$3;

  String get _prettyNumber => '$_dialCode ${_phone.text.trim()}';

  bool get _phoneValid => _digits(_phone.text).length >= 9;

  static String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    _code.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.removeListener(_onCodeChanged);
    _phone.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _onCodeChanged() => setState(() {});

  void _startCountdown() {
    _ticker?.cancel();
    setState(() => _resendIn = 30);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendIn <= 1) {
        timer.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  Future<void> _sendCode() async {
    if (!_phoneValid || _sending) return;
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    try {
      final phone = '+${_digits(_dialCode)}${_digits(_phone.text)}';
      await context.app.requestOtp(phone);
    } catch (_) {
      // Prototype always succeeds — the code is 123456.
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _forward = true;
      _step = _Step.code;
    });
    _startCountdown();
    // Give the incoming step a frame before stealing focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _codeFocus.requestFocus();
    });
  }

  Future<void> _verify() async {
    if (_code.text.length < 6 || _verifying) return;
    HapticFeedback.mediumImpact();
    setState(() => _verifying = true);
    try {
      final phone = '+${_digits(_dialCode)}${_digits(_phone.text)}';
      await context.app.signIn(phone, _code.text.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _back() {
    _ticker?.cancel();
    _code.clear();
    setState(() {
      _forward = false;
      _step = _Step.phone;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Scaffold(
      backgroundColor: dc.canvas,
      body: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 300,
            child: DcAurora(
              colors: [Color(0x24C1613A), Color(0x14000000), Color(0x00FBF7F1)],
            ),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: Motion.page,
              switchInCurve: Motion.emphasized,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final offset = Tween<Offset>(
                  begin: Offset(_forward ? 0.12 : -0.12, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: _step == _Step.phone
                  ? _buildPhoneStep(dc)
                  : _buildCodeStep(dc),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step one: the number ─────────────────────────────────────────────────
  Widget _buildPhoneStep(DcTheme dc) {
    return SingleChildScrollView(
      key: const ValueKey('phone'),
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        Space.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Space.lg),
          Text(
            'Welcome to\nthe table.',
            style: AppType.serif(
              36,
              weight: 540,
              height: 1.1,
              tracking: -1.1,
              color: dc.ink,
            ),
          ),
          const SizedBox(height: Space.md),
          Text(
            'Sign in to book seats, host dinners and meet your circle over '
            'great food.',
            style: AppType.sans(
              14.5,
              weight: 420,
              height: 1.55,
              color: dc.inkMuted,
            ),
          ),
          const SizedBox(height: Space.xxxl),
          Text('MOBILE NUMBER', style: AppType.overline(color: dc.inkFaint)),
          const SizedBox(height: Space.sm),
          _PhoneField(
            controller: _phone,
            dialCode: _dialCode,
            onChanged: (_) => setState(() {}),
            onCountryTap: _pickCountry,
            onSubmitted: _sendCode,
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 15,
                color: dc.inkFaint,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Prototype build — no SMS is sent. Any six-digit code works.',
                  style: AppType.sans(
                    12,
                    weight: 460,
                    height: 1.4,
                    color: dc.inkFaint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xxl),
          DcButton(
            'Send code',
            size: DcButtonSize.large,
            isLoading: _sending,
            enabled: _phoneValid,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: _sendCode,
          ),
          const SizedBox(height: Space.xxl),
          Row(
            children: [
              Expanded(child: Divider(color: dc.line, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.md),
                child: Text(
                  'or',
                  style: AppType.sans(12, weight: 560, color: dc.inkFaint),
                ),
              ),
              Expanded(child: Divider(color: dc.line, height: 1)),
            ],
          ),
          const SizedBox(height: Space.xxl),
          DcButton(
            'Continue with Google',
            variant: DcButtonVariant.outline,
            size: DcButtonSize.medium,
            icon: Icons.g_mobiledata_rounded,
            onPressed: _socialSignIn,
          ),
          const SizedBox(height: Space.md),
          DcButton(
            'Continue with Apple',
            variant: DcButtonVariant.outline,
            size: DcButtonSize.medium,
            icon: Icons.apple_rounded,
            onPressed: _socialSignIn,
          ),
          const SizedBox(height: Space.xxxl),
          Center(
            child: Text.rich(
              TextSpan(
                text: 'By continuing you agree to our ',
                children: [
                  TextSpan(
                    text: 'Terms',
                    style: AppType.sans(11.5, weight: 620, color: dc.inkMuted),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Community Guidelines',
                    style: AppType.sans(11.5, weight: 620, color: dc.inkMuted),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: AppType.sans(
                11.5,
                weight: 440,
                height: 1.6,
                color: dc.inkFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step two: the code ───────────────────────────────────────────────────
  Widget _buildCodeStep(DcTheme dc) {
    final complete = _code.text.length == 6;

    return SingleChildScrollView(
      key: const ValueKey('code'),
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        Space.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DcIconButton(
            Icons.arrow_back_rounded,
            size: 40,
            iconSize: 20,
            variant: DcIconButtonVariant.surface,
            onPressed: _back,
          ),
          const SizedBox(height: Space.xl),
          Text(
            'Check your\nmessages.',
            style: AppType.serif(
              34,
              weight: 540,
              height: 1.12,
              tracking: -1.0,
              color: dc.ink,
            ),
          ),
          const SizedBox(height: Space.md),
          Text.rich(
            TextSpan(
              text: 'We sent a six-digit code to ',
              children: [
                TextSpan(
                  text: _prettyNumber,
                  style: AppType.sans(13.5, weight: 680, color: dc.ink),
                ),
              ],
            ),
            style: AppType.sans(
              13.5,
              weight: 430,
              height: 1.6,
              color: dc.inkMuted,
            ),
          ),
          const SizedBox(height: Space.xxxl),
          _OtpField(
            controller: _code,
            focusNode: _codeFocus,
            onCompleted: _verify,
          ),
          const SizedBox(height: Space.xl),
          Row(
            children: [
              if (_resendIn > 0) ...[
                Icon(Icons.timer_outlined, size: 15, color: dc.inkFaint),
                const SizedBox(width: 6),
                Text(
                  'Resend code in 0:${_resendIn.toString().padLeft(2, '0')}',
                  style: AppType.sans(12.5, weight: 520, color: dc.inkFaint),
                ),
              ] else
                GestureDetector(
                  onTap: () {
                    _startCountdown();
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code resent')),
                    );
                  },
                  child: Text(
                    'Resend code',
                    style: AppType.sans(12.5, weight: 660, color: dc.accent),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: _back,
                child: Text(
                  'Change number',
                  style: AppType.sans(12.5, weight: 620, color: dc.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xxxl),
          DcButton(
            'Verify and continue',
            size: DcButtonSize.large,
            isLoading: _verifying,
            enabled: complete,
            onPressed: _verify,
          ),
          const SizedBox(height: Space.xl),
          Center(
            child: DcTag(
              'Prototype — any 6-digit code signs you in',
              icon: Icons.science_outlined,
              tone: PillTone.accent,
              size: DcTagSize.small,
            ),
          ),
        ],
      ),
    );
  }

  void _socialSignIn() {
    HapticFeedback.lightImpact();
    // Quick dev shortcut — uses the default seeded number.
    context.app.signIn('+351910000001', '123456');
  }

  Future<void> _pickCountry() async {
    final picked = await DcSheet.show<int>(
      context,
      builder: (context) => DcSheet(
        title: 'Where are you dialling from?',
        child: SizedBox(
          height: 340,
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: Space.lg),
            itemCount: _countries.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            itemBuilder: (context, i) {
              final country = _countries[i];
              return DcSelectRow(
                icon: Icons.flag_outlined,
                title: '${country.$1}  ${country.$2}',
                value: country.$3,
                onTap: () => Navigator.of(context).pop(i),
              );
            },
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _dialIndex = picked);
  }
}

/// Country chip plus the number itself, laid out as one control.
class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.dialCode,
    required this.onChanged,
    required this.onCountryTap,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String dialCode;
  final ValueChanged<String> onChanged;
  final VoidCallback onCountryTap;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
      decoration: BoxDecoration(
        color: dc.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: dc.line, width: 1.2),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onCountryTap,
            borderRadius: BorderRadius.circular(Radii.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.sm,
                vertical: Space.sm,
              ),
              child: Row(
                children: [
                  Text(
                    dialCode,
                    style: AppType.sans(15, weight: 640, color: dc.ink),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more_rounded, size: 18, color: dc.inkFaint),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 24, color: dc.line),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: Space.md),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: (_) => onSubmitted(),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                  _GroupedDigits(),
                ],
                style: AppType.sans(16, weight: 600, color: dc.ink),
                cursorColor: dc.accent,
                cursorWidth: 1.8,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: '900 000 000',
                  hintStyle: AppType.sans(16, weight: 460, color: dc.inkFaint),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Spaces a run of digits into groups of three as the guest types.
class _GroupedDigits extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Six character boxes driven by a single hidden field.
class _OtpField extends StatelessWidget {
  const _OtpField({
    required this.controller,
    required this.focusNode,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: SizedBox(
        height: 68,
        child: Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < 6; i++) ...[
                  if (i > 0) const SizedBox(width: Space.sm),
                  Expanded(
                    child: _OtpBox(
                      index: i,
                      value: i < controller.text.length
                          ? controller.text[i]
                          : null,
                      active: focusNode.hasFocus && i == controller.text.length,
                    ),
                  ),
                ],
              ],
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (value) {
                    if (value.length == 6) onCompleted();
                  },
                  showCursor: false,
                  style: const TextStyle(color: Colors.transparent),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.index,
    required this.value,
    required this.active,
  });

  final int index;
  final String? value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final filled = value != null;

    return AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.enter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? dc.accentSoft : dc.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: active
              ? dc.accent
              : (filled ? dc.accent.withValues(alpha: 0.35) : dc.line),
          width: active ? 1.8 : 1.2,
        ),
      ),
      child: value == null
          ? (active
                ? Container(
                    width: 2,
                    height: 22,
                    decoration: BoxDecoration(
                      color: dc.accent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  )
                : null)
          : Text(
              value!,
              style: AppType.serif(
                24,
                weight: 600,
                height: 1,
                tracking: 0,
                color: dc.ink,
              ),
            ),
    );
  }
}

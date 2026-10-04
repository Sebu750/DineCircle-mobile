import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../data/app_scope.dart';
import '../models/booking.dart';
import '../models/dinner_event.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// Mock payment methods offered at checkout.
const _methods = <(String, IconData, String)>[
  ('Apple Pay', Icons.apple_rounded, 'Instant · no card needed'),
  ('Google Pay', Icons.g_mobiledata_rounded, 'Instant · no card needed'),
  ('Visa •••• 4242', Icons.credit_card_rounded, 'Expires 09 / 28'),
  ('New card', Icons.add_card_rounded, 'Add a payment method'),
];

/// The join & pay flow: pick seats, review the split, choose how to pay.
///
/// Reserving updates the store, so the seat meter, the table and the host's
/// console all move together.
class JoinSheet extends StatefulWidget {
  const JoinSheet({super.key, required this.eventId});

  final String eventId;

  static Future<Booking?> show(
    BuildContext context, {
    required String eventId,
  }) {
    return DcSheet.show<Booking>(
      context,
      builder: (_) => JoinSheet(eventId: eventId),
    );
  }

  @override
  State<JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<JoinSheet> {
  int _seats = 1;
  int _method = 0;
  bool _paying = false;
  Booking? _confirmed;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final event = app.event(widget.eventId);
    final confirmed = _confirmed;

    return DcSheet(
      title: confirmed == null ? 'Reserve your seat' : null,
      subtitle: confirmed == null
          ? '${event.title} · ${Fmt.dayMonth(event.start)}'
          : null,
      child: AnimatedSize(
        duration: Motion.base,
        curve: Motion.emphasized,
        alignment: Alignment.topCenter,
        child: confirmed == null
            ? _buildForm(context, event, app.seatsLeftFor(event.id))
            : _Confirmation(booking: confirmed, event: event),
      ),
    );
  }

  Widget _buildForm(BuildContext context, DinnerEvent event, int seatsLeft) {
    final dc = context.dc;
    final maxSeats = seatsLeft.clamp(1, 6);
    final subtotal = event.pricePerSeat * _seats;
    final fee = double.parse((subtotal * 0.06).toStringAsFixed(2));
    final total = subtotal + fee;
    final invitesReview = event.audience == Audience.inviteOnly;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DcSurface(
            radius: Radii.lg,
            shadows: dc.shadowSm,
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              children: [
                DcStepper(
                  value: _seats,
                  min: 1,
                  max: maxSeats,
                  onChanged: (value) => setState(() => _seats = value),
                ),
                const SizedBox(height: Space.md),
                Divider(color: dc.line, height: 1),
                const SizedBox(height: Space.md),
                Row(
                  children: [
                    Icon(
                      Icons.event_seat_rounded,
                      size: 15,
                      color: dc.inkFaint,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _seats == 1
                            ? 'One seat at this table'
                            : 'You and ${_seats - 1} ${_seats == 2 ? 'guest' : 'guests'}',
                        style: AppType.sans(
                          12.5,
                          weight: 560,
                          color: dc.inkMuted,
                        ),
                      ),
                    ),
                    Text(
                      seatsLeft <= 3
                          ? 'Only $seatsLeft left'
                          : '$seatsLeft seats available',
                      style: AppType.sans(
                        12,
                        weight: 640,
                        color: seatsLeft <= 3 ? dc.gold : dc.inkFaint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          DcSurface(
            radius: Radii.lg,
            shadows: dc.shadowSm,
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              children: [
                DcKeyValue(
                  label: '${Fmt.money(event.pricePerSeat)} × $_seats',
                  value: Fmt.money(subtotal),
                ),
                DcKeyValue(
                  label: 'Service fee · 6%',
                  value: Fmt.money(fee),
                  divider: true,
                ),
                DcKeyValue(
                  label: 'Total today',
                  value: Fmt.money(total),
                  emphasis: true,
                  divider: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          Padding(
            padding: const EdgeInsets.only(left: Space.xs, bottom: Space.md),
            child: Text(
              'PAY WITH',
              style: AppType.overline(color: dc.inkFaint),
            ),
          ),
          DcSurface(
            radius: Radii.lg,
            shadows: dc.shadowSm,
            clip: true,
            child: Column(
              children: [
                for (var i = 0; i < _methods.length; i++) ...[
                  if (i > 0) Divider(color: dc.line, height: 1),
                  _MethodRow(
                    label: _methods[i].$1,
                    hint: _methods[i].$3,
                    icon: _methods[i].$2,
                    selected: _method == i,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _method = i);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                invitesReview
                    ? Icons.hourglass_top_rounded
                    : Icons.bolt_rounded,
                size: 15,
                color: invitesReview ? dc.gold : dc.pine,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  invitesReview
                      ? 'This host approves every guest. You will hear back within a day.'
                      : 'Instant confirmation — your seat is locked in straight away.',
                  style: AppType.sans(
                    12,
                    weight: 500,
                    height: 1.45,
                    color: dc.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          DcButton(
            'Confirm and pay ${Fmt.money(fee + subtotal)}',
            size: DcButtonSize.large,
            isLoading: _paying,
            onPressed: () => _pay(context),
          ),
          const SizedBox(height: Space.md),
          Center(
            child: Text(
              'Free cancellation until 48 hours before the table',
              textAlign: TextAlign.center,
              style: AppType.sans(11.5, weight: 480, color: dc.inkFaint),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pay(BuildContext context) async {
    if (_paying) return;
    final app = context.app;
    HapticFeedback.mediumImpact();
    setState(() => _paying = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final booking = await app.book(
      eventId: widget.eventId,
      seats: _seats,
      paymentLabel: _methods[_method].$1,
    );
    setState(() {
      _paying = false;
      _confirmed = booking;
    });
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.label,
    required this.hint,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final tone = selected ? dc.accent : dc.inkMuted;

    return Material(
      color: selected ? dc.accentSoft.withValues(alpha: 0.5) : dc.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.md + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? dc.surface : dc.surfaceAlt,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border: Border.all(color: selected ? dc.accent : dc.line),
                ),
                child: Icon(icon, size: 19, color: tone),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: context.text.titleSmall),
                    const SizedBox(height: 2),
                    Text(hint, style: context.text.bodySmall),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: Motion.fast,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? dc.accent : Colors.transparent,
                  border: Border.all(
                    color: selected ? dc.accent : dc.line,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 13, color: dc.onAccent)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Post-payment state: what was booked, and the reference to show at the door.
class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.booking, required this.event});

  final Booking booking;
  final DinnerEvent event;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final host = app.hostOf(event);
    final venue = app.restaurantFor(event);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: Space.sm),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Motion.slow,
          curve: Motion.emphasized,
          builder: (context, value, child) => Transform.scale(
            scale: 0.7 + value * 0.3,
            child: Opacity(opacity: value, child: child),
          ),
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: dc.pineSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 36, color: dc.pine),
          ),
        ),
        const SizedBox(height: Space.xl),
        Text(
          'Your seat is booked',
          textAlign: TextAlign.center,
          style: AppType.serif(
            25,
            weight: 560,
            height: 1.15,
            tracking: -0.6,
            color: dc.ink,
          ),
        ),
        const SizedBox(height: Space.sm),
        Text(
          'We sent the ticket to your phone. Show the reference at the door.',
          textAlign: TextAlign.center,
          style: AppType.sans(
            13.5,
            weight: 440,
            height: 1.5,
            color: dc.inkMuted,
          ),
        ),
        const SizedBox(height: Space.xl),
        DcSurface(
          radius: Radii.lg,
          shadows: dc.shadowSm,
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            children: [
              DcKeyValue(label: 'Table', value: event.title),
              DcKeyValue(
                label: 'When',
                value:
                    '${Fmt.dayMonth(event.start)} · ${Fmt.clock(event.start)}',
                divider: true,
              ),
              DcKeyValue(
                label: 'Where',
                value: '${venue.name}, ${venue.neighborhood}',
                divider: true,
              ),
              DcKeyValue(
                label: 'Host',
                value: '@${host.handle}',
                divider: true,
              ),
              DcKeyValue(
                label: booking.seats == 1 ? 'Seat' : 'Seats',
                value: '${booking.seats}',
                divider: true,
              ),
              DcKeyValue(
                label: 'Paid with ${booking.paymentLabel}',
                value: Fmt.money(booking.total),
                emphasis: true,
                divider: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        DcSurface(
          radius: Radii.md,
          color: dc.surfaceAlt,
          showBorder: false,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.md,
          ),
          child: Row(
            children: [
              Icon(Icons.qr_code_2_rounded, size: 20, color: dc.inkMuted),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  booking.reference,
                  style: AppType.sans(
                    14,
                    weight: 700,
                    tracking: 1.2,
                    color: dc.ink,
                  ),
                ),
              ),
              Icon(
                Icons.confirmation_number_rounded,
                size: 18,
                color: dc.inkFaint,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        DcButton(
          'Done',
          size: DcButtonSize.large,
          onPressed: () => Navigator.of(context).maybePop(booking),
        ),
      ],
    );
  }
}

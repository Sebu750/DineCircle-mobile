import 'package:intl/intl.dart';

/// Presentation helpers shared across screens.
abstract final class Fmt {
  static const currencySymbol = '€';

  /// `$120` for whole amounts, `$120.50` when cents matter.
  static String money(
    num amount, {
    bool withCents = false,
    String symbol = currencySymbol,
  }) {
    final value = amount.toDouble();
    final format = withCents || value % 1 != 0
        ? NumberFormat('#,##0.00', 'en_US')
        : NumberFormat('#,##0', 'en_US');
    return '$symbol${format.format(value)}';
  }

  /// Compact large numbers: `980`, `4.2k`, `18k`.
  static String compact(num value) {
    if (value < 1000) return value.toStringAsFixed(0);
    if (value < 10000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '${(value / 1000).round()}k';
  }

  static final _weekday = DateFormat('EEE', 'en_US');
  static final _dayMonth = DateFormat('d MMM', 'en_US');
  static final _monthDay = DateFormat('MMM d', 'en_US');
  static final _fullDate = DateFormat('EEEE, d MMMM', 'en_US');
  static final _clock = DateFormat('h:mm a', 'en_US');
  static final _clockCompact = DateFormat('h a', 'en_US');
  static final _monthYear = DateFormat('MMMM yyyy', 'en_US');

  static String weekday(DateTime d) => _weekday.format(d);
  static String dayMonth(DateTime d) => _dayMonth.format(d);
  static String monthDay(DateTime d) => _monthDay.format(d);
  static String fullDate(DateTime d) => _fullDate.format(d);
  static String clock(DateTime d) => _clock.format(d).toLowerCase();
  static String clockCompact(DateTime d) =>
      _clockCompact.format(d).toLowerCase();
  static String monthYear(DateTime d) => _monthYear.format(d);

  /// Numeric day for calendar badges: `07`.
  static String dayNumber(DateTime d) => d.day.toString().padLeft(2, '0');

  /// Short month for calendar badges: `OCT`.
  static String monthTag(DateTime d) =>
      DateFormat('MMM', 'en_US').format(d).toUpperCase();

  /// Human countdown: `Tonight`, `Tomorrow`, `In 4 days`.
  static String until(DateTime target, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(target.year, target.month, target.day);
    final days = that.difference(today).inDays;
    if (days < 0) return 'Past';
    if (days == 0) {
      return target.hour >= 17 ? 'Tonight' : 'Today';
    }
    if (days == 1) return 'Tomorrow';
    if (days < 7) return 'In $days days';
    if (days < 14) return 'Next week';
    return 'In ${(days / 7).floor()} weeks';
  }

  /// `2h 30m`, `45m`, `3h`.
  static String duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// `1.2 km` / `850 m` from metres.
  static String distance(num meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static const _initials = [
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];
  static String monthInitial(DateTime d) => _initials[d.month - 1];
}

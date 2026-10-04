/// Lifecycle of a guest's seat reservation.
enum BookingStatus {
  confirmed('Confirmed'),
  pending('Pending'),
  completed('Attended'),
  cancelled('Refunded');

  const BookingStatus(this.label);

  final String label;
}

/// A paid reservation of one or more seats at a dinner.
class Booking {
  const Booking({
    required this.id,
    required this.eventId,
    required this.guestId,
    required this.seats,
    required this.pricePerSeat,
    required this.createdAt,
    required this.reference,
    required this.paymentLabel,
    this.status = BookingStatus.confirmed,
    this.checkedIn = false,
  });

  final String id;
  final String eventId;
  final String guestId;
  final int seats;
  final double pricePerSeat;
  final DateTime createdAt;

  /// Human-friendly code shown on the ticket, e.g. `DC-8H4K2`.
  final String reference;

  /// Masked instrument, e.g. `Visa •••• 4242`.
  final String paymentLabel;

  final BookingStatus status;
  final bool checkedIn;

  /// DineCircle's guest service fee, charged on top of the seat price.
  double get serviceFee =>
      double.parse((pricePerSeat * seats * 0.06).toStringAsFixed(2));

  double get subtotal => pricePerSeat * seats;

  double get total => double.parse((subtotal + serviceFee).toStringAsFixed(2));

  Booking copyWith({BookingStatus? status, bool? checkedIn}) {
    return Booking(
      id: id,
      eventId: eventId,
      guestId: guestId,
      seats: seats,
      pricePerSeat: pricePerSeat,
      createdAt: createdAt,
      reference: reference,
      paymentLabel: paymentLabel,
      status: status ?? this.status,
      checkedIn: checkedIn ?? this.checkedIn,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      guestId: json['guestId'] as String,
      seats: (json['seats'] as num?)?.toInt() ?? 1,
      pricePerSeat: (json['pricePerSeat'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reference: json['reference'] as String? ?? '',
      paymentLabel: json['paymentLabel'] as String? ?? '',
      status: BookingStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      checkedIn: json['checkedIn'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'guestId': guestId,
    'seats': seats,
    'pricePerSeat': pricePerSeat,
    'createdAt': createdAt.toIso8601String(),
    'reference': reference,
    'paymentLabel': paymentLabel,
    'status': status.name,
    'checkedIn': checkedIn,
  };
}

/// Where a host payout stands.
enum PayoutStatus {
  paid('Paid'),
  inTransit('In transit'),
  scheduled('Scheduled');

  const PayoutStatus(this.label);

  final String label;
}

/// A single line in a host's earnings history.
class Payout {
  const Payout({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.date,
    required this.seatsSold,
    required this.gross,
    required this.commission,
    required this.status,
  });

  final String id;
  final String eventId;
  final String eventTitle;
  final DateTime date;
  final int seatsSold;

  /// Total collected from guests before fees.
  final double gross;

  /// DineCircle's platform commission.
  final double commission;

  final PayoutStatus status;

  double get net => double.parse((gross - commission).toStringAsFixed(2));

  /// Commission as a 0 – 1 ratio, for the breakdown bar.
  double get commissionRatio => gross == 0 ? 0 : commission / gross;

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      eventTitle: json['eventTitle'] as String? ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      seatsSold: (json['seatsSold'] as num?)?.toInt() ?? 0,
      gross: (json['gross'] as num?)?.toDouble() ?? 0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0,
      status: PayoutStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PayoutStatus.paid,
      ),
    );
  }
}

/// A month of aggregated host performance.
class EarningsPoint {
  const EarningsPoint({
    required this.label,
    required this.seats,
    required this.revenue,
  });

  final String label;
  final int seats;
  final double revenue;

  factory EarningsPoint.fromJson(Map<String, dynamic> json) {
    return EarningsPoint(
      label: json['label'] as String? ?? '',
      seats: (json['seats'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

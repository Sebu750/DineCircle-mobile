import { Router } from 'express';
import { z } from 'zod';
import { query, withTransaction } from '../db.js';
import { ApiError, notFound, forbidden } from '../context.js';

const router = Router();

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/** Human-readable booking reference, e.g. `DC-7K3MQ`. */
function makeReference(): string {
  let code = '';
  for (let i = 0; i < 5; i++) {
    code += ALPHABET[Math.floor(Math.random() * ALPHABET.length)] ?? 'X';
  }
  return `DC-${code}`;
}

type BookingRow = {
  id: string;
  event_id: string;
  user_id: string;
  seats: number;
  price_per_seat: string;
  total_amount: string;
  created_at: Date;
  reference: string;
  payment_label: string;
  status: string;
  checked_in: boolean;
  title: string;
  start_at: Date;
  cover_image: string;
  host_name: string | null;
  restaurant_name: string | null;
};

const BOOKING_SELECT = `
  SELECT b.*, e.title, e.start_at, e.cover_image,
         u.name AS host_name, r.name AS restaurant_name
  FROM bookings b
  JOIN dinner_events e ON e.id = b.event_id
  LEFT JOIN users u ON u.id = e.host_id
  LEFT JOIN restaurants r ON r.id = e.restaurant_id`;

function serialize(row: BookingRow) {
  return {
    id: row.id,
    eventId: row.event_id,
    eventTitle: row.title,
    eventCoverImage: row.cover_image,
    hostName: row.host_name,
    restaurantName: row.restaurant_name,
    userId: row.user_id,
    seats: row.seats,
    pricePerSeat: Number(row.price_per_seat),
    total: Number(row.total_amount),
    reference: row.reference,
    paymentLabel: row.payment_label,
    status: row.status,
    checkedIn: row.checked_in,
    createdAt: row.created_at,
    startAt: row.start_at,
    isUpcoming: new Date(row.start_at).getTime() > Date.now(),
  };
}

// GET /api/bookings — one user's tickets (My Tables). Defaults to the
// acting user; `?eventId=` returns a host's guest list for one event.
router.get('/bookings', async (req, res) => {
  const raw = req.query.userId;
  const userId =
    typeof raw === 'string' && raw.trim() !== '' ? raw.trim() : req.userId;
  const eventId =
    typeof req.query.eventId === 'string' && req.query.eventId.trim() !== ''
      ? req.query.eventId.trim()
      : null;

  if (eventId !== null) {
    const [event] = await query<{ host_id: string }>(
      'SELECT host_id FROM dinner_events WHERE id = $1::UUID',
      [eventId],
    );
    if (!event) throw notFound('Event');
    if (event.host_id !== req.userId) {
      throw forbidden('Only the host can see this guest list');
    }
    const guests = await query<BookingRow>(
      `${BOOKING_SELECT} WHERE b.event_id = $1::UUID ORDER BY b.created_at ASC`,
      [eventId],
    );
    res.json({ bookings: guests.map(serialize), count: guests.length });
    return;
  }

  const [guest] = await query<{ id: string }>(
    'SELECT id FROM users WHERE id = $1::UUID',
    [userId],
  );
  if (!guest) throw notFound('Guest');

  const rows = await query<BookingRow>(
    `${BOOKING_SELECT} WHERE b.user_id = $1::UUID ORDER BY e.start_at ASC`,
    [userId],
  );
  const all = rows.map(serialize);
  res.json({
    bookings: all,
    upcoming: all.filter((b) => b.isUpcoming && b.status !== 'cancelled'),
    past: all.filter((b) => !b.isUpcoming),
    cancelled: all.filter((b) => b.status === 'cancelled'),
    count: all.length,
  });
});

const createBookingSchema = z.object({
  seats: z.coerce.number().int().min(1).max(10).default(1),
  paymentLabel: z.string().trim().min(1).max(40).default('Visa •••• 4242'),
});

type EventLockRow = {
  id: string;
  title: string;
  start_at: Date;
  seats_total: number;
  seats_booked: number;
  price_per_seat: string;
  audience: string;
  host_id: string;
  attendee_ids: string[];
};

// POST /api/events/:id/bookings — join & pay. The event row is locked with
// FOR UPDATE inside a single transaction so two guests can never oversell
// the last seat.
router.post('/events/:id/bookings', async (req, res) => {
  const input = createBookingSchema.parse(req.body ?? {});
  const eventId = req.params.id;
  const userId = req.userId;

  const [guest] = await query<{ id: string }>(
    'SELECT id FROM users WHERE id = $1::UUID',
    [userId],
  );
  if (!guest) throw new ApiError(422, `Unknown guest ${userId}`);

  const result = await withTransaction(async (client) => {
    const { rows } = await client.query<EventLockRow>(
      `SELECT id, title, start_at, seats_total, seats_booked, price_per_seat,
              audience, host_id, attendee_ids
       FROM dinner_events WHERE id = $1::UUID FOR UPDATE`,
      [eventId],
    );
    const event = rows[0];
    if (!event) throw notFound('Event');

    if (event.audience === 'followers' && event.host_id !== userId) {
      const { rows: followsHost } = await client.query(
        'SELECT 1 FROM follows WHERE follower_id = $1 AND followee_id = $2',
        [userId, event.host_id],
      );
      if (followsHost.length === 0) {
        throw forbidden("This event is only for the host's followers");
      }
    }
    if (
      event.audience === 'inviteOnly' &&
      event.host_id !== userId &&
      !event.attendee_ids.includes(userId)
    ) {
      throw forbidden('This event is invite-only');
    }

    if (new Date(event.start_at).getTime() <= Date.now()) {
      throw new ApiError(409, 'This event has already started');
    }
    const seatsLeft = event.seats_total - event.seats_booked;
    if (seatsLeft < input.seats) {
      throw new ApiError(
        409,
        seatsLeft === 0
          ? 'This event is sold out'
          : `Only ${seatsLeft} seat(s) left`,
      );
    }

    const { rows: duplicates } = await client.query(
      `SELECT id FROM bookings
       WHERE event_id = $1 AND user_id = $2 AND status = 'confirmed'`,
      [eventId, userId],
    );
    if (duplicates.length > 0) {
      throw new ApiError(
        409,
        'You already hold a confirmed booking at this event',
      );
    }

    const totalAmount = input.seats * Number(event.price_per_seat);
    const { rows: insertedRows } = await client.query<{
      id: string; event_id: string; user_id: string; seats: number;
      price_per_seat: string; total_amount: string; reference: string;
      payment_label: string; status: string; created_at: Date;
    }>(
      `INSERT INTO bookings (event_id, user_id, seats, price_per_seat,
                             total_amount, reference, payment_label, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'confirmed')
       RETURNING id, event_id, user_id, seats, price_per_seat, total_amount,
                 reference, payment_label, status, created_at`,
      [
        eventId,
        userId,
        input.seats,
        event.price_per_seat,
        totalAmount,
        makeReference(),
        input.paymentLabel,
      ],
    );
    const booking = insertedRows[0];
    if (!booking) throw new ApiError(500, 'Booking insert failed');

    const { rows: updated } = await client.query<{ seats_booked: number }>(
      `UPDATE dinner_events
         SET seats_booked = seats_booked + $2,
             attendee_ids = CASE WHEN $3 = ANY(attendee_ids)
                                 THEN attendee_ids
                                 ELSE array_append(attendee_ids, $3) END
       WHERE id = $1::UUID
       RETURNING seats_booked`,
      [eventId, input.seats, userId],
    );

    // Tell the host someone joined (actor_id = host so it appears in their feed).
    if (event.host_id && event.host_id !== userId) {
      await client.query(
        `INSERT INTO activity (actor_id, kind, title, body, event_id, amount, is_unread)
         VALUES ($1, 'newGuest', $2, $3, $4, $5, true)`,
        [
          event.host_id,
          input.seats === 1
            ? 'A new guest joined your event'
            : `${input.seats} new guests joined your event`,
          `${event.title} just sold ${input.seats} more ${input.seats === 1 ? 'seat' : 'seats'}.`,
          eventId,
          input.seats * Number(event.price_per_seat),
        ],
      );
    }

    return {
      booking,
      seatsBooked: updated[0]?.seats_booked ?? event.seats_booked + input.seats,
      seatsTotal: event.seats_total,
    };
  });

  const pricePerSeat = Number(result.booking.price_per_seat);
  res.status(201).json({
    booking: {
      id: result.booking.id,
      eventId: result.booking.event_id,
      userId: result.booking.user_id,
      seats: result.booking.seats,
      pricePerSeat,
      total: Number(result.booking.total_amount),
      reference: result.booking.reference,
      paymentLabel: result.booking.payment_label,
      status: result.booking.status,
      createdAt: result.booking.created_at,
    },
    event: {
      id: eventId,
      seatsBooked: result.seatsBooked,
      seatsTotal: result.seatsTotal,
      seatsLeft: result.seatsTotal - result.seatsBooked,
    },
  });
});

type CancelRow = {
  id: string;
  event_id: string;
  user_id: string;
  seats: number;
  price_per_seat: string;
  total_amount: string;
  payment_label: string;
  status: string;
};

// POST /api/bookings/:id/cancel — refund the guest and release the seats.
router.post('/bookings/:id/cancel', async (req, res) => {
  const bookingId = req.params.id;

  const result = await withTransaction(async (client) => {
    const { rows } = await client.query<CancelRow>(
      `SELECT b.id, b.event_id, b.user_id, b.seats, b.price_per_seat,
              b.total_amount, b.payment_label, b.status
       FROM bookings b
       WHERE b.id = $1::UUID
       FOR UPDATE OF b`,
      [bookingId],
    );
    const booking = rows[0];
    if (!booking) throw notFound('Booking');
    if (booking.user_id !== req.userId) {
      throw new ApiError(403, 'This booking belongs to another guest');
    }
    if (booking.status === 'cancelled') {
      throw new ApiError(409, 'This booking is already cancelled');
    }
    if (booking.status === 'completed') {
      throw new ApiError(409, 'Completed bookings cannot be cancelled');
    }

    const { rows: cancelledRows } = await client.query<CancelRow>(
      `UPDATE bookings SET status = 'cancelled', checked_in = false
       WHERE id = $1::UUID
       RETURNING id, event_id, user_id, seats, price_per_seat, total_amount,
                 payment_label, status`,
      [bookingId],
    );
    const cancelled = cancelledRows[0];
    if (!cancelled) throw new ApiError(500, 'Cancel failed');

    const { rows: released } = await client.query<{ seats_booked: number }>(
      `UPDATE dinner_events
         SET seats_booked = GREATEST(0, seats_booked - $2)
       WHERE id = $1::UUID
       RETURNING seats_booked`,
      [cancelled.event_id, cancelled.seats],
    );

    return {
      cancelled,
      refund: {
        amount: Number(cancelled.total_amount),
        seats: cancelled.seats,
        method: cancelled.payment_label,
      },
      seatsBooked: released[0]?.seats_booked ?? 0,
    };
  });

  res.json({
    booking: {
      id: result.cancelled.id,
      eventId: result.cancelled.event_id,
      userId: result.cancelled.user_id,
      seats: result.cancelled.seats,
      status: result.cancelled.status,
    },
    refund: result.refund,
    event: {
      id: result.cancelled.event_id,
      seatsBooked: result.seatsBooked,
    },
  });
});

// POST /api/bookings/:id/checkin — mark a ticket used.
router.post('/bookings/:id/checkin', async (req, res) => {
  const bookingId = req.params.id;

  const [row] = await query<{
    id: string; event_id: string; user_id: string; host_id: string;
    status: string; checked_in: boolean; seats: number;
  }>(
    `SELECT b.id, b.event_id, b.user_id, b.status, b.checked_in, b.seats,
            e.host_id
     FROM bookings b JOIN dinner_events e ON e.id = b.event_id
     WHERE b.id = $1::UUID`,
    [bookingId],
  );
  if (!row) throw notFound('Booking');
  if (row.user_id !== req.userId && row.host_id !== req.userId) {
    throw forbidden('Only the guest or the host can check in');
  }
  if (row.status === 'cancelled') {
    throw new ApiError(409, 'Cancelled bookings cannot be checked in');
  }
  if (row.checked_in) {
    throw new ApiError(409, 'Already checked in');
  }

  await query(
    'UPDATE bookings SET checked_in = true, checked_in_at = now() WHERE id = $1::UUID',
    [bookingId],
  );

  res.json({
    booking: {
      id: row.id,
      eventId: row.event_id,
      userId: row.user_id,
      seats: row.seats,
      checkedIn: true,
    },
  });
});

export default router;

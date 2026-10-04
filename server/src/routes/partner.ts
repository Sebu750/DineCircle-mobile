import { Router } from 'express';
import { z } from 'zod';
import { query } from '../db.js';
import { ApiError, notFound, requireRole } from '../context.js';

const router = Router();

// All partner routes require partner_admin or super_admin role.
router.use(requireRole('partner_admin', 'super_admin'));

// ── Restaurants ──────────────────────────────────────────────────────────────

// GET /api/partner/restaurants — the partner admin's restaurants.
router.get('/restaurants', async (req, res) => {
  const rows = await query<{
    id: string; name: string; tagline: string; city: string;
    rating: string; review_count: number; seats: number;
    accepting_bookings: boolean; cover_image: string;
    profile_completion: number;
  }>(
    `SELECT id, name, tagline, city, rating, review_count, seats,
            accepting_bookings, cover_image, profile_completion
     FROM restaurants
     WHERE owner_id = $1
     ORDER BY name ASC`,
    [req.userId],
  );

  res.json({
    restaurants: rows.map((r) => ({
      id: r.id,
      name: r.name,
      tagline: r.tagline,
      city: r.city,
      rating: Number(r.rating),
      reviewCount: r.review_count,
      seats: r.seats,
      acceptingBookings: r.accepting_bookings,
      coverImage: r.cover_image,
      profileCompletion: r.profile_completion,
    })),
    count: rows.length,
  });
});

// GET /api/partner/restaurants/:id — detailed restaurant profile for the partner.
router.get('/restaurants/:id', async (req, res) => {
  const [restaurant] = await query<{
    id: string; name: string; tagline: string; about: string;
    cuisines: string[]; address: string; neighborhood: string; city: string;
    phone: string; email: string; website: string; instagram: string;
    price_range: string; rating: string; review_count: number;
    seats: number; tables_count: number; since: string; owner_name: string;
    amenities: string[]; opening_hours: object; profile_completion: number;
    accepting_bookings: boolean; dine_circle_plus: boolean;
    cover_image: string; gallery: string[]; tags: string[];
    partner_perk: string | null;
  }>(
    `SELECT * FROM restaurants WHERE id = $1::UUID AND owner_id = $2`,
    [req.params.id, req.userId],
  );
  if (!restaurant) throw notFound('Restaurant');

  res.json({ restaurant });
});

// ── Events ───────────────────────────────────────────────────────────────────

const createPartnerEventSchema = z.object({
  restaurantId: z.string().uuid(),
  title: z.string().trim().min(3).max(120),
  tagline: z.string().trim().max(200).default(''),
  description: z.string().trim().max(4000).default(''),
  startAt: z.coerce.date(),
  endAt: z.coerce.date(),
  seatsTotal: z.number().int().min(1).max(200),
  pricePerSeat: z.number().positive().max(10000),
  type: z.enum(['dinner', 'tasting', 'supperClub', 'brunch', 'workshop', 'festival']).default('dinner'),
  audience: z.enum(['public', 'followers', 'friends', 'inviteOnly']).default('public'),
  menuStyle: z.enum(['setMenu', 'tastingMenu', 'familyStyle', 'sharing', 'buffet']).default('setMenu'),
  coverImage: z.string().default(''),
  tags: z.array(z.string()).default([]),
});

// POST /api/partner/events — create a new event for a partner restaurant.
router.post('/events', async (req, res) => {
  const input = createPartnerEventSchema.parse(req.body);

  // Verify the restaurant belongs to this partner
  const [restaurant] = await query<{ id: string }>(
    'SELECT id FROM restaurants WHERE id = $1::UUID AND owner_id = $2',
    [input.restaurantId, req.userId],
  );
  if (!restaurant) throw new ApiError(404, 'Restaurant not found');

  const durationMinutes = Math.round(
    (input.endAt.getTime() - input.startAt.getTime()) / 60000,
  );

  const [created] = await query<{
    id: string; title: string; restaurant_id: string; status: string;
    start_at: Date; seats_total: number; seats_booked: number;
    price_per_seat: string;
  }>(
    `INSERT INTO dinner_events (
       restaurant_id, title, tagline, description, start_at, end_at,
       duration_minutes, seats_total, seats_booked, price_per_seat,
       type, audience, status, menu_style, cover_image, tags
     ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,0,$9,$10,$11,'requested',$12,$13,$14)
     RETURNING id, title, restaurant_id, status, start_at, seats_total, seats_booked, price_per_seat`,
    [
      input.restaurantId, input.title, input.tagline, input.description,
      input.startAt, input.endAt, durationMinutes, input.seatsTotal,
      input.pricePerSeat, input.type, input.audience, input.menuStyle,
      input.coverImage, input.tags,
    ],
  );

  if (!created) throw new ApiError(500, 'Event creation failed');

  res.status(201).json({
    event: {
      id: created.id,
      title: created.title,
      restaurantId: created.restaurant_id,
      status: created.status,
      startAt: created.start_at,
      seatsTotal: created.seats_total,
      seatsBooked: created.seats_booked,
      pricePerSeat: Number(created.price_per_seat),
    },
  });
});

// PUT /api/partner/events/:id — update an event (partner who owns the restaurant).
router.put('/events/:id', async (req, res) => {
  const updateSchema = createPartnerEventSchema.extend({ status: z.enum(["draft","requested","confirmed","live","completed","declined","cancelled"]).optional() }).partial();
  const input = updateSchema.parse(req.body);
  const eventId = req.params.id;

  // Verify ownership through restaurant
  const [event] = await query<{ id: string; restaurant_id: string }>(
    `SELECT e.id, e.restaurant_id FROM dinner_events e
     JOIN restaurants r ON r.id = e.restaurant_id
     WHERE e.id = $1::UUID AND r.owner_id = $2`,
    [eventId, req.userId],
  );
  if (!event) throw notFound('Event');

  const sets: string[] = [];
  const params: unknown[] = [];
  let idx = 1;

  if (input.title !== undefined) { sets.push(`title = $${idx++}`); params.push(input.title); }
  if (input.tagline !== undefined) { sets.push(`tagline = $${idx++}`); params.push(input.tagline); }
  if (input.description !== undefined) { sets.push(`description = $${idx++}`); params.push(input.description); }
  if (input.startAt !== undefined) { sets.push(`start_at = $${idx++}`); params.push(input.startAt); }
  if (input.seatsTotal !== undefined) { sets.push(`seats_total = $${idx++}`); params.push(input.seatsTotal); }
  if (input.pricePerSeat !== undefined) { sets.push(`price_per_seat = $${idx++}`); params.push(input.pricePerSeat); }
  if (input.type !== undefined) { sets.push(`type = $${idx++}`); params.push(input.type); }
  if (input.status !== undefined) { sets.push(`status = $${idx++}`); params.push(input.status); }
  if (input.coverImage !== undefined) { sets.push(`cover_image = $${idx++}`); params.push(input.coverImage); }
  if (input.tags !== undefined) { sets.push(`tags = $${idx++}`); params.push(input.tags); }

  if (sets.length === 0) {
    res.json({ updated: false });
    return;
  }

  params.push(eventId);
  const [updated] = await query<{ id: string; title: string; status: string }>(
    `UPDATE dinner_events SET ${sets.join(', ')} WHERE id = $${idx}
     RETURNING id, title, status`,
    params,
  );

  res.json({ updated: true, event: updated });
});

// GET /api/partner/events — all events for the partner's restaurants.
router.get('/events', async (req, res) => {
  const { status, limit = '50' } = req.query;
  const conditions: string[] = ['r.owner_id = $1'];
  const params: unknown[] = [req.userId];

  if (typeof status === 'string' && status !== '') {
    params.push(status);
    conditions.push(`e.status = $${params.length}`);
  }

  const where = conditions.join(' AND ');
  const parsedLimit = Math.min(Number(limit) || 50, 200);

  const rows = await query<{
    id: string; title: string; restaurant_name: string; start_at: Date;
    seats_total: number; seats_booked: number; price_per_seat: string;
    status: string; type: string;
  }>(
    `SELECT e.id, e.title, r.name AS restaurant_name, e.start_at,
            e.seats_total, e.seats_booked, e.price_per_seat, e.status, e.type
     FROM dinner_events e
     JOIN restaurants r ON r.id = e.restaurant_id
     WHERE ${where}
     ORDER BY e.start_at DESC
     LIMIT ${parsedLimit}`,
    params,
  );

  res.json({
    events: rows.map((e) => ({
      id: e.id,
      title: e.title,
      restaurantName: e.restaurant_name,
      startAt: e.start_at,
      seatsTotal: e.seats_total,
      seatsBooked: e.seats_booked,
      seatsLeft: Math.max(0, e.seats_total - e.seats_booked),
      pricePerSeat: Number(e.price_per_seat),
      status: e.status,
      type: e.type,
    })),
    count: rows.length,
  });
});

// ── Bookings for partner events ──────────────────────────────────────────────

// GET /api/partner/bookings — all bookings for the partner's events.
router.get('/bookings', async (req, res) => {
  const { eventId, status, limit = '100' } = req.query;
  const conditions: string[] = ['r.owner_id = $1'];
  const params: unknown[] = [req.userId];

  if (typeof eventId === 'string' && eventId !== '') {
    params.push(eventId);
    conditions.push(`e.id = $${params.length}`);
  }
  if (typeof status === 'string' && status !== '') {
    params.push(status);
    conditions.push(`b.status = $${params.length}`);
  }

  const where = conditions.join(' AND ');
  const parsedLimit = Math.min(Number(limit) || 100, 500);

  const rows = await query<{
    id: string; event_id: string; event_title: string; user_id: string;
    user_name: string; seats: number; total_amount: string;
    status: string; payment_status: string; reference: string;
    checked_in: boolean; created_at: Date;
  }>(
    `SELECT b.id, b.event_id, e.title AS event_title,
            b.user_id, u.name AS user_name,
            b.seats, b.total_amount, b.status, b.payment_status,
            b.reference, b.checked_in, b.created_at
     FROM bookings b
     JOIN dinner_events e ON e.id = b.event_id
     JOIN restaurants r ON r.id = e.restaurant_id
     JOIN users u ON u.id = b.user_id
     WHERE ${where}
     ORDER BY b.created_at DESC
     LIMIT ${parsedLimit}`,
    params,
  );

  res.json({
    bookings: rows.map((b) => ({
      id: b.id,
      eventId: b.event_id,
      eventTitle: b.event_title,
      userId: b.user_id,
      userName: b.user_name,
      seats: b.seats,
      totalAmount: Number(b.total_amount),
      status: b.status,
      paymentStatus: b.payment_status,
      reference: b.reference,
      checkedIn: b.checked_in,
      createdAt: b.created_at,
    })),
    count: rows.length,
  });
});

// POST /api/partner/bookings/:id/checkin — check in a guest.
router.post('/bookings/:id/checkin', async (req, res) => {
  const bookingId = req.params.id;

  // Verify the booking belongs to one of the partner's events
  const [booking] = await query<{
    id: string; event_id: string; user_id: string; seats: number;
    status: string; checked_in: boolean;
  }>(
    `SELECT b.id, b.event_id, b.user_id, b.seats, b.status, b.checked_in
     FROM bookings b
     JOIN dinner_events e ON e.id = b.event_id
     JOIN restaurants r ON r.id = e.restaurant_id
     WHERE b.id = $1::UUID AND r.owner_id = $2`,
    [bookingId, req.userId],
  );
  if (!booking) throw notFound('Booking');
  if (booking.status === 'cancelled') {
    throw new ApiError(409, 'Cancelled bookings cannot be checked in');
  }
  if (booking.checked_in) {
    throw new ApiError(409, 'Already checked in');
  }

  await query(
    'UPDATE bookings SET checked_in = true, checked_in_at = now() WHERE id = $1::UUID',
    [bookingId],
  );

  res.json({
    booking: {
      id: booking.id,
      eventId: booking.event_id,
      userId: booking.user_id,
      seats: booking.seats,
      checkedIn: true,
    },
  });
});

// ── Special Menus ────────────────────────────────────────────────────────────

const createMenuSchema = z.object({
  restaurantId: z.string().uuid(),
  name: z.string().trim().min(2).max(120),
  description: z.string().trim().max(2000).default(''),
  pricePerGuest: z.number().positive().max(10000),
  minGuests: z.number().int().min(1).default(2),
  tags: z.array(z.string()).default([]),
  coverImage: z.string().default(''),
});

// POST /api/partner/menus — create a special menu.
router.post('/menus', async (req, res) => {
  const input = createMenuSchema.parse(req.body);

  const [restaurant] = await query<{ id: string }>(
    'SELECT id FROM restaurants WHERE id = $1::UUID AND owner_id = $2',
    [input.restaurantId, req.userId],
  );
  if (!restaurant) throw new ApiError(404, 'Restaurant not found');

  const [created] = await query<{
    id: string; name: string; restaurant_id: string; status: string;
    price_per_guest: string;
  }>(
    `INSERT INTO special_menus (restaurant_id, name, description, price_per_guest, min_guests, tags, cover_image)
     VALUES ($1,$2,$3,$4,$5,$6,$7)
     RETURNING id, name, restaurant_id, status, price_per_guest`,
    [input.restaurantId, input.name, input.description, input.pricePerGuest, input.minGuests, input.tags, input.coverImage],
  );

  if (!created) throw new ApiError(500, 'Menu creation failed');

  res.status(201).json({
    menu: {
      id: created.id,
      name: created.name,
      restaurantId: created.restaurant_id,
      status: created.status,
      pricePerGuest: Number(created.price_per_guest),
    },
  });
});

// GET /api/partner/menus — special menus for the partner's restaurants.
router.get('/menus', async (req, res) => {
  const rows = await query<{
    id: string; restaurant_id: string; restaurant_name: string;
    name: string; description: string; status: string;
    price_per_guest: string; min_guests: number; tags: string[];
    views_this_week: number; bookings_count: number;
  }>(
    `SELECT sm.id, sm.restaurant_id, r.name AS restaurant_name,
            sm.name, sm.description, sm.status, sm.price_per_guest,
            sm.min_guests, sm.tags, sm.views_this_week, sm.bookings_count
     FROM special_menus sm
     JOIN restaurants r ON r.id = sm.restaurant_id
     WHERE r.owner_id = $1::UUID
     ORDER BY sm.created_at DESC`,
    [req.userId],
  );

  res.json({
    menus: rows.map((m) => ({
      id: m.id,
      restaurantId: m.restaurant_id,
      restaurantName: m.restaurant_name,
      name: m.name,
      description: m.description,
      status: m.status,
      pricePerGuest: Number(m.price_per_guest),
      minGuests: m.min_guests,
      tags: m.tags,
      viewsThisWeek: m.views_this_week,
      bookingsCount: m.bookings_count,
    })),
    count: rows.length,
  });
});

// ── Analytics ────────────────────────────────────────────────────────────────

// GET /api/partner/analytics — business insights for the partner dashboard.
router.get('/analytics', async (req, res) => {
  // Revenue summary across all partner restaurants
  const [revenue] = await query<{
    total_revenue: string;
    total_bookings: number;
    total_events: number;
    avg_price_per_seat: string;
    total_covers: number;
  }>(
    `SELECT
       COALESCE(SUM(b.total_amount), 0)::text AS total_revenue,
       COUNT(b.id)::int AS total_bookings,
       COUNT(DISTINCT e.id)::int AS total_events,
       COALESCE(AVG(b.price_per_seat), 0)::text AS avg_price_per_seat,
       COALESCE(SUM(b.seats), 0)::int AS total_covers
     FROM bookings b
     JOIN dinner_events e ON e.id = b.event_id
     JOIN restaurants r ON r.id = e.restaurant_id
     WHERE r.owner_id = $1::UUID
       AND b.status <> 'cancelled'`,
    [req.userId],
  );

  // Upcoming events count
  const [upcoming] = await query<{ count: number }>(
    `SELECT COUNT(*)::int AS count
     FROM dinner_events e
     JOIN restaurants r ON r.id = e.restaurant_id
     WHERE r.owner_id = $1::UUID
       AND e.start_at >= now()
       AND e.status IN ('confirmed', 'live', 'requested')`,
    [req.userId],
  );

  // Average fill rate
  const [fillRate] = await query<{ avg_fill: number }>(
    `SELECT COALESCE(AVG(e.seats_booked::numeric / GREATEST(e.seats_total, 1)), 0)::float8 AS avg_fill
     FROM dinner_events e
     JOIN restaurants r ON r.id = e.restaurant_id
     WHERE r.owner_id = $1::UUID
       AND e.start_at < now()`,
    [req.userId],
  );

  // Recent bookings (last 10)
  const recentBookings = await query<{
    id: string; event_title: string; user_name: string;
    seats: number; total_amount: string; status: string; created_at: Date;
  }>(
    `SELECT b.id, e.title AS event_title, u.name AS user_name,
            b.seats, b.total_amount, b.status, b.created_at
     FROM bookings b
     JOIN dinner_events e ON e.id = b.event_id
     JOIN restaurants r ON r.id = e.restaurant_id
     JOIN users u ON u.id = b.user_id
     WHERE r.owner_id = $1::UUID
     ORDER BY b.created_at DESC
     LIMIT 10`,
    [req.userId],
  );

  res.json({
    analytics: {
      totalRevenue: Number(revenue?.total_revenue ?? 0),
      totalBookings: revenue?.total_bookings ?? 0,
      totalEvents: revenue?.total_events ?? 0,
      avgPricePerSeat: Number(revenue?.avg_price_per_seat ?? 0),
      totalCovers: revenue?.total_covers ?? 0,
      upcomingEvents: upcoming?.count ?? 0,
      avgFillRate: fillRate?.avg_fill ?? 0,
    },
    recentBookings: recentBookings.map((b) => ({
      id: b.id,
      eventTitle: b.event_title,
      userName: b.user_name,
      seats: b.seats,
      totalAmount: Number(b.total_amount),
      status: b.status,
      createdAt: b.created_at,
    })),
  });
});

// ── Notifications ────────────────────────────────────────────────────────────

// GET /api/partner/notifications — notifications for the partner's restaurants.
router.get('/notifications', async (req, res) => {
  const { unreadOnly, limit = '50' } = req.query;
  const conditions: string[] = ['n.restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = $1)'];
  const params: unknown[] = [req.userId];

  if (unreadOnly === 'true') {
    conditions.push('n.read = false');
  }

  const where = conditions.join(' AND ');
  const parsedLimit = Math.min(Number(limit) || 50, 200);

  const rows = await query<{
    id: string; restaurant_id: string; title: string; body: string;
    category: string; read: boolean; icon: string | null; tint: string | null;
    notification_time: Date;
  }>(
    `SELECT n.* FROM notifications n
     WHERE ${where}
     ORDER BY n.notification_time DESC
     LIMIT ${parsedLimit}`,
    params,
  );

  res.json({
    notifications: rows.map((n) => ({
      id: n.id,
      restaurantId: n.restaurant_id,
      title: n.title,
      body: n.body,
      category: n.category,
      read: n.read,
      icon: n.icon,
      tint: n.tint,
      notificationTime: n.notification_time,
    })),
    count: rows.length,
  });
});

export default router;

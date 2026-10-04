import { Router } from 'express';
import { z } from 'zod';
import { query, withTransaction } from '../db.js';
import { ApiError, notFound, forbidden } from '../context.js';

const router = Router();

/** Row shape shared by list and detail queries. */
type EventRow = {
  id: string;
  title: string;
  tagline: string;
  description: string;
  host_id: string;
  restaurant_id: string;
  cover_image: string;
  gallery: string[];
  start_at: Date;
  duration_minutes: number;
  seats_total: number;
  seats_booked: number;
  price_per_seat: string;
  type: string;
  audience: string;
  menu_style: string;
  included: string[];
  tags: string[];
  is_featured: boolean;
  host_note: string;
  language: string;
  dress_code: string;
  cancellation: string;
  attendee_ids: string[];
  host_name: string | null;
  host_handle: string | null;
  host_avatar: string | null;
  restaurant_name: string | null;
  restaurant_neighborhood: string | null;
};

const EVENT_SELECT = `
  SELECT e.*, u.name AS host_name, u.handle AS host_handle, u.avatar_url AS host_avatar,
         r.name AS restaurant_name, r.neighborhood AS restaurant_neighborhood
  FROM dinner_events e
  LEFT JOIN users u ON u.id = e.host_id
  LEFT JOIN restaurants r ON r.id = e.restaurant_id`;

function serialize(row: EventRow) {
  const seatsLeft = Math.max(0, row.seats_total - row.seats_booked);
  return {
    id: row.id,
    title: row.title,
    tagline: row.tagline,
    description: row.description,
    hostId: row.host_id,
    host: row.host_name === null ? null : {
      id: row.host_id,
      name: row.host_name,
      handle: row.host_handle,
      avatarUrl: row.host_avatar,
    },
    restaurantId: row.restaurant_id,
    restaurant: row.restaurant_name === null ? null : {
      id: row.restaurant_id,
      name: row.restaurant_name,
      neighborhood: row.restaurant_neighborhood,
    },
    coverImage: row.cover_image,
    gallery: row.gallery,
    startAt: row.start_at,
    durationMinutes: row.duration_minutes,
    seatsTotal: row.seats_total,
    seatsBooked: row.seats_booked,
    seatsLeft,
    isSoldOut: seatsLeft <= 0,
    pricePerSeat: Number(row.price_per_seat),
    type: row.type,
    audience: row.audience,
    menuStyle: row.menu_style,
    included: row.included,
    tags: row.tags,
    isFeatured: row.is_featured,
    hostNote: row.host_note,
    language: row.language,
    dressCode: row.dress_code,
    cancellation: row.cancellation,
    attendeeIds: row.attendee_ids,
  };
}

/**
 * Visibility rule: public and friends tables are open; follower tables need
 * a follow; invite-only tables need a seat. Hosts and booked guests always
 * see their own tables.
 */
const AUDIENCE_GATE = `(e.audience IN ('public','friends')
     OR e.host_id = $VIEWER_UUID
     OR (e.audience = 'followers' AND EXISTS (
           SELECT 1 FROM follows f
           WHERE f.follower_id = $VIEWER_UUID AND f.followee_id = e.host_id))
     OR (e.audience = 'inviteOnly' AND $VIEWER = ANY(e.attendee_ids))
     OR EXISTS (
           SELECT 1 FROM bookings b
           WHERE b.event_id = e.id AND b.user_id = $VIEWER_UUID
             AND b.status <> 'cancelled'))`;

// GET /api/events — filterable feed of events the viewer may see.
router.get('/', async (req, res) => {
  const {
    type, audience, featured, hostId, venueId, upcoming, q,
    limit = '50', offset = '0',
  } = req.query;

  const conditions: string[] = [];
  const params: unknown[] = [req.userId, req.userId]; // $1 = text (attendee_ids), $2 = UUID
  conditions.push(
    AUDIENCE_GATE.replaceAll('$VIEWER_UUID', '$2').replaceAll('$VIEWER', '$1'),
  );

  const add = (sqlFragment: string, value: unknown) => {
    params.push(value);
    conditions.push(sqlFragment.replace('?', `$${params.length}`));
  };

  if (typeof type === 'string' && type !== '') {
    add('e.type = ?', type);
  }
  if (typeof audience === 'string' && audience !== '') {
    add('e.audience = ?', audience);
  }
  if (featured === 'true') conditions.push('e.is_featured');
  if (typeof hostId === 'string' && hostId !== '') add('e.host_id = ?::UUID', hostId);
  if (typeof venueId === 'string' && venueId !== '') {
    add('e.restaurant_id = ?::UUID', venueId);
  }
  if (upcoming === 'false') {
    conditions.push('e.start_at < now()');
  } else if (upcoming !== 'all') {
    conditions.push('e.start_at >= now()');
  }
  if (typeof q === 'string' && q.trim() !== '') {
    params.push(`%${q.trim().toLowerCase()}%`);
    const i = params.length;
    conditions.push(
      `(lower(e.title) LIKE $${i} OR lower(e.tagline) LIKE $${i} OR EXISTS (
         SELECT 1 FROM unnest(e.tags) tag WHERE lower(tag) LIKE $${i}))`,
    );
  }

  const where = conditions.length === 0 ? '' : `WHERE ${conditions.join(' AND ')}`;
  const parsedLimit = Math.min(Number(limit) || 50, 200);
  const parsedOffset = Math.max(Number(offset) || 0, 0);

  const rows = await query<EventRow>(
    `${EVENT_SELECT} ${where} ORDER BY e.start_at ASC LIMIT ${parsedLimit} OFFSET ${parsedOffset}`,
    params,
  );
  res.json({ events: rows.map(serialize), count: rows.length });
});

// GET /api/events/:id — one visible event with menu, host and venue.
router.get('/:id', async (req, res) => {
  const [event] = await query<EventRow>(
    `${EVENT_SELECT}
     WHERE e.id = $1::UUID AND ${AUDIENCE_GATE.replaceAll('$VIEWER_UUID', '$3').replaceAll('$VIEWER', '$2')}`,
    [req.params.id, req.userId, req.userId],
  );
  if (!event) throw notFound('Event');

  const menu = await query<{
    id: string; position: number; name: string;
    description: string; pairing: string | null; signature: boolean;
  }>(
    `SELECT id, position, name, description, pairing, signature
     FROM menu_items WHERE event_id = $1 ORDER BY position ASC`,
    [req.params.id],
  );

  const [venue] = await query<{
    id: string; name: string; cuisines: string[]; neighborhood: string;
    address: string; rating: string; review_count: number; price_range: string;
    cover_image: string; gallery: string[];
    about: string; tags: string[]; is_partner: boolean;
    partner_perk: string | null; opening_hours: object; seats: number;
  }>(
    `SELECT * FROM restaurants WHERE id = $1`,
    [event.restaurant_id],
  );

  const attendees = await query<{
    id: string; name: string; handle: string; avatar_url: string | null;
  }>(
    `SELECT id, name, handle, avatar_url FROM users
     WHERE id = ANY($1::text[])`,
    [event.attendee_ids],
  );

  res.json({
    event: {
      ...serialize(event),
      menu: menu.map((m) => ({
        id: m.id,
        position: m.position,
        name: m.name,
        description: m.description,
        pairing: m.pairing,
        isSignature: m.signature,
      })),
      venue: venue === undefined ? null : {
        id: venue.id,
        name: venue.name,
        cuisines: venue.cuisines,
        neighborhood: venue.neighborhood,
        address: venue.address,
        rating: Number(venue.rating),
        reviewCount: venue.review_count,
        priceRange: venue.price_range,
        coverImage: venue.cover_image,
        gallery: venue.gallery,
        about: venue.about,
        tags: venue.tags,
        isPartner: venue.is_partner,
        partnerPerk: venue.partner_perk,
        openingHours: venue.opening_hours,
      },
      attendees: attendees.map((a) => ({
        id: a.id, name: a.name, handle: a.handle, avatarUrl: a.avatar_url,
      })),
    },
  });
});

const createEventSchema = z.object({
  title: z.string().trim().min(3).max(120),
  tagline: z.string().trim().max(200).default(''),
  description: z.string().trim().max(4000).default(''),
  restaurantId: z.string().min(1),
  hostId: z.string().min(1).optional(),
  coverImage: z.string().min(1),
  gallery: z.array(z.string()).default([]),
  startAt: z.coerce.date(),
  durationMinutes: z.number().int().min(30).max(600).default(150),
  seatsTotal: z.number().int().min(1).max(100),
  pricePerSeat: z.number().positive().max(10000),
  type: z.enum(['dinner', 'tasting', 'supperClub', 'brunch', 'workshop', 'festival']).default('dinner'),
  audience: z.enum(['public', 'followers', 'friends', 'inviteOnly']).default('public'),
  menuStyle: z.enum(['setMenu', 'tastingMenu', 'familyStyle', 'sharing', 'buffet']).default('familyStyle'),
  included: z.array(z.string()).default([]),
  tags: z.array(z.string()).default([]),
  isFeatured: z.boolean().default(false),
  hostNote: z.string().trim().max(1000).default(''),
  menu: z.array(z.object({
    name: z.string().trim().min(1).max(120),
    description: z.string().trim().max(400).default(''),
    pairing: z.string().trim().max(120).optional(),
    isSignature: z.boolean().default(false),
  })).default([]),
});

// POST /api/events — publish a new event (hosts and partner admins only).
router.post('/', async (req, res) => {
  // Only hosts, partner admins, or super admins can create events
  const canCreate = ['host', 'partner_admin', 'super_admin'].includes(req.userRole);
  if (!canCreate) throw new ApiError(403, 'Only hosts or partners can create events');

  const input = createEventSchema.parse(req.body);
  // Force hostId to the caller — prevent impersonation
  const hostId = req.userId;

  const [venue] = await query<{ id: string; owner_id: string }>(
    'SELECT id, owner_id FROM restaurants WHERE id = $1::UUID', [input.restaurantId],
  );
  if (!venue) throw new ApiError(422, `Unknown restaurant ${input.restaurantId}`);

  // Hosts can only create events at restaurants they own
  if (req.userRole === 'host' && venue.owner_id !== req.userId) {
    throw new ApiError(403, 'You do not own this restaurant');
  }

  const gallery = input.gallery.length > 0 ? input.gallery : [input.coverImage];

  const [created] = await query<EventRow>(
    `INSERT INTO dinner_events (title, tagline, description, host_id,
                                restaurant_id, cover_image, gallery, start_at,
                                duration_minutes, seats_total, seats_booked,
                                price_per_seat, type, audience, menu_style,
                                included, tags, is_featured, host_note)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19)
     RETURNING *`,
    [input.title, input.tagline, input.description, hostId,
     input.restaurantId, input.coverImage, gallery, input.startAt,
     input.durationMinutes, input.seatsTotal, 0,
     input.pricePerSeat, input.type, input.audience, input.menuStyle,
     input.included, input.tags, input.isFeatured, input.hostNote],
  );

  if (!created) throw new ApiError(500, 'Event creation failed');

  for (const [i, item] of input.menu.entries()) {
    await query(
      `INSERT INTO menu_items (event_id, position, name, description, pairing, signature)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [created.id, i, item.name, item.description, item.pairing ?? null, item.isSignature],
    );
  }

  // Re-fetch with JOINs for full serialization
  const [full] = await query<EventRow>(
    `${EVENT_SELECT} WHERE e.id = $1::UUID`, [created.id],
  );
  res.status(201).json({ event: serialize(full!) });
});

// DELETE /api/events/:id — the host cancels an event. Bookings vanish via
// cascade; every still-active guest gets an activity note about it.
router.delete('/:id', async (req, res) => {
  const eventId = req.params.id;

  await withTransaction(async (client) => {
    const { rows } = await client.query<{ host_id: string; title: string }>(
      'SELECT host_id, title FROM dinner_events WHERE id = $1 FOR UPDATE',
      [eventId],
    );
    const event = rows[0];
    if (!event) throw notFound('Event');
    if (event.host_id !== req.userId) {
      throw forbidden('Only the host can cancel this event');
    }

    const { rows: guests } = await client.query<{ user_id: string }>(
      `SELECT DISTINCT user_id FROM bookings
       WHERE event_id = $1 AND status <> 'cancelled'`,
      [eventId],
    );

    for (const guest of guests) {
      await client.query(
        `INSERT INTO activity (actor_id, kind, title, body, event_id, is_unread)
         VALUES ($1, 'reminder', $2, $3, $4, true)`,
        [
          guest.user_id,
          'An event you booked was cancelled',
          `${event.title} was cancelled by the host. Your payment will be refunded.`,
          eventId,
        ],
      );
    }

    await client.query('DELETE FROM dinner_events WHERE id = $1', [eventId]);
  });

  res.json({ deleted: true, eventId });
});

export default router;

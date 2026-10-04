import { Router } from 'express';
import { query } from '../db.js';
import { notFound } from '../context.js';

const router = Router();

type RestaurantRow = {
  id: string; name: string; cuisines: string[]; neighborhood: string; address: string;
  rating: string; review_count: number; price_range: string;
  cover_image: string; gallery: string[]; about: string; tags: string[];
  is_partner: boolean; partner_perk: string | null; opening_hours: object;
  seats: number; city: string;
};

function serialize(r: RestaurantRow) {
  return {
    id: r.id,
    name: r.name,
    cuisines: r.cuisines,
    neighborhood: r.neighborhood,
    address: r.address,
    city: r.city,
    rating: Number(r.rating),
    reviewCount: r.review_count,
    priceRange: r.price_range,
    coverImage: r.cover_image,
    gallery: r.gallery,
    about: r.about,
    tags: r.tags,
    isPartner: r.is_partner,
    partnerPerk: r.partner_perk,
    openingHours: r.opening_hours,
    seats: r.seats,
  };
}

// GET /api/restaurants — partner venues, filterable.
router.get('/', async (req, res) => {
  const { partner, q, limit = '50' } = req.query;
  const conditions: string[] = [];
  const params: unknown[] = [];

  if (partner === 'true') conditions.push('is_partner');
  if (typeof q === 'string' && q.trim() !== '') {
    params.push(`%${q.trim().toLowerCase()}%`);
    const i = params.length;
    conditions.push(
      `(lower(name) LIKE $${i} OR lower(neighborhood) LIKE $${i} OR lower(city) LIKE $${i})`,
    );
  }

  const where = conditions.length === 0 ? '' : `WHERE ${conditions.join(' AND ')}`;
  const parsedLimit = Math.min(Number(limit) || 50, 200);

  const rows = await query<RestaurantRow>(
    `SELECT * FROM restaurants ${where}
     ORDER BY is_partner DESC, rating DESC LIMIT ${parsedLimit}`,
    params,
  );
  res.json({ restaurants: rows.map(serialize), count: rows.length });
});

// GET /api/restaurants/:id — venue profile plus upcoming events.
router.get('/:id', async (req, res) => {
  const [venue] = await query<RestaurantRow>(
    'SELECT * FROM restaurants WHERE id = $1::UUID', [req.params.id],
  );
  if (!venue) throw notFound('Restaurant');

  const events = await query<{
    id: string; title: string; tagline: string; start_at: Date;
    seats_total: number; seats_booked: number; price_per_seat: string;
    type: string; cover_image: string; host_name: string | null;
  }>(
    `SELECT e.id, e.title, e.tagline, e.start_at, e.seats_total, e.seats_booked,
            e.price_per_seat, e.type, e.cover_image, u.name AS host_name
     FROM dinner_events e LEFT JOIN users u ON u.id = e.host_id
     WHERE e.restaurant_id = $1 AND e.start_at >= now()
     ORDER BY e.start_at ASC`,
    [req.params.id],
  );

  res.json({
    restaurant: serialize(venue),
    upcomingEvents: events.map((e) => ({
      id: e.id,
      title: e.title,
      tagline: e.tagline,
      startAt: e.start_at,
      seatsTotal: e.seats_total,
      seatsBooked: e.seats_booked,
      seatsLeft: Math.max(0, e.seats_total - e.seats_booked),
      pricePerSeat: Number(e.price_per_seat),
      type: e.type,
      coverImage: e.cover_image,
      hostName: e.host_name,
    })),
  });
});

export default router;

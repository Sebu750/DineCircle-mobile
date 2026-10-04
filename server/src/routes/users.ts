import { Router } from 'express';
import { z } from 'zod';
import { query } from '../db.js';
import { notFound } from '../context.js';

const router = Router();

type UserRow = {
  id: string;
  name: string;
  handle: string;
  city: string;
  bio: string;
  followers_count: number;
  following_count: number;
  dinners_hosted: number;
  dinners_joined: number;
  rating: string;
  review_count: number;
  avatar_url: string | null;
  badges: string[];
  tastes: string[];
  accent_hex: string | null;
  joined_year: number;
  role: string;
};

function serialize(u: UserRow) {
  return {
    id: u.id,
    name: u.name,
    handle: u.handle,
    city: u.city,
    bio: u.bio,
    followers: u.followers_count,
    following: u.following_count,
    dinnersHosted: u.dinners_hosted,
    dinnersJoined: u.dinners_joined,
    rating: Number(u.rating),
    reviewCount: u.review_count,
    avatarUrl: u.avatar_url,
    badges: u.badges,
    tastes: u.tastes,
    accentHex: u.accent_hex,
    joinedYear: u.joined_year,
    role: u.role,
  };
}

const profileSchema = z.object({
  name: z.string().trim().min(2).max(80),
  city: z.string().trim().min(2).max(60),
  bio: z.string().trim().max(400).default(''),
  tastes: z.array(z.string().trim().min(1).max(40)).max(8).default([]),
});

// PATCH /api/users/me — edit the signed-in profile.
router.patch('/me', async (req, res) => {
  const input = profileSchema.parse(req.body ?? {});

  await query(
    'UPDATE users SET name = $2, city = $3, bio = $4, tastes = $5 WHERE id = $1::UUID',
    [req.userId, input.name, input.city, input.bio, input.tastes],
  );

  const [updated] = await query<UserRow>(
    'SELECT * FROM users WHERE id = $1::UUID',
    [req.userId],
  );
  if (!updated) throw notFound('User');
  res.json({ user: serialize(updated) });
});


// GET /api/users/me — the signed-in user's own profile.
router.get('/me', async (req, res) => {
  const [user] = await query<UserRow>('SELECT * FROM users WHERE id = $1::UUID', [
    req.userId,
  ]);
  if (!user) throw notFound('User');
  res.json({ user: serialize(user) });
});

// GET /api/users/:id — profile card plus hosted upcoming events and reviews.
router.get('/:id', async (req, res) => {
  const [user] = await query<UserRow>('SELECT * FROM users WHERE id = $1::UUID', [
    req.params.id,
  ]);
  if (!user) throw notFound('User');

  const hosted = await query<{
    id: string;
    title: string;
    tagline: string;
    start_at: Date;
    cover_image: string;
    seats_total: number;
    seats_booked: number;
    price_per_seat: string;
    type: string;
  }>(
    `SELECT id, title, tagline, start_at, cover_image, seats_total, seats_booked,
            price_per_seat, type
     FROM dinner_events
     WHERE host_id = $1 AND start_at >= now()
     ORDER BY start_at ASC
     LIMIT 20`,
    [user.id],
  );

  const reviews = await query<{
    id: string;
    rating: string;
    text: string;
    created_at: Date;
    event_title: string;
    author_name: string | null;
    author_handle: string | null;
    author_avatar: string | null;
  }>(
    `SELECT rv.id, rv.rating, rv.text, rv.created_at, e.title AS event_title,
            u.name AS author_name, u.handle AS author_handle,
            u.avatar_url AS author_avatar
     FROM reviews rv
     JOIN dinner_events e ON e.id = rv.event_id
     LEFT JOIN users u ON u.id = rv.author_id
     WHERE e.host_id = $1
     ORDER BY rv.created_at DESC
     LIMIT 10`,
    [user.id],
  );

  const [follow] = await query<{ is_following: boolean }>(
    `SELECT EXISTS (
       SELECT 1 FROM follows WHERE follower_id = $1 AND followee_id = $2
     ) AS is_following`,
    [req.userId, user.id],
  );

  res.json({
    user: serialize(user),
    viewerFollows: follow?.is_following ?? false,
    hostedUpcoming: hosted.map((e) => ({
      id: e.id,
      title: e.title,
      tagline: e.tagline,
      startAt: e.start_at,
      coverImage: e.cover_image,
      seatsTotal: e.seats_total,
      seatsBooked: e.seats_booked,
      seatsLeft: Math.max(0, e.seats_total - e.seats_booked),
      pricePerSeat: Number(e.price_per_seat),
      type: e.type,
    })),
    reviews: reviews.map((r) => ({
      id: r.id,
      rating: Number(r.rating),
      text: r.text,
      createdAt: r.created_at,
      eventTitle: r.event_title,
      author: {
        name: r.author_name,
        handle: r.author_handle,
        avatarUrl: r.author_avatar,
      },
    })),
  });
});

export default router;

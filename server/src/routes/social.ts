import { Router } from 'express';
import { query } from '../db.js';
import { notFound, forbidden } from '../context.js';

const router = Router();

type ActivityRow = {
  id: string;
  kind: string;
  title: string;
  body: string;
  actor_id: string | null;
  event_id: string | null;
  amount: string | null;
  is_unread: boolean;
  created_at: Date;
  actor_name: string | null;
  actor_handle: string | null;
  actor_avatar: string | null;
};

const ACTIVITY_SELECT = `
  SELECT a.*, u.name AS actor_name, u.handle AS actor_handle,
         u.avatar_url AS actor_avatar
  FROM activity a
  LEFT JOIN users u ON u.id = a.actor_id`;

// GET /api/activity — the signed-in user's feed, newest first.
router.get('/activity', async (req, res) => {
  const rows = await query<ActivityRow>(
    `${ACTIVITY_SELECT}
     WHERE a.actor_id = $1
     ORDER BY a.created_at DESC
     LIMIT 100`,
    [req.userId],
  );

  res.json({
    activity: rows.map((a) => ({
      id: a.id,
      kind: a.kind,
      title: a.title,
      body: a.body,
      eventId: a.event_id,
      amount: a.amount === null ? null : Number(a.amount),
      isUnread: a.is_unread,
      createdAt: a.created_at,
      actor: a.actor_id === null ? null : {
        id: a.actor_id,
        name: a.actor_name,
        handle: a.actor_handle,
        avatarUrl: a.actor_avatar,
      },
    })),
    unreadCount: rows.filter((a) => a.is_unread).length,
  });
});

// POST /api/activity/read — marks every item as read.
router.post('/activity/read', async (req, res) => {
  await query(
    'UPDATE activity SET is_unread = false WHERE actor_id = $1',
    [req.userId],
  );
  res.json({ read: true });
});

// -- Saved events -----------------------------------------------------------

type SavedEventRow = {
  id: string;
  title: string;
  tagline: string;
  start_at: Date;
  cover_image: string;
  seats_total: number;
  seats_booked: number;
  price_per_seat: string;
  type: string;
  host_name: string | null;
};

// GET /api/me/saved — events the user bookmarked.
router.get('/me/saved', async (req, res) => {
  const rows = await query<SavedEventRow>(
    `SELECT e.id, e.title, e.tagline, e.start_at, e.cover_image,
            e.seats_total, e.seats_booked, e.price_per_seat, e.type,
            u.name AS host_name
     FROM saved_events s
     JOIN dinner_events e ON e.id = s.event_id
     LEFT JOIN users u ON u.id = e.host_id
     WHERE s.user_id = $1
     ORDER BY e.start_at ASC`,
    [req.userId],
  );

  res.json({
    saved: rows.map((e) => ({
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
      hostName: e.host_name,
    })),
  });
});

// POST /api/events/:id/save — bookmark an event.
router.post('/events/:id/save', async (req, res) => {
  const [event] = await query<{ id: string }>(
    'SELECT id FROM dinner_events WHERE id = $1::UUID',
    [req.params.id],
  );
  if (!event) throw notFound('Event');

  await query(
    `INSERT INTO saved_events (user_id, event_id) VALUES ($1, $2)
     ON CONFLICT DO NOTHING`,
    [req.userId, req.params.id],
  );
  res.status(201).json({ saved: true, eventId: req.params.id });
});

// DELETE /api/events/:id/save — unbookmark.
router.delete('/events/:id/save', async (req, res) => {
  await query(
    'DELETE FROM saved_events WHERE user_id = $1 AND event_id = $2',
    [req.userId, req.params.id],
  );
  res.json({ saved: false, eventId: req.params.id });
});

// -- Follows ----------------------------------------------------------------

// POST /api/users/:id/follow — follow a user (never yourself).
router.post('/users/:id/follow', async (req, res) => {
  const [target] = await query<{ id: string; followers_count: number }>(
    'SELECT id, followers_count FROM users WHERE id = $1::UUID',
    [req.params.id],
  );
  if (!target) throw notFound('User');
  if (target.id === req.userId) {
    throw forbidden('You cannot follow yourself');
  }

  const inserted = await query<{ follower_id: string }>(
    `INSERT INTO follows (follower_id, followee_id) VALUES ($1, $2)
     ON CONFLICT DO NOTHING
     RETURNING follower_id`,
    [req.userId, target.id],
  );

  if (inserted.length > 0) {
    await query(
      'UPDATE users SET followers_count = followers_count + 1 WHERE id = $1::UUID',
      [target.id],
    );
    await query(
      'UPDATE users SET following_count = following_count + 1 WHERE id = $1::UUID',
      [req.userId],
    );

    const [actor] = await query<{ name: string; followers_count: number }>(
      'SELECT name, followers_count FROM users WHERE id = $1::UUID',
      [req.userId],
    );
    await query(
      `INSERT INTO activity (actor_id, kind, title, body, is_unread)
       VALUES ($1, 'follower', $2, $3, true)`,
      [
        target.id,
        `${actor?.name ?? 'Someone'} started following you`,
        `You now have ${(target.followers_count ?? 0) + 1} followers.`,
      ],
    );
  }

  const [followerCount] = await query<{ followers_count: number }>(
    'SELECT followers_count FROM users WHERE id = $1::UUID',
    [target.id],
  );
  res.status(201).json({
    following: true,
    userId: target.id,
    followers: followerCount?.followers_count ?? 0,
  });
});

// DELETE /api/users/:id/follow — unfollow.
router.delete('/users/:id/follow', async (req, res) => {
  const removed = await query<{ follower_id: string }>(
    `DELETE FROM follows WHERE follower_id = $1::UUID AND followee_id = $2::UUID
     RETURNING follower_id`,
    [req.userId, req.params.id],
  );

  if (removed.length > 0) {
    await query(
      'UPDATE users SET followers_count = GREATEST(0, followers_count - 1) WHERE id = $1::UUID',
      [req.params.id],
    );
    await query(
      'UPDATE users SET following_count = GREATEST(0, following_count - 1) WHERE id = $1::UUID',
      [req.userId],
    );
  }

  const [followerCount] = await query<{ followers_count: number }>(
    'SELECT followers_count FROM users WHERE id = $1::UUID',
    [req.params.id],
  );
  res.json({
    following: false,
    userId: req.params.id,
    followers: followerCount?.followers_count ?? 0,
  });
});

export default router;

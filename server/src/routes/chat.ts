import { Router } from 'express';
import { z } from 'zod';
import { query } from '../db.js';
import { ApiError, notFound, forbidden } from '../context.js';

const router = Router();

/**
 * A member is the host, a guest with an active booking, or anyone on the
 * seeded attendee list. System messages have a null author.
 */
async function requireMember(eventId: string, userId: string) {
  const [event] = await query<{ id: string; host_id: string; attendee_ids: string[] }>(
    'SELECT id, host_id, attendee_ids FROM dinner_events WHERE id = $1',
    [eventId],
  );
  if (!event) throw notFound('Event');

  const isMember =
    event.host_id === userId ||
    event.attendee_ids.includes(userId) ||
    (await query<{ exists: boolean }>(
      `SELECT EXISTS (
         SELECT 1 FROM bookings
         WHERE event_id = $1 AND user_id = $2 AND status <> 'cancelled'
       ) AS exists`,
      [eventId, userId],
    ))[0]!.exists;

  if (!isMember) {
    throw forbidden('Event chat is for hosts and booked guests');
  }
  return event;
}

type MessageRow = {
  id: string;
  author_id: string | null;
  text: string;
  sent_at: Date;
  is_system: boolean;
  author_name: string | null;
  author_handle: string | null;
  author_avatar: string | null;
};

const MESSAGE_SELECT = `
  SELECT m.id, m.author_id, m.text, m.sent_at, m.is_system,
         u.name AS author_name, u.handle AS author_handle,
         u.avatar_url AS author_avatar
  FROM chat_messages m
  LEFT JOIN users u ON u.id = m.author_id`;

// GET /api/events/:id/messages — the event's chat thread, oldest first.
router.get('/events/:id/messages', async (req, res) => {
  const event = await requireMember(req.params.id, req.userId);
  const rows = await query<MessageRow>(
    `${MESSAGE_SELECT}
     WHERE m.event_id = $1
     ORDER BY m.sent_at ASC
     LIMIT 200`,
    [event.id],
  );

  res.json({
    messages: rows.map((m) => ({
      id: m.id,
      authorId: m.author_id,
      text: m.text,
      sentAt: m.sent_at,
      isSystem: m.is_system,
      author: m.author_id === null ? null : {
        id: m.author_id,
        name: m.author_name,
        handle: m.author_handle,
        avatarUrl: m.author_avatar,
      },
    })),
    count: rows.length,
  });
});

const sendSchema = z.object({
  text: z.string().trim().min(1).max(1000),
});

// POST /api/events/:id/messages — post to the thread as the current user.
router.post('/events/:id/messages', async (req, res) => {
  const event = await requireMember(req.params.id, req.userId);
  const { text } = sendSchema.parse(req.body ?? {});

  const [sent] = await query<MessageRow>(
    `INSERT INTO chat_messages (event_id, author_id, text, sent_at)
     VALUES ($1, $2, $3, now())
     RETURNING id, author_id, text, sent_at, is_system`,
    [event.id, req.userId, text],
  );
  if (!sent) throw new ApiError(500, 'Message could not be sent');

  // Re-fetch with author info
  const [full] = await query<MessageRow>(
    `${MESSAGE_SELECT} WHERE m.id = $1`,
    [sent.id],
  );
  if (!full) throw new ApiError(500, 'Message could not be loaded');

  res.status(201).json({
    message: {
      id: full.id,
      authorId: full.author_id,
      text: full.text,
      sentAt: full.sent_at,
      isSystem: full.is_system,
      author: full.author_id === null ? null : {
        id: full.author_id,
        name: full.author_name,
        handle: full.author_handle,
        avatarUrl: full.author_avatar,
      },
    },
  });
});

export default router;

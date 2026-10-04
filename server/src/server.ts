import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createServer } from 'node:http';
import { Server as SocketServer } from 'socket.io';
import { ZodError } from 'zod';
import type { NextFunction, Request, Response } from 'express';
import { pool } from './db.js';
import { ApiError, requireAuth } from './context.js';
import { apiRateLimiter, authRateLimiter, auditLog } from './security.js';
import authRouter from './routes/auth.js';
import bookingsRouter from './routes/bookings.js';
import chatRouter from './routes/chat.js';
import eventsRouter from './routes/events.js';
import hostsRouter from './routes/hosts.js';
import partnerRouter from './routes/partner.js';
import restaurantsRouter from './routes/restaurants.js';
import reviewsRouter from './routes/reviews.js';
import socialRouter from './routes/social.js';
import usersRouter from './routes/users.js';

const app = express();
app.disable('x-powered-by');

// ── Security headers & CORS ─────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: (origin, callback) => {
    if (!origin) return callback(null, true);
    const allowed = [
      'http://localhost:3000',
      'http://localhost:4000',
      'http://localhost:8080',
      'http://127.0.0.1:8080',
      'http://10.0.2.2:3000',
      'http://10.0.2.2:4000',
    ];
    if (allowed.includes(origin)) return callback(null, true);
    if (process.env.NODE_ENV !== 'production') return callback(null, true);
    callback(new Error('CORS: origin not allowed'));
  },
}));
app.use(express.json({ limit: '1mb' }));

// ── Rate limiting ───────────────────────────────────────────────────────────
app.use('/api/', apiRateLimiter);

// Create HTTP server and attach Socket.io
const httpServer = createServer(app);
const io = new SocketServer(httpServer, {
  cors: { origin: '*' },
});

// ── WebSocket handling (authenticated) ──────────────────────────────────────

/** Look up a user from an auth token. Returns null if invalid/expired. */
async function resolveUserFromToken(token: string | undefined): Promise<{ id: string; role: string } | null> {
  if (!token) return null;
  const cleaned = token.startsWith('Bearer ') ? token.slice(7).trim() : token;
  const result = await pool.query<{ user_id: string; role: string }>(
    `SELECT at.user_id, u.role
     FROM auth_tokens at
     JOIN users u ON u.id = at.user_id
     WHERE at.token = $1 AND at.expires_at > now()`,
    [cleaned],
  );
  if (result.rows.length === 0) return null;
  const row = result.rows[0];
  return row ? { id: row.user_id, role: row.role } : null;
}

/** Check if a user is a member (host, booked guest, or partner) of an event. */
async function canAccessEvent(eventId: string, userId: string, role: string): Promise<boolean> {
  // Partner admins and super admins can access any event
  if (role === 'partner_admin' || role === 'super_admin') return true;

  const result = await pool.query<{ ok: boolean }>(
    `SELECT EXISTS(
       SELECT 1 FROM dinner_events e
       WHERE e.id = $1::UUID AND (e.host_id = $2::UUID
         OR EXISTS (SELECT 1 FROM bookings b WHERE b.event_id = $1::UUID AND b.user_id = $2::UUID AND b.status <> 'cancelled'))
     ) AS ok`,
    [eventId, userId],
  );
  return result.rows[0]?.ok ?? false;
}

/** Check if a user owns a restaurant. */
async function canAccessRestaurant(restaurantId: string, userId: string, role: string): Promise<boolean> {
  if (role === 'partner_admin' || role === 'super_admin') return true;
  const result = await pool.query<{ ok: boolean }>(
    `SELECT EXISTS(
       SELECT 1 FROM restaurants WHERE id = $1::UUID AND owner_id = $2::UUID
     ) AS ok`,
    [restaurantId, userId],
  );
  return result.rows[0]?.ok ?? false;
}

// Track authenticated userId per socket for chat messages
const socketUsers = new Map<string, { id: string; role: string }>();

io.on('connection', async (socket) => {
  const token = socket.handshake.auth?.token;
  const user = await resolveUserFromToken(token);

  if (!user) {
    // Unauthenticated connection — reject
    socket.disconnect(true);
    return;
  }

  socketUsers.set(socket.id, user);

  socket.on('join_event', async (eventId: string) => {
    const ok = await canAccessEvent(eventId, user.id, user.role);
    if (ok) {
      socket.join(`event_${eventId}`);
    } else {
      socket.emit('error', { message: 'Not authorised to join this event' });
    }
  });

  socket.on('leave_event', (eventId: string) => {
    socket.leave(`event_${eventId}`);
  });

  socket.on('join_restaurant', async (restaurantId: string) => {
    const ok = await canAccessRestaurant(restaurantId, user.id, user.role);
    if (ok) {
      socket.join(`restaurant_${restaurantId}`);
    } else {
      socket.emit('error', { message: 'Not authorised to join this restaurant' });
    }
  });

  socket.on('leave_restaurant', (restaurantId: string) => {
    socket.leave(`restaurant_${restaurantId}`);
  });

  socket.on('chat_message', async (data: { eventId: string; text: string }) => {
    // Re-verify membership before broadcasting
    const ok = await canAccessEvent(data.eventId, user.id, user.role);
    if (!ok) {
      socket.emit('error', { message: 'Not authorised to chat in this event' });
      return;
    }
    socket.to(`event_${data.eventId}`).emit('new_message', {
      eventId: data.eventId,
      text: data.text,
      userId: user.id,
      sentAt: new Date().toISOString(),
    });
  });

  socket.on('disconnect', () => {
    socketUsers.delete(socket.id);
  });
});

/** Helper: emit a booking update to all clients watching an event. */
export function emitBookingUpdated(eventId: string, booking: unknown) {
  io.to(`event_${eventId}`).emit('booking_updated', booking);
}

/** Helper: emit an event status change to all watchers. */
export function emitEventUpdated(eventId: string, event: unknown) {
  io.to(`event_${eventId}`).emit('event_updated', event);
}

/** Helper: emit a notification to a restaurant's watchers. */
export function emitRestaurantNotification(restaurantId: string, notification: unknown) {
  io.to(`restaurant_${restaurantId}`).emit('notification', notification);
}

// ── REST API routes ─────────────────────────────────────────────────────────

// Public: sign-in flow and liveness (with strict rate limiting for auth).
app.use('/api/auth', authRateLimiter, authRouter);

app.get('/api/health', async (_req: Request, res: Response) => {
  const started = Date.now();
  await pool.query('SELECT 1');
  res.json({
    status: 'ok',
    database: 'unified dinecircle',
    latencyMs: Date.now() - started,
    time: new Date().toISOString(),
  });
});

// Everything below requires a Bearer token.
app.use(requireAuth);

// Audit logging for all authenticated mutating requests.
app.use(auditLog);

// Mobile app routes
app.use('/api/events', eventsRouter);
app.use('/api/restaurants', restaurantsRouter);
app.use('/api/users', usersRouter);
app.use('/api/hosts', hostsRouter);
app.use('/api', reviewsRouter);
app.use('/api', bookingsRouter);
app.use('/api', chatRouter);
app.use('/api', socialRouter);

// Partner app routes (role-gated: partner_admin, super_admin)
app.use('/api/partner', partnerRouter);

app.use((_req: Request, res: Response, _next: NextFunction) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use(
  (error: unknown, _req: Request, res: Response, _next: NextFunction) => {
    if (error instanceof ApiError) {
      res.status(error.status).json({ error: error.message });
      return;
    }
    if (error instanceof ZodError) {
      res.status(400).json({ error: 'Invalid request body', issues: error.issues });
      return;
    }
    console.error('Unhandled error:', error);
    res.status(500).json({ error: 'Internal server error' });
  },
);

const port = Number(process.env.PORT ?? 4000);
httpServer.listen(port, () => {
  console.log(`DineCircle API (unified + WebSocket) listening on http://localhost:${port}`);
});

let shuttingDown = false;
function shutdown(signal: string): void {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log(`\n${signal} received — closing server`);
  io.close();
  httpServer.close(async () => {
    await pool.end().catch(() => undefined);
    process.exit(0);
  });
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

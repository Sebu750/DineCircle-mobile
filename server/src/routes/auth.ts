import { Router } from 'express';
import { randomBytes } from 'node:crypto';
import { z } from 'zod';
import { query } from '../db.js';
import { requireAuth, loadUser } from '../context.js';

const router = Router();

const TOKEN_TTL_DAYS = 30;

const phoneSchema = z
  .string()
  .trim()
  .regex(/^\+?[0-9][0-9\s-]{7,19}$/, 'Enter a valid phone number');

// POST /api/auth/signin — simple MVP sign-in.
// Accepts a phone number, finds or creates the user, returns a token.
// No OTP required for the MVP demo.
router.post('/signin', async (req, res) => {
  const { phone } = z.object({ phone: phoneSchema }).parse(req.body ?? {});
  const normalized = phone.replace(/[\s-]/g, '');

  const [existing] = await query<{ id: string; role: string }>(
    'SELECT id, role FROM users WHERE phone = $1',
    [normalized],
  );

  let userId = existing?.id;
  if (!userId) {
    const digits = normalized.slice(-4);
    const [created] = await query<{ id: string }>(
      `INSERT INTO users (name, handle, phone, city, bio, joined_year, accent_hex)
       VALUES ($1, $2, $3, 'Lyon', '', $4, $5)
       RETURNING id`,
      [
        `Diner ${digits}`,
        `diner.${digits}${Math.random().toString(36).slice(2, 5)}`,
        normalized,
        new Date().getFullYear(),
        '#4A5A7A',
      ],
    );
    userId = created?.id;
  }
  if (!userId) {
    res.status(500).json({ error: 'Could not create the account' });
    return;
  }

  const token = `dc_${randomBytes(24).toString('hex')}`;
  const expiresAt = new Date(Date.now() + TOKEN_TTL_DAYS * 24 * 60 * 60_000);
  await query(
    'INSERT INTO auth_tokens (token, user_id, expires_at) VALUES ($1, $2, $3)',
    [token, userId, expiresAt],
  );

  res.json({ token, expiresAt, user: await loadUser(userId) });
});

// ── Legacy OTP endpoints (kept for backward compatibility) ──────────────────

const OTP_TTL_MINUTES = 10;
const isDev = process.env.NODE_ENV !== 'production';

const requestSchema = z.object({ phone: phoneSchema });
const verifySchema = z.object({
  phone: phoneSchema,
  code: z.string().trim().regex(/^[0-9]{6}$/, 'Enter the 6-digit code'),
});

function generateOtp(): string {
  const buf = randomBytes(4);
  const num = buf.readUInt32BE(0) % 1_000_000;
  return num.toString().padStart(6, '0');
}

router.post('/otp/request', async (req, res) => {
  const { phone } = requestSchema.parse(req.body ?? {});
  const normalized = phone.replace(/[\s-]/g, '');
  const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60_000);
  const code = generateOtp();

  await query(
    `INSERT INTO otp_codes (phone, code, expires_at)
     VALUES ($1, $2, $3)
     ON CONFLICT (phone) DO UPDATE
       SET code = EXCLUDED.code, expires_at = EXCLUDED.expires_at,
           created_at = now()`,
    [normalized, code, expiresAt],
  );

  if (isDev) {
    console.log(`[OTP] Code for ${normalized}: ${code}`);
    res.json({ sent: true, phone: normalized, expiresAt, devCode: code });
  } else {
    console.log(`[SMS] Sending OTP to ${normalized}`);
    res.json({ sent: true, phone: normalized, expiresAt });
  }
});

router.post('/otp/verify', async (req, res) => {
  const { phone, code } = verifySchema.parse(req.body ?? {});
  const normalized = phone.replace(/[\s-]/g, '');

  const [otp] = await query<{ code: string; expires_at: Date }>(
    'SELECT code, expires_at FROM otp_codes WHERE phone = $1',
    [normalized],
  );
  if (!otp || otp.code !== code) {
    res.status(401).json({ error: 'That code is not right. Try again.' });
    return;
  }
  if (new Date(otp.expires_at).getTime() <= Date.now()) {
    res.status(401).json({ error: 'That code expired. Request a new one.' });
    return;
  }
  await query('DELETE FROM otp_codes WHERE phone = $1', [normalized]);

  const [existing] = await query<{ id: string }>(
    'SELECT id FROM users WHERE phone = $1',
    [normalized],
  );

  let userId = existing?.id;
  if (!userId) {
    const digits = normalized.slice(-4);
    const [created] = await query<{ id: string }>(
      `INSERT INTO users (name, handle, phone, city, bio, joined_year, accent_hex)
       VALUES ($1, $2, $3, 'Lyon', '', $4, $5)
       RETURNING id`,
      [
        `Diner ${digits}`,
        `diner.${digits}${Math.random().toString(36).slice(2, 5)}`,
        normalized,
        new Date().getFullYear(),
        '#4A5A7A',
      ],
    );
    userId = created?.id;
  }
  if (!userId) {
    res.status(500).json({ error: 'Could not create the account' });
    return;
  }

  const token = `dc_${randomBytes(24).toString('hex')}`;
  const expiresAt = new Date(Date.now() + TOKEN_TTL_DAYS * 24 * 60 * 60_000);
  await query(
    'INSERT INTO auth_tokens (token, user_id, expires_at) VALUES ($1, $2, $3)',
    [token, userId, expiresAt],
  );

  res.json({ token, expiresAt, user: await loadUser(userId) });
});

// GET /api/auth/me — the session's user (used on app start to restore state).
router.get('/me', requireAuth, async (req, res) => {
  res.json({ user: await loadUser(req.userId) });
});

// POST /api/auth/signout — deletes the token row.
router.post('/signout', requireAuth, async (req, res) => {
  const header = req.header('Authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
  await query('DELETE FROM auth_tokens WHERE token = $1', [token]);
  res.json({ signedOut: true });
});

export default router;

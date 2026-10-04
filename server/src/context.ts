import type { Request, Response, NextFunction, RequestHandler } from 'express';
import { query } from './db.js';

/** Recognised roles in the unified schema. */
export type UserRole = 'user' | 'host' | 'partner_admin' | 'super_admin';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      /** The acting user's UUID, resolved from the Bearer token. */
      userId: string;
      /** The acting user's role, loaded by requireAuth. */
      userRole: UserRole;
    }
  }
}

export class ApiError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

export const notFound = (what: string): ApiError =>
  new ApiError(404, `${what} not found`);

export const forbidden = (why: string): ApiError => new ApiError(403, why);

export const unauthorized = (): ApiError =>
  new ApiError(401, 'Sign in to continue');

/**
 * Resolves the acting user from the Authorization: Bearer <token> header.
 * Tokens live in auth_tokens with a 30-day expiry.
 */
export const requireAuth: RequestHandler = async (
  req: Request,
  _res: Response,
  next: NextFunction,
) => {
  try {
    const header = req.header('Authorization') ?? '';
    const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
    if (token === '') throw unauthorized();

    const [session] = await query<{ user_id: string; role: string }>(
      `SELECT at.user_id, u.role
       FROM auth_tokens at
       JOIN users u ON u.id = at.user_id
       WHERE at.token = $1 AND at.expires_at > now()`,
      [token],
    );
    if (!session) throw unauthorized();

    req.userId = session.user_id;
    req.userRole = session.role as UserRole;
    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Middleware factory: restrict access to specific roles.
 * Usage: router.get('/', requireRole('partner_admin', 'super_admin'), handler)
 */
export function requireRole(...roles: UserRole[]): RequestHandler {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.userRole || !roles.includes(req.userRole)) {
      return next(forbidden('Insufficient permissions'));
    }
    next();
  };
}

/** Serializes the current user for auth endpoints (full profile shape). */
export async function loadUser(id: string) {
  const [user] = await query<{
    id: string; name: string; handle: string; phone: string | null;
    city: string; bio: string; followers_count: number; following_count: number;
    dinners_hosted: number; dinners_joined: number; rating: string;
    review_count: number; avatar_url: string | null; badges: string[];
    tastes: string[]; accent_hex: string | null; joined_year: number;
    role: string;
  }>('SELECT * FROM users WHERE id = $1', [id]);
  if (!user) throw notFound('User');
  return {
    id: user.id,
    name: user.name,
    handle: user.handle,
    phone: user.phone,
    city: user.city,
    bio: user.bio,
    followers: user.followers_count,
    following: user.following_count,
    dinnersHosted: user.dinners_hosted,
    dinnersJoined: user.dinners_joined,
    rating: Number(user.rating),
    reviewCount: user.review_count,
    avatarUrl: user.avatar_url,
    badges: user.badges,
    tastes: user.tastes,
    accentHex: user.accent_hex,
    joinedYear: user.joined_year,
    role: user.role,
  };
}

import type { Request, Response, NextFunction } from 'express';
import rateLimit from 'express-rate-limit';
import { query } from './db.js';

/**
 * Rate limiter: 100 requests per minute per IP.
 * Applied globally to all /api/* routes.
 */
export const apiRateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests — please try again later' },
});

/**
 * Stricter rate limiter for auth endpoints: 10 requests per minute.
 */
export const authRateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many authentication attempts — please wait' },
});

/**
 * Audit logging middleware.
 * Records write operations (POST/PUT/PATCH/DELETE) to the audit_log table.
 */
export function auditLog(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  // Only log mutating methods
  if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) {
    next();
    return;
  }

  // Capture the original end() to log after the response is sent
  const originalEnd = res.end;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  (res as any).end = function (...args: any[]) {
    // Fire-and-forget audit insert
    const userId = req.userId ?? null;
    const action = req.method;
    const resource = req.path;
    const statusCode = res.statusCode;

    query(
      `INSERT INTO audit_log (user_id, action, resource, resource_id, changes, status_code, ip_address, user_agent)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        userId,
        action,
        resource,
        req.params.id ?? null,
        JSON.stringify(req.body ?? {}),
        statusCode,
        req.ip ?? null,
        req.get('user-agent') ?? null,
      ],
    ).catch((err) => {
      console.error('Audit log insert failed:', err);
    });

    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-explicit-any
    return (originalEnd as any).apply(res, args);
  };

  next();
}

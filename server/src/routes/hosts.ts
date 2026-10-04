import { Router } from 'express';
import { query } from '../db.js';
import { forbidden, notFound } from '../context.js';
import type { UserRole } from '../context.js';

const router = Router();

type PayoutRow = {
  id: string;
  event_id: string;
  event_title: string;
  payout_date: Date;
  seats_sold: number;
  gross: string;
  commission: string;
  status: string;
};

function serialize(p: PayoutRow) {
  const gross = Number(p.gross);
  const commission = Number(p.commission);
  return {
    id: p.id,
    eventId: p.event_id,
    eventTitle: p.event_title,
    date: p.payout_date,
    seatsSold: p.seats_sold,
    gross,
    commission,
    net: gross - commission,
    status: p.status,
  };
}

async function requireHost(id: string): Promise<void> {
  const [host] = await query<{ id: string }>(
    'SELECT id FROM users WHERE id = $1::UUID',
    [id],
  );
  if (!host) throw notFound('Host');
}

/**
 * Ensure the caller is either the host themselves, or a privileged role.
 * Prevents any random user from viewing another host's financial data.
 */
function assertHostAccess(requesterId: string, requesterRole: UserRole, targetHostId: string): void {
  if (requesterId === targetHostId) return;
  if (requesterRole === 'partner_admin' || requesterRole === 'super_admin') return;
  throw forbidden('You can only view your own earnings');
}

// GET /api/hosts/:id/payouts — one earnings line per hosted event.
router.get('/:id/payouts', async (req, res) => {
  const hostId = req.params.id;
  await requireHost(hostId);
  assertHostAccess(req.userId, req.userRole, hostId);

  const rows = await query<PayoutRow>(
    `SELECT p.*, e.title AS event_title
     FROM payouts p
     JOIN dinner_events e ON e.id = p.event_id
     WHERE e.host_id = $1::UUID
     ORDER BY p.payout_date DESC
     LIMIT 200`,
    [hostId],
  );
  res.json({ payouts: rows.map(serialize), count: rows.length });
});

type MoneyRow = {
  earned: number;
  in_transit: number;
  scheduled: number;
  lifetime_gross: number;
  commission_total: number;
  seats_sold: number;
};

type TablesRow = {
  hosted_count: number;
  upcoming_count: number;
  fill_rate: number;
};

// GET /api/hosts/:id/summary — headline numbers for the earnings panel.
router.get('/:id/summary', async (req, res) => {
  const hostId = req.params.id;
  await requireHost(hostId);
  assertHostAccess(req.userId, req.userRole, hostId);

  const [money] = await query<MoneyRow>(
    `SELECT
       COALESCE((SUM(gross - commission) FILTER (WHERE status = 'paid')), 0)::float8      AS earned,
       COALESCE((SUM(gross - commission) FILTER (WHERE status = 'processing')), 0)::float8 AS in_transit,
       COALESCE((SUM(gross - commission) FILTER (WHERE status = 'scheduled')), 0)::float8 AS scheduled,
       COALESCE(SUM(gross), 0)::float8                                                     AS lifetime_gross,
       COALESCE(SUM(commission), 0)::float8                                                AS commission_total,
       COALESCE(SUM(seats_sold), 0)::int                                                   AS seats_sold
     FROM payouts p
     JOIN dinner_events e ON e.id = p.event_id
     WHERE e.host_id = $1::UUID`,
    [hostId],
  );

  const [tables] = await query<TablesRow>(
    `SELECT count(*)::int AS hosted_count,
            (count(*) FILTER (WHERE start_at >= now()))::int AS upcoming_count,
            COALESCE(AVG(seats_booked::numeric / GREATEST(seats_total, 1)), 0)::float8 AS fill_rate
     FROM dinner_events
     WHERE host_id = $1::UUID`,
    [hostId],
  );

  const earned = money?.earned ?? 0;
  const inTransit = money?.in_transit ?? 0;
  const scheduled = money?.scheduled ?? 0;
  const lifetimeGross = money?.lifetime_gross ?? 0;
  const seatsSold = money?.seats_sold ?? 0;

  const now = new Date();
  const nextPayout = new Date(now.getFullYear(), now.getMonth() + 1, 1);

  res.json({
    hostId,
    earned,
    inTransit,
    scheduled,
    lifetimeGross,
    commissionTotal: money?.commission_total ?? 0,
    netTotal: earned + inTransit + scheduled,
    seatsSold,
    averageSeatPrice: seatsSold > 0 ? lifetimeGross / seatsSold : 0,
    hostedCount: tables?.hosted_count ?? 0,
    upcomingCount: tables?.upcoming_count ?? 0,
    averageFillRate: tables?.fill_rate ?? 0,
    nextPayoutDate: nextPayout.toISOString(),
  });
});

type TrendRow = {
  label: string;
  month: Date;
  seats: number;
  revenue: number;
};

// GET /api/hosts/:id/trend — net revenue and seats per month.
router.get('/:id/trend', async (req, res) => {
  const hostId = req.params.id;
  await requireHost(hostId);
  assertHostAccess(req.userId, req.userRole, hostId);

  const rows = await query<TrendRow>(
    `SELECT to_char(m.month, 'Mon') AS label,
            m.month,
            COALESCE(SUM(p.seats_sold), 0)::int AS seats,
            COALESCE(SUM(p.gross - p.commission), 0)::float8 AS revenue
     FROM generate_series(
            date_trunc('month', now()) - interval '5 months',
            date_trunc('month', now()),
            interval '1 month') AS m(month)
     LEFT JOIN payouts p
       ON date_trunc('month', p.payout_date) = m.month
      AND p.event_id IN (SELECT id FROM dinner_events WHERE host_id = $1::UUID)
     GROUP BY m.month
     ORDER BY m.month DESC`,
    [hostId],
  );

  res.json({
    trend: rows
      .slice(0, 6)
      .reverse()
      .map((r) => ({ label: r.label, seats: r.seats, revenue: r.revenue })),
  });
});

export default router;

/** Applies schema.sql — idempotent, safe to run repeatedly. */
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool } from './db.js';

const here = dirname(fileURLToPath(import.meta.url));
const sql = await readFile(join(here, 'schema.sql'), 'utf8');

try {
  await pool.query(sql);
  console.log(
    'Schema applied: users, restaurants, dinner_events, menu_items, ' +
      'bookings, payouts, reviews, follows.',
  );
} catch (error) {
  console.error('Schema failed:', error);
  process.exitCode = 1;
} finally {
  await pool.end();
}

import pg from 'pg';
import 'dotenv/config';

const connectionString =
  process.env.DATABASE_URL ??
  'postgresql://h4til3fishnix@localhost:5432/dinecircle';

export const pool = new pg.Pool({ connectionString, max: 10 });

export type QueryParams = ReadonlyArray<unknown>;

/** Thin wrapper so routes can `await query<T>(sql, params)` and get typed rows. */
export async function query<T extends pg.QueryResultRow = pg.QueryResultRow>(
  text: string,
  params: QueryParams = [],
): Promise<T[]> {
  const result = await pool.query<T>(text, params as unknown[]);
  return result.rows;
}

/** Run `fn` inside a transaction with commit/rollback. */
export async function withTransaction<T>(
  fn: (client: pg.PoolClient) => Promise<T>,
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const value = await fn(client);
    await client.query('COMMIT');
    return value;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

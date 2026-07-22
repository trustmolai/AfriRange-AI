import { Pool } from 'pg';

/**
 * Neon PostgreSQL + PostGIS Database Connection Pool
 * Uses environment variable DATABASE_URL provided by Neon DB
 */

const connectionString = process.env.DATABASE_URL || 'postgres://postgres:postgres@localhost:5432/afrirange';

export const dbPool = new Pool({
  connectionString,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

/**
 * Utility function to execute spatial SQL queries safely
 */
export async function query<T = any>(text: string, params?: any[]): Promise<{ rows: T[]; rowCount: number }> {
  const start = Date.now();
  try {
    const res = await dbPool.query(text, params);
    const duration = Date.now() - start;
    if (process.env.DEBUG_SQL === 'true') {
      console.log('Executed query:', { text, duration, rows: res.rowCount });
    }
    return { rows: res.rows, rowCount: res.rowCount };
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
}

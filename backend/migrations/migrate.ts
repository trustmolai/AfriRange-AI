import fs from 'fs';
import path from 'path';
import { Pool } from 'pg';
import dotenv from 'dotenv';

// Load environment variables from backend/.env
dotenv.config({ path: path.join(__dirname, '../.env') });

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error('ERROR: DATABASE_URL is not set in backend/.env');
  process.exit(1);
}

const pool = new Pool({
  connectionString,
  ssl: { rejectUnauthorized: false },
});

async function runMigrations() {
  console.log('Starting Neon Database Migrations...');
  const migrationsDir = path.join(__dirname);

  const files = fs.readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql'))
    .sort();

  for (const file of files) {
    console.log(`Executing migration: ${file}`);
    const filePath = path.join(migrationsDir, file);
    const sql = fs.readFileSync(filePath, 'utf8');

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(sql);
      await client.query('COMMIT');
      console.log(`Successfully applied ${file}`);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error(`Failed to apply ${file}:`, err);
      process.exit(1);
    } finally {
      client.release();
    }
  }

  console.log('All 8 migrations completed successfully on Neon PostgreSQL.');
  await pool.end();
  process.exit(0);
}

runMigrations();

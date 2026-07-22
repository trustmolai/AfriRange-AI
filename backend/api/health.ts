import type { NextApiRequest, NextApiResponse } from 'next';
import { query } from '../lib/db';
import { withErrorHandler, allowMethods } from '../lib/middleware';

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET'])) return;

  const start = Date.now();
  let dbStatus = 'healthy';
  let dbLatencyMs = 0;

  try {
    const dbStart = Date.now();
    await query('SELECT 1');
    dbLatencyMs = Date.now() - dbStart;
  } catch (error) {
    dbStatus = 'unhealthy';
  }

  const isHealthy = dbStatus === 'healthy';
  const statusCode = isHealthy ? 200 : 503;

  return res.status(statusCode).json({
    status: isHealthy ? 'ok' : 'degraded',
    service: 'AfriRange AI Backend API',
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.floor(process.uptime()),
    responseTimeMs: Date.now() - start,
    checks: {
      database: {
        status: dbStatus,
        latencyMs: dbLatencyMs,
      },
    },
  });
}

export default withErrorHandler(handler);

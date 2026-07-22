import type { NextApiRequest, NextApiResponse } from 'next';
import { verifyAccessToken, type JwtPayload } from './auth';

// ===================================================================
// AfriRange AI — API Middleware
// Auth guard, rate limiting, CORS, error handling
// ===================================================================

// -------------------------------------------------------------------
// Types
// -------------------------------------------------------------------

export interface AuthenticatedRequest extends NextApiRequest {
  user: JwtPayload;
}

export type ApiHandler = (
  req: NextApiRequest,
  res: NextApiResponse
) => Promise<void>;

export type AuthenticatedHandler = (
  req: AuthenticatedRequest,
  res: NextApiResponse
) => Promise<void>;

// -------------------------------------------------------------------
// Authentication Middleware
// -------------------------------------------------------------------

/** Extract and verify JWT from Authorization header. */
export function withAuth(handler: AuthenticatedHandler): ApiHandler {
  return async (req: NextApiRequest, res: NextApiResponse) => {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'unauthorized',
        message: 'Missing or invalid authorization header.',
      });
    }

    const token = authHeader.substring(7);
    const payload = verifyAccessToken(token);

    if (!payload) {
      return res.status(401).json({
        error: 'unauthorized',
        message: 'Invalid or expired access token.',
      });
    }

    (req as AuthenticatedRequest).user = payload;
    return handler(req as AuthenticatedRequest, res);
  };
}

// -------------------------------------------------------------------
// CORS Middleware
// -------------------------------------------------------------------

const ALLOWED_ORIGINS = [
  'http://localhost:3000',
  'https://afrirange.ai',
  'https://www.afrirange.ai',
];

export function setCorsHeaders(req: NextApiRequest, res: NextApiResponse): boolean {
  const origin = req.headers.origin || '';
  if (ALLOWED_ORIGINS.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  }
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return true;
  }
  return false;
}

// -------------------------------------------------------------------
// Rate Limiting (In-memory, suitable for Vercel serverless)
// -------------------------------------------------------------------

const rateLimitStore = new Map<string, { count: number; resetAt: number }>();

/**
 * Simple in-memory rate limiter.
 * Note: In Vercel serverless, each instance has its own memory.
 * For production scale, migrate to Upstash Redis rate limiting.
 */
export function checkRateLimit(
  ip: string,
  maxRequests: number = 10,
  windowMs: number = 60_000
): boolean {
  const now = Date.now();
  const key = ip;
  const entry = rateLimitStore.get(key);

  if (!entry || now > entry.resetAt) {
    rateLimitStore.set(key, { count: 1, resetAt: now + windowMs });
    return true;
  }

  if (entry.count >= maxRequests) {
    return false;
  }

  entry.count++;
  return true;
}

// -------------------------------------------------------------------
// Error Handling Wrapper
// -------------------------------------------------------------------

export function withErrorHandler(handler: ApiHandler): ApiHandler {
  return async (req: NextApiRequest, res: NextApiResponse) => {
    try {
      if (setCorsHeaders(req, res)) return;
      await handler(req, res);
    } catch (error: any) {
      console.error(`[API Error] ${req.method} ${req.url}:`, error);
      res.status(500).json({
        error: 'internal_server_error',
        message: 'An unexpected error occurred. Please try again later.',
      });
    }
  };
}

// -------------------------------------------------------------------
// Method Guard
// -------------------------------------------------------------------

export function allowMethods(
  req: NextApiRequest,
  res: NextApiResponse,
  methods: string[]
): boolean {
  if (!methods.includes(req.method || '')) {
    res.setHeader('Allow', methods.join(', '));
    res.status(405).json({
      error: 'method_not_allowed',
      message: `Only ${methods.join(', ')} methods are allowed.`,
    });
    return false;
  }
  return true;
}

// -------------------------------------------------------------------
// Client IP Extraction
// -------------------------------------------------------------------

export function getClientIp(req: NextApiRequest): string {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string') {
    return forwarded.split(',')[0].trim();
  }
  return req.socket?.remoteAddress || 'unknown';
}

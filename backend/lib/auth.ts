import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';

// ===================================================================
// AfriRange AI — Authentication Utilities
// bcrypt password hashing, JWT token management, secure token generation
// ===================================================================

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret-change-in-production';
const BCRYPT_ROUNDS = 12;

// -------------------------------------------------------------------
// Password Hashing (bcrypt, 12 rounds)
// -------------------------------------------------------------------

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, BCRYPT_ROUNDS);
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

// -------------------------------------------------------------------
// JWT Token Generation & Verification
// -------------------------------------------------------------------

export interface JwtPayload {
  userId: string;
  email: string;
  role: string;
}

/** Generate a short-lived access token (15 minutes). */
export function generateAccessToken(payload: JwtPayload): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '15m' });
}

/** Generate a long-lived refresh token (30 days). */
export function generateRefreshToken(payload: JwtPayload): string {
  return jwt.sign(payload, JWT_REFRESH_SECRET, { expiresIn: '30d' });
}

/** Verify and decode an access token. Returns null if invalid/expired. */
export function verifyAccessToken(token: string): JwtPayload | null {
  try {
    return jwt.verify(token, JWT_SECRET) as JwtPayload;
  } catch {
    return null;
  }
}

/** Verify and decode a refresh token. Returns null if invalid/expired. */
export function verifyRefreshToken(token: string): JwtPayload | null {
  try {
    return jwt.verify(token, JWT_REFRESH_SECRET) as JwtPayload;
  } catch {
    return null;
  }
}

// -------------------------------------------------------------------
// Secure Token Generation (email verification, password reset)
// -------------------------------------------------------------------

/** Generate a cryptographically secure random token (URL-safe). */
export function generateSecureToken(length: number = 48): string {
  return crypto.randomBytes(length).toString('base64url');
}

/** SHA-256 hash a token for safe database storage. */
export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

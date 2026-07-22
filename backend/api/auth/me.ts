import type { NextApiResponse } from 'next';
import { query } from '../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET'])) return;

  const result = await query(
    `SELECT id, email, full_name, phone_number, country_code, preferred_language, farming_type, role,
            email_verified, subscription_tier, subscription_status, ai_credit_balance, created_at
     FROM users WHERE id = $1 AND deleted_at IS NULL`,
    [req.user.userId]
  );

  if (result.rowCount === 0) {
    return res.status(404).json({ error: 'user_not_found', message: 'User profile not found.' });
  }

  const user = result.rows[0];

  return res.status(200).json({
    user: {
      id: user.id,
      email: user.email,
      fullName: user.full_name,
      phoneNumber: user.phone_number,
      countryCode: user.country_code,
      preferredLanguage: user.preferred_language,
      farmingType: user.farming_type,
      role: user.role,
      emailVerified: user.email_verified,
      subscriptionTier: user.subscription_tier,
      subscriptionStatus: user.subscription_status,
      aiCreditBalance: user.ai_credit_balance,
      createdAt: user.created_at,
    },
  });
}

export default withErrorHandler(withAuth(handler));

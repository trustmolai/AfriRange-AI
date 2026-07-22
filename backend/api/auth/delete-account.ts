import { authenticateUser } from '../../lib/middleware';
import { query } from '../../lib/db';

/**
 * Serverless API Route: Account & Personal Data Deletion
 * Google Play User Data & Account Deletion Policy Compliance
 */
export default async function handler(req: any, res: any) {
  if (req.method !== 'DELETE') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const authUser = await authenticateUser(req, res);
  if (!authUser) return;

  try {
    const userId = authUser.id;

    // Delete user record from Neon DB (cascade deletes farms, paddocks, subscriptions, etc.)
    await query(`DELETE FROM users WHERE id = $1`, [userId]);

    console.log(`[Account Deletion] Deleted user account and personal data for User ID: ${userId}`);

    return res.status(200).json({
      success: true,
      message: 'Account and personal data have been permanently deleted in compliance with Google Play User Data Policy.',
    });
  } catch (err: any) {
    console.error('[Account Deletion Error]', err);
    return res.status(500).json({ success: false, error: err.message });
  }
}

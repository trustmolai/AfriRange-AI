import { authenticateUser } from '../../lib/middleware';
import { query } from '../../lib/db';

export default async function handler(req: any, res: any) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const authUser = await authenticateUser(req, res);
  if (!authUser) return;

  try {
    const resLedger = await query(
      `SELECT id, transaction_type as "transactionType", credits_added as "creditsAdded", 
              credits_used as "creditsUsed", balance_after as "balanceAfter", 
              reference_id as "referenceId", description, created_at as "createdAt"
       FROM ai_credit_transactions
       WHERE user_id = $1
       ORDER BY created_at DESC LIMIT 50`,
      [authUser.id]
    );

    return res.status(200).json({ success: true, history: resLedger.rows });
  } catch (err: any) {
    return res.status(500).json({ success: false, error: err.message });
  }
}

import { authenticateUser } from '../../lib/middleware';
import { query } from '../../lib/db';

export default async function handler(req: any, res: any) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const authUser = await authenticateUser(req, res);
  if (!authUser) return;

  try {
    const historyRes = await query(
      `SELECT id, payment_provider as "paymentProvider", amount, currency, status, 
              transaction_reference as "transactionReference", created_at as "createdAt"
       FROM payment_records
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [authUser.id]
    );

    return res.status(200).json({ success: true, history: historyRes.rows });
  } catch (err: any) {
    return res.status(500).json({ success: false, error: err.message });
  }
}

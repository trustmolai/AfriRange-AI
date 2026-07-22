import { authenticateUser } from '../../lib/middleware';
import { query } from '../../lib/db';

export default async function handler(req: any, res: any) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const authUser = await authenticateUser(req, res);
  if (!authUser) return;

  try {
    const userRes = await query(`SELECT ai_credit_balance FROM users WHERE id = $1`, [authUser.id]);
    const balance = userRes.rows[0]?.ai_credit_balance ?? 10;
    return res.status(200).json({ success: true, balance });
  } catch (err: any) {
    return res.status(500).json({ success: false, error: err.message });
  }
}

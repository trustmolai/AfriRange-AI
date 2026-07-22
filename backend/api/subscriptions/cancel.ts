import { authenticateUser } from '../../lib/middleware';
import { BillingService } from '../../lib/billing-service';

export default async function handler(req: any, res: any) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const authUser = await authenticateUser(req, res);
  if (!authUser) return;

  try {
    await BillingService.cancelSubscription(authUser.id);
    return res.status(200).json({ success: true, message: 'Subscription auto-renew cancelled successfully.' });
  } catch (err: any) {
    return res.status(500).json({ success: false, error: err.message });
  }
}

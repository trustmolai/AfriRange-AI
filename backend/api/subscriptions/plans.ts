import { query } from '../../../lib/db';
import { BillingService } from '../../../lib/billing-service';

export default async function handler(req: any, res: any) {
  if (req.method === 'GET') {
    try {
      const plans = await BillingService.getSubscriptionPlans();
      return res.status(200).json({ success: true, plans });
    } catch (err: any) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}

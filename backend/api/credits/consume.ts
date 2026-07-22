import { authenticateUser } from '../../lib/middleware';
import { BillingService } from '../../lib/billing-service';

export default async function handler(req: any, res: any) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const authUser = await authenticateUser(req, res);
  if (!authUser) return;

  const { amount = 1, featureTag = 'AI Request' } = req.body || {};

  try {
    const result = await BillingService.consumeCredits(authUser.id, amount, featureTag);
    if (!result.success) {
      return res.status(402).json({
        success: false,
        message: result.message,
        remaining: result.remaining,
      });
    }

    return res.status(200).json({
      success: true,
      remaining: result.remaining,
      message: result.message,
    });
  } catch (err: any) {
    return res.status(500).json({ success: false, error: err.message });
  }
}

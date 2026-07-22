import { authenticateUser } from '../../lib/middleware';
import { BillingService } from '../../lib/billing-service';

export default async function handler(req: any, res: any) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const authUser = await authenticateUser(req, res);
  if (!authUser) return;

  const { productId, purchaseToken, isCreditPack } = req.body || {};
  if (!productId || !purchaseToken) {
    return res.status(400).json({ error: 'productId and purchaseToken are required.' });
  }

  try {
    const result = await BillingService.verifyGooglePlayPurchase(
      authUser.id,
      productId,
      purchaseToken,
      Boolean(isCreditPack)
    );

    if (!result.success) {
      return res.status(400).json({ success: false, message: result.message });
    }

    return res.status(200).json({
      success: true,
      message: result.message,
      balance: result.balance,
    });
  } catch (err: any) {
    return res.status(500).json({ success: false, error: err.message });
  }
}

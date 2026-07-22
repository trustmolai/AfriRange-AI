import crypto from 'crypto';
import { query } from '../../lib/db';

/**
 * Serverless API Route: External Paystack Webhook Handler
 * STRICTLY for enterprise, NGO, government, and website B2B payments.
 * NOT for in-app digital purchases (Google Play Billing Policy Compliance).
 */
export default async function handler(req: any, res: any) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const paystackSecret = process.env.PAYSTACK_SECRET_KEY;
  if (!paystackSecret) {
    console.warn('[Paystack Webhook] PAYSTACK_SECRET_KEY missing.');
  }

  const signature = req.headers['x-paystack-signature'];
  if (paystackSecret && signature) {
    const hash = crypto
      .createHmac('sha512', paystackSecret)
      .update(JSON.stringify(req.body))
      .digest('hex');

    if (hash !== signature) {
      return res.status(401).json({ error: 'Invalid Paystack webhook signature' });
    }
  }

  const event = req.body;
  if (event?.event === 'charge.success') {
    const data = event.data;
    const email = data.customer?.email;
    const amount = data.amount / 100; // convert kobo to main currency
    const reference = data.reference;

    console.log(`[Paystack B2B Webhook] Payment received from ${email}, Ref: ${reference}, Amount: ${amount}`);

    // Map customer email to B2B enterprise user
    const userRes = await query(`SELECT id FROM users WHERE email = $1`, [email]);
    if (userRes.rows.length > 0) {
      const userId = userRes.rows[0].id;
      await query(
        `INSERT INTO payment_records (user_id, payment_provider, amount, currency, status, transaction_reference, metadata)
         VALUES ($1, 'paystack_external', $2, $3, 'completed', $4, $5)`,
        [userId, amount, data.currency || 'USD', reference, JSON.stringify(data)]
      );
    }
  }

  return res.status(200).json({ status: 'success' });
}

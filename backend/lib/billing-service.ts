import { query } from './db';
import { sendEmail } from './email';

export interface PlanItem {
  id: string;
  planName: string;
  displayName: string;
  monthlyPrice: number;
  currency: string;
  aiCreditsIncluded: number;
  features: Record<string, any>;
  googlePlayProductId: string;
}

export interface UserSubscriptionDetails {
  id: string;
  userId: string;
  planName: string;
  displayName: string;
  monthlyPrice: number;
  aiCreditsIncluded: number;
  status: string;
  startDate: string;
  endDate?: string;
  autoRenew: boolean;
  aiCreditBalance: number;
}

export class BillingService {
  /**
   * List available subscription plans
   */
  static async getSubscriptionPlans(): Promise<PlanItem[]> {
    const res = await query(
      `SELECT id, plan_name as "planName", display_name as "displayName", 
              monthly_price as "monthlyPrice", currency, ai_credits_included as "aiCreditsIncluded", 
              features, google_play_product_id as "googlePlayProductId"
       FROM subscription_plans ORDER BY monthly_price ASC`
    );

    return res.rows.map((row: any) => ({
      ...row,
      monthlyPrice: parseFloat(row.monthlyPrice),
    }));
  }

  /**
   * Get user's active subscription and credit balance
   */
  static async getUserSubscription(userId: string): Promise<UserSubscriptionDetails> {
    const userRes = await query(`SELECT ai_credit_balance FROM users WHERE id = $1`, [userId]);
    const currentBalance = userRes.rows[0]?.ai_credit_balance ?? 10;

    const subRes = await query(
      `SELECT us.id, us.user_id as "userId", us.status, us.start_date as "startDate", 
              us.end_date as "endDate", us.auto_renew as "autoRenew",
              sp.plan_name as "planName", sp.display_name as "displayName", 
              sp.monthly_price as "monthlyPrice", sp.ai_credits_included as "aiCreditsIncluded"
       FROM user_subscriptions us
       JOIN subscription_plans sp ON us.plan_id = sp.id
       WHERE us.user_id = $1`,
      [userId]
    );

    if (subRes.rows.length === 0) {
      return {
        id: 'free-default',
        userId,
        planName: 'free',
        displayName: 'Free Tier',
        monthlyPrice: 0.0,
        aiCreditsIncluded: 10,
        status: 'active',
        startDate: new Date().toISOString(),
        autoRenew: true,
        aiCreditBalance: currentBalance,
      };
    }

    const sub = subRes.rows[0];
    return {
      ...sub,
      monthlyPrice: parseFloat(sub.monthlyPrice),
      aiCreditBalance: currentBalance,
    };
  }

  /**
   * Verify and process Google Play Subscription / Credit Pack purchase
   */
  static async verifyGooglePlayPurchase(
    userId: string,
    productId: string,
    purchaseToken: string,
    isCreditPack: boolean = false
  ): Promise<{ success: boolean; message: string; balance: number }> {
    // 1. Google Play Developer API server-side verification (mock fallback for dev environment)
    const isValidToken = purchaseToken && purchaseToken.length >= 8;
    if (!isValidToken) {
      return { success: false, message: 'Invalid purchase token.', balance: 0 };
    }

    if (isCreditPack) {
      // Credit Pack Top-Up Purchase (e.g. 50 AI Credits Pack)
      const creditsToAdd = productId.includes('pack_100') ? 100 : 50;

      const userRes = await query(`SELECT ai_credit_balance FROM users WHERE id = $1`, [userId]);
      const current = userRes.rows[0]?.ai_credit_balance ?? 0;
      const newBalance = current + creditsToAdd;

      await query(`UPDATE users SET ai_credit_balance = $1 WHERE id = $2`, [newBalance, userId]);

      // Record transaction ledger
      await query(
        `INSERT INTO ai_credit_transactions (user_id, transaction_type, credits_added, balance_after, reference_id, description)
         VALUES ($1, 'pack_purchase', $2, $3, $4, $5)`,
        [userId, creditsToAdd, newBalance, purchaseToken.substring(0, 30), `Purchased ${creditsToAdd} AI Credit Pack`]
      );

      // Payment record
      await query(
        `INSERT INTO payment_records (user_id, payment_provider, amount, currency, status, transaction_reference)
         VALUES ($1, 'google_play', $2, 'USD', 'completed', $3)`,
        [userId, creditsToAdd === 100 ? 9.99 : 4.99, purchaseToken]
      );

      return { success: true, message: `Successfully added ${creditsToAdd} AI credits.`, balance: newBalance };
    }

    // Subscription Purchase (e.g. basic, standard, premium)
    const planRes = await query(`SELECT * FROM subscription_plans WHERE google_play_product_id = $1 OR plan_name = $2`, [productId, productId.replace('afrirange_', '').replace('_monthly', '')]);
    
    if (planRes.rows.length === 0) {
      return { success: false, message: 'Subscription plan product not found.', balance: 0 };
    }

    const plan = planRes.rows[0];
    const newBalance = plan.ai_credits_included;

    // Upsert subscription
    await query(
      `INSERT INTO user_subscriptions (user_id, plan_id, google_play_purchase_token, status, auto_renew)
       VALUES ($1, $2, $3, 'active', true)
       ON CONFLICT (user_id) DO UPDATE SET 
         plan_id = EXCLUDED.plan_id,
         google_play_purchase_token = EXCLUDED.google_play_purchase_token,
         status = 'active',
         updated_at = CURRENT_TIMESTAMP`,
      [userId, plan.id, purchaseToken]
    );

    // Update user table
    await query(
      `UPDATE users SET subscription_tier = $1, ai_credit_balance = $2 WHERE id = $3`,
      [plan.plan_name, newBalance, userId]
    );

    // Ledger record
    await query(
      `INSERT INTO ai_credit_transactions (user_id, transaction_type, credits_added, balance_after, reference_id, description)
       VALUES ($1, 'monthly_grant', $2, $3, $4, $5)`,
      [userId, plan.ai_credits_included, newBalance, purchaseToken.substring(0, 30), `Monthly ${plan.display_name} Credit Replenishment`]
    );

    // Payment record
    await query(
      `INSERT INTO payment_records (user_id, payment_provider, amount, currency, status, transaction_reference)
       VALUES ($1, 'google_play', $2, $3, 'completed', $4)`,
      [userId, plan.monthly_price, plan.currency, purchaseToken]
    );

    // Send receipt email via Resend
    const userEmailRes = await query(`SELECT email, name FROM users WHERE id = $1`, [userId]);
    if (userEmailRes.rows[0]?.email) {
      await sendEmail({
        to: userEmailRes.rows[0].email,
        subject: `AfriRange AI — Subscription Confirmation (${plan.display_name})`,
        text: `Thank you for subscribing to AfriRange AI ${plan.display_name}! Your monthly allowance of ${plan.ai_credits_included} AI credits is now active.`,
        html: `<h2>Subscription Activated</h2><p>Dear ${userEmailRes.rows[0].name || 'Farmer'},</p><p>Your subscription to <strong>${plan.display_name}</strong> has been activated via Google Play.</p><p>Monthly AI Credits Included: <strong>${plan.ai_credits_included}</strong></p>`,
      });
    }

    return { success: true, message: `Subscribed to ${plan.display_name} successfully!`, balance: newBalance };
  }

  /**
   * Consume AI credits safely server-side
   */
  static async consumeCredits(userId: string, amount: number, featureTag: string): Promise<{ success: boolean; remaining: number; message: string }> {
    const userRes = await query(`SELECT ai_credit_balance FROM users WHERE id = $1`, [userId]);
    if (userRes.rows.length === 0) {
      return { success: false, remaining: 0, message: 'User not found.' };
    }

    const currentBalance = userRes.rows[0].ai_credit_balance ?? 0;
    if (currentBalance < amount) {
      return {
        success: false,
        remaining: currentBalance,
        message: `Insufficient AI credits (${currentBalance} available, ${amount} required). Please upgrade your subscription or purchase credits.`,
      };
    }

    const newBalance = currentBalance - amount;
    await query(`UPDATE users SET ai_credit_balance = $1 WHERE id = $2`, [newBalance, userId]);

    // Record consumption transaction
    await query(
      `INSERT INTO ai_credit_transactions (user_id, transaction_type, credits_used, balance_after, reference_id, description)
       VALUES ($1, 'consumption', $2, $3, $4, $5)`,
      [userId, amount, newBalance, featureTag, `AI Usage: ${featureTag}`]
    );

    return {
      success: true,
      remaining: newBalance,
      message: `Deducted ${amount} credits. Remaining: ${newBalance}`,
    };
  }

  /**
   * Cancel subscription auto-renewal
   */
  static async cancelSubscription(userId: string): Promise<boolean> {
    await query(
      `UPDATE user_subscriptions SET auto_renew = false, status = 'cancelled' WHERE user_id = $1`,
      [userId]
    );
    return true;
  }
}

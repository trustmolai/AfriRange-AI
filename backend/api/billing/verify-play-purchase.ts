import { query } from '../../lib/db';

export interface PlayVerifyRequest {
  user_id: string;
  package_name: string;
  subscription_id: string; // e.g. 'afrirange_pro_monthly', 'afrirange_pro_yearly'
  purchase_token: string;
}

export interface PlayVerifyResponse {
  success: boolean;
  subscription_status: string;
  ai_credit_balance: number;
  message: string;
}

/**
 * Serverless API Route: Validate Google Play In-App Subscription Token
 */
export async function verifyGooglePlaySubscription(
  req: PlayVerifyRequest
): Promise<PlayVerifyResponse> {
  const { user_id, subscription_id, purchase_token } = req;

  // In production, invoke Google Play Developer API (androidpublisher v3) using Service Account
  // https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}

  console.log(`[Google Play Verification] Validating token for user ${user_id}, SKU: ${subscription_id}`);

  // Mock verification validation for testing/dev:
  const isValid = purchase_token && purchase_token.length > 10;

  if (!isValid) {
    return {
      success: false,
      subscription_status: 'invalid',
      ai_credit_balance: 5,
      message: 'Invalid or expired Google Play purchase token.',
    };
  }

  // Update Neon DB user record with Pro Tier status & unlocked AI credits
  await query(
    `UPDATE users 
     SET subscription_tier = 'pro',
         subscription_status = 'active',
         google_play_purchase_token = $1,
         google_play_subscription_id = $2,
         ai_credit_balance = 999, -- Unlimited for Pro tier
         updated_at = CURRENT_TIMESTAMP 
     WHERE id = $3`,
    [purchase_token, subscription_id, user_id]
  );

  return {
    success: true,
    subscription_status: 'active',
    ai_credit_balance: 999,
    message: 'Google Play subscription verified successfully. Pro Tier unlocked.',
  };
}

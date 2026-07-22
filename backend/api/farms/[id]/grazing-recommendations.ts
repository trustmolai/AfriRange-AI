import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET'])) return;

  const farmId = req.query.id as string;

  // Ownership check
  const farmCheck = await query(
    `SELECT id FROM farms WHERE id = $1 AND user_id = $2`,
    [farmId, req.user.userId]
  );

  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  const result = await query(
    `SELECT id, grazing_zone_id, recommendation_date, recommended_action,
            grazing_days_remaining, recommended_stocking_rate, rest_period_days,
            risk_level, ai_explanation, created_at
     FROM grazing_recommendations
     WHERE farm_id = $1
     ORDER BY recommendation_date DESC
     LIMIT 20`,
    [farmId]
  );

  return res.status(200).json({
    recommendations: result.rows.map(r => ({
      id: r.id,
      grazingZoneId: r.grazing_zone_id,
      recommendationDate: r.recommendation_date,
      recommendedAction: r.recommended_action,
      grazingDaysRemaining: r.grazing_days_remaining,
      recommendedStockingRate: r.recommended_stocking_rate ? parseFloat(r.recommended_stocking_rate) : null,
      restPeriodDays: r.rest_period_days,
      riskLevel: r.risk_level,
      aiExplanation: r.ai_explanation,
      createdAt: r.created_at,
    })),
  });
}

export default withErrorHandler(withAuth(handler));

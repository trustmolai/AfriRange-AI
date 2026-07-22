import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { generateGrazingRecommendation } from '../../../lib/grazing-engine';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['POST'])) return;

  const farmId = req.query.id as string;

  // Farm ownership check
  const farmCheck = await query(
    `SELECT id, name FROM farms WHERE id = $1 AND user_id = $2`,
    [farmId, req.user.userId]
  );

  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  // Gather actual livestock load from livestock_groups
  const lsuResult = await query(
    `SELECT COALESCE(SUM(total_lsu), 0) AS actual_lsu
     FROM livestock_groups
     WHERE farm_id = $1`,
    [farmId]
  );
  const actualLsu = parseFloat(lsuResult.rows[0].actual_lsu);

  // Gather recommended capacity from carrying_capacity_records
  const capResult = await query(
    `SELECT COALESCE(carrying_capacity_lsu, 0) AS recommended_lsu
     FROM carrying_capacity_records
     WHERE farm_id = $1
     ORDER BY created_at DESC LIMIT 1`,
    [farmId]
  );
  const recommendedLsu = capResult.rowCount > 0 ? parseFloat(capResult.rows[0].recommended_lsu) : actualLsu;

  try {
    const recommendation = await generateGrazingRecommendation(farmId, actualLsu, recommendedLsu);

    // Persist recommendation
    const insertResult = await query(
      `INSERT INTO grazing_recommendations 
         (farm_id, recommended_action, grazing_days_remaining, recommended_stocking_rate, rest_period_days, risk_level, ai_explanation)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, recommendation_date, created_at`,
      [
        farmId,
        recommendation.recommendedAction,
        recommendation.grazingDaysRemaining,
        recommendation.recommendedStockingRate,
        recommendation.restPeriodDays,
        recommendation.riskLevel,
        recommendation.explanation,
      ]
    );

    return res.status(200).json({
      message: 'Grazing recommendation generated successfully.',
      recommendation: {
        id: insertResult.rows[0].id,
        recommendationDate: insertResult.rows[0].recommendation_date,
        ...recommendation,
      },
    });
  } catch (error: any) {
    console.error('Grazing recommendation generation error:', error);
    return res.status(502).json({ error: 'ai_service_error', message: 'Failed to generate grazing recommendation. Please try again.' });
  }
}

export default withErrorHandler(withAuth(handler));

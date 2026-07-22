import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET'])) return;

  const farmId = req.query.id as string;
  const period = req.query.period ? parseInt(req.query.period as string) : null;

  // Farm ownership check
  const farmCheck = await query(
    `SELECT id FROM farms WHERE id = $1 AND user_id = $2`,
    [farmId, req.user.userId]
  );

  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  try {
    // Build query with optional period filter
    let queryStr = `
      SELECT id, forecast_date, forecast_period_days, drought_risk_level, drought_risk_score,
             rainfall_probability, forage_shortage_probability, water_stress_probability,
             heat_stress_probability, forage_days_remaining, spi_value, ani_value, ai_explanation,
             created_at
      FROM drought_forecasts
      WHERE farm_id = $1`;
    
    const params: any[] = [farmId];
    
    if (period) {
      queryStr += ` AND forecast_period_days = $${params.length + 1}`;
      params.push(period);
    }
    
    queryStr += ` ORDER BY forecast_date DESC, forecast_period_days ASC LIMIT 10`;

    const result = await query(queryStr, params);

    return res.status(200).json({
      forecasts: result.rows.map(row => ({
        id: row.id,
        forecastDate: row.forest_date,
        forecastPeriodDays: row.forecast_period_days,
        droughtRiskLevel: row.drought_risk_level,
        droughtRiskScore: parseFloat(row.drought_risk_score),
        rainfallProbability: parseFloat(row.rainfall_probability),
        forageShortageProbability: parseFloat(row.forage_shortage_probability),
        waterStressProbability: parseFloat(row.water_stress_probability),
        heatStressProbability: parseFloat(row.heat_stress_probability),
        forageDaysRemaining: row.forage_days_remaining,
        spiValue: row.spi_value ? parseFloat(row.spi_value) : null,
        aniValue: row.ani_value ? parseFloat(row.ani_value) : null,
        aiExplanation: row.ai_explanation,
        createdAt: row.created_at
      })),
      count: result.rows.length
    });
  } catch (error) {
    console.error('Error fetching drought forecasts:', error);
    return res.status(500).json({ error: 'internal_error', message: 'Failed to retrieve drought forecasts' });
  }
}

export default withErrorHandler(withAuth(handler));
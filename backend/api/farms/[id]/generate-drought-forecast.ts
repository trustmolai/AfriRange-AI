import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { generateDroughtForecast } from '../../../lib/drought-engine';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['POST'])) return;

  const farmId = req.query.id as string;
  const periods: number[] = Array.isArray(req.body.periods) 
    ? req.body.periods.map(p => parseInt(p)) 
    : [30, 60, 90]; // Default periods

  // Validate periods
  const validPeriods = periods.filter(p => [30, 60, 90].includes(p));
  if (validPeriods.length === 0) {
    return res.status(400).json({ error: 'invalid_periods', message: 'Periods must be 30, 60, or 90 days' });
  }

  // Farm ownership check
  const farmCheck = await query(
    `SELECT id FROM farms WHERE id = $1 AND user_id = $2`,
    [farmId, req.user.userId]
  );

  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  try {
    // Generate forecasts for each requested period
    const forecasts = await Promise.all(
      validPeriods.map(period => generateDroughtForecast(farmId, period))
    );

    // Store all forecasts in database
    const storedForecasts = await Promise.all(
      forecasts.map(forecast => 
        query(
          `INSERT INTO drought_forecasts 
             (farm_id, forecast_date, forecast_period_days, drought_risk_level, drought_risk_score,
              rainfall_probability, forage_shortage_probability, water_stress_probability,
              heat_stress_probability, forage_days_remaining, spi_value, ani_value, ai_explanation)
           VALUES ($1, CURRENT_DATE, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
           RETURNING id, forecast_date, created_at`,
          [
            farmId,
            forecast.forecastPeriodDays,
            forecast.droughtRiskLevel,
            forecast.droughtRiskScore,
            forecast.rainfallProbability,
            forageShortProbability,
            waterStressProbability,
            heatStressProbability,
            forageDaysRemaining,
            forecast.spiValue,
            forecast.aniValue,
            forecast.aiExplanation
          ]
        )
      )
    );

    return res.status(200).json({
      message: `Drought forecasts generated successfully for periods: ${validPeriods.join(', ')} days`,
      farmId,
      forecasts: forecasts.map((forecast, index) => ({
        id: storedForecasts[index].rows[0].id,
        forecastDate: storedForecasts[index].rows[0].forecast_date,
        forecastPeriodDays: forecast.forecastPeriodDays,
        droughtRiskLevel: forecast.droughtRiskLevel,
        droughtRiskScore: forecast.droughtRiskScore,
        rainfallProbability: forecast.rainfallProbability,
        forageShortageProbability: forecast.forageShortProbability,
        waterStressProbability: forecast.waterStressProbability,
        heatStressProbability: forecast.heatStressProbability,
        forageDaysRemaining: forecast.forageDaysRemaining,
        spiValue: forecast.spiValue,
        aniValue: forecast.aniValue,
        aiExplanation: forecast.aiExplanation,
        createdAt: storedForecasts[index].rows[0].created_at
      }))
    });
  } catch (error) {
    console.error('Error generating drought forecasts:', error);
    return res.status(500).json({ error: 'internal_error', message: 'Failed to generate drought forecasts' });
  }
}

export default withErrorHandler(withAuth(handler));
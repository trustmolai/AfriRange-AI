import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { calculateStockingRateRisk } from '../../../lib/carrying-capacity';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['POST'])) return;

  const farmId = req.query.id as string;

  // Farm ownership and area check
  const farmCheck = await query('SELECT total_area_ha FROM farms WHERE id = $1 AND user_id = $2', [farmId, req.user.userId]);
  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  const farmAreaHa = parseFloat(farmCheck.rows[0].total_area_ha);

  // 1. Calculate Actual LSU (Sum of all livestock groups on this farm)
  const actualLsuResult = await query(
    'SELECT SUM(lsu_value) AS total_lsu FROM livestock_groups WHERE farm_id = $1',
    [farmId]
  );
  const actualLsu = parseFloat(actualLsuResult.rows[0].total_lsu || '0.00');

  // 2. Fetch Latest Recommended Carrying Capacity LSU for this farm
  const latestRecResult = await query(
    `SELECT carrying_capacity_lsu FROM carrying_capacity_records 
     WHERE farm_id = $1 AND grazing_zone_id IS NULL
     ORDER BY calculated_at DESC LIMIT 1`,
    [farmId]
  );
  
  // Default to 0.2 LSU/ha if no calculated record exists yet
  const recommendedLsu = latestRecResult.rowCount > 0 
    ? parseFloat(latestRecResult.rows[0].carrying_capacity_lsu)
    : Math.round(farmAreaHa * 0.200 * 100) / 100;

  // 3. Compute Risk Level
  const calc = calculateStockingRateRisk(farmAreaHa, actualLsu, recommendedLsu);

  // 4. Save Stocking Rate Record
  const insertResult = await query(
    `INSERT INTO stocking_rate_records (farm_id, actual_lsu, recommended_lsu, stocking_rate_ha_per_lsu, grazing_pressure_pct, risk_level)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING id, actual_lsu, recommended_lsu, stocking_rate_ha_per_lsu, grazing_pressure_pct, risk_level, calculated_at`,
    [farmId, actualLsu, recommendedLsu, calc.stockingRateHaPerLsu, calc.grazingPressurePct, calc.riskLevel]
  );

  const rec = insertResult.rows[0];

  return res.status(200).json({
    message: 'Stocking rate calculated successfully.',
    stockingRate: {
      id: rec.id,
      farmId,
      actualLsu: parseFloat(rec.actual_lsu),
      recommendedLsu: parseFloat(rec.recommended_lsu),
      stockingRateHaPerLsu: parseFloat(rec.stocking_rate_ha_per_lsu),
      grazingPressurePct: parseFloat(rec.grazing_pressure_pct),
      riskLevel: rec.risk_level,
      recommendation: calc.recommendation,
      calculatedAt: rec.calculated_at,
    },
  });
}

export default withErrorHandler(withAuth(handler);

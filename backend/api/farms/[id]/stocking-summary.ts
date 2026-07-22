import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { calculateStockingRateRisk } from '../../../lib/carrying-capacity';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET'])) return;

  const farmId = req.query.id as string;

  // Farm ownership check
  const farmCheck = await query('SELECT total_area_ha FROM farms WHERE id = $1 AND user_id = $2', [farmId, req.user.userId]);
  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  const farmAreaHa = parseFloat(farmCheck.rows[0].total_area_ha);

  // 1. Total Current LSU
  const actualLsuResult = await query(
    'SELECT SUM(lsu_value) AS total_lsu, SUM(tlu_value) AS total_tlu FROM livestock_groups WHERE farm_id = $1',
    [farmId]
  );
  const actualLsu = parseFloat(actualLsuResult.rows[0].total_lsu || '0.00');
  const actualTlu = parseFloat(actualLsuResult.rows[0].total_tlu || '0.00');

  // 2. Recommended Carrying Capacity
  const latestRecResult = await query(
    `SELECT carrying_capacity_lsu, carrying_capacity_tlu FROM carrying_capacity_records 
     WHERE farm_id = $1 AND grazing_zone_id IS NULL
     ORDER BY calculated_at DESC LIMIT 1`,
    [farmId]
  );

  const recommendedLsu = latestRecResult.rowCount > 0
    ? parseFloat(latestRecResult.rows[0].carrying_capacity_lsu)
    : Math.round(farmAreaHa * 0.200 * 100) / 100;

  const recommendedTlu = latestRecResult.rowCount > 0
    ? parseFloat(latestRecResult.rows[0].carrying_capacity_tlu)
    : Math.round(farmAreaHa * 0.280 * 100) / 100;

  // 3. Compute Risk Level
  const calc = calculateStockingRateRisk(farmAreaHa, actualLsu, recommendedLsu);

  // 4. Paddock status distribution count
  const paddocksResult = await query(
    `SELECT current_status, COUNT(*)::int AS count 
     FROM paddocks 
     WHERE farm_id = $1 
     GROUP BY current_status`,
    [farmId]
  );

  return res.status(200).json({
    farmId,
    totalAreaHa: farmAreaHa,
    actualLsu,
    actualTlu,
    recommendedLsu,
    recommendedTlu,
    stockingRateHaPerLsu: calc.stockingRateHaPerLsu,
    grazingPressurePct: calc.grazingPressurePct,
    riskLevel: calc.riskLevel,
    recommendation: calc.recommendation,
    paddockSummary: paddocksResult.rows.reduce((acc, r) => {
      acc[r.current_status] = r.count;
      return acc;
    }, {} as Record<string, number>),
  });
}

export default withErrorHandler(withAuth(handler));

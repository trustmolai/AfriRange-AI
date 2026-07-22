import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { calculateCarryingCapacityLsu } from '../../../lib/carrying-capacity';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['POST'])) return;

  const farmId = req.query.id as string;
  const { biomassKgPerHa, utilizationPct, grazingZoneId } = req.body || {};

  // Farm ownership check
  const farmCheck = await query('SELECT total_area_ha FROM farms WHERE id = $1 AND user_id = $2', [farmId, req.user.userId]);
  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  const farmAreaHa = parseFloat(farmCheck.rows[0].total_area_ha);
  let targetAreaHa = farmAreaHa;

  if (grazingZoneId) {
    const zoneCheck = await query('SELECT area_ha FROM paddocks WHERE id = $1 AND farm_id = $2', [grazingZoneId, farmId]);
    if (zoneCheck.rowCount > 0) {
      targetAreaHa = parseFloat(zoneCheck.rows[0].area_ha);
    }
  }

  const biomass = biomassKgPerHa ? parseFloat(biomassKgPerHa) : 2500.0;
  const utilization = utilizationPct ? parseFloat(utilizationPct) : 40.0;

  const capacityLsu = calculateCarryingCapacityLsu(targetAreaHa, biomass, utilization);
  const capacityTlu = Math.round(capacityLsu * 1.4 * 100) / 100;
  const totalAvailableForageKg = targetAreaHa * biomass;

  // Insert Record
  const insertResult = await query(
    `INSERT INTO carrying_capacity_records (farm_id, grazing_zone_id, total_area_ha, available_forage_kg_dm, sustainable_utilization_pct, carrying_capacity_lsu, carrying_capacity_tlu)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING id, total_area_ha, available_forage_kg_dm, sustainable_utilization_pct, carrying_capacity_lsu, carrying_capacity_tlu, calculated_at`,
    [farmId, grazingZoneId || null, targetAreaHa, totalAvailableForageKg, utilization, capacityLsu, capacityTlu]
  );

  const rec = insertResult.rows[0];

  return res.status(200).json({
    message: 'Carrying capacity calculated successfully.',
    carryingCapacity: {
      id: rec.id,
      farmId,
      grazingZoneId: grazingZoneId || null,
      totalAreaHa: parseFloat(rec.total_area_ha),
      availableForageKgDm: parseFloat(rec.available_forage_kg_dm),
      sustainableUtilizationPct: parseFloat(rec.sustainable_utilization_pct),
      carryingCapacityLsu: parseFloat(rec.carrying_capacity_lsu),
      carryingCapacityTlu: parseFloat(rec.carrying_capacity_tlu),
      calculatedAt: rec.calculated_at,
    },
  });
}

export default withErrorHandler(withAuth(handler));

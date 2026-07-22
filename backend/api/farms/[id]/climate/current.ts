import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { ClimateService } from '../../../lib/climate-service';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET'])) return;

  const farmId = req.query.id as string;

  // Farm ownership check
  const farmCheck = await query(
    `SELECT id FROM farms WHERE id = $1 AND user_id = $2`,
    [farmId, req.user.userId]
  );

  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  try {
    // Get current climate snapshot
    const currentClimate = await ClimateService.getCurrentClimate(farmId);
    
    return res.status(200).json({
      farmId,
      observationDate: currentClimate.observationDate,
      rainfallMm: currentClimate.rainfallMm,
      temperatureC: currentClimate.temperatureC,
      humidityPercentage: currentClimate.humidityPercentage,
      evapotranspirationMm: currentClimate.evapotranspirationMm,
      dataSource: currentClimate.dataSource,
      soilMoisture: currentClimate.soilMoisture
    });
  } catch (error) {
    console.error('Error fetching current climate:', error);
    return res.status(500).json({ error: 'internal_error', message: 'Failed to retrieve climate data' });
  }
}

export default withErrorHandler(withAuth(handler));
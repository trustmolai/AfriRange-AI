import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { ClimateService } from '../../../lib/climate-service';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['POST'])) return;

  const farmId = req.query.id as string;
  const months = parseInt(req.body.months as string) || 1; // Default to 1 month refresh

  // Farm ownership check
  const farmCheck = await query(
    `SELECT id FROM farms WHERE id = $1 AND user_id = $2`,
    [farmId, req.user.userId]
  );

  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  try {
    // Generate fresh climate data (in production, this would call external APIs)
    const newClimateData = await ClimateService.getClimateHistory(farmId, months);
    
    // Store the new data in database
    const storedCount = await Promise.all(
      newClimateData.map(record => 
        ClimateService.storeClimateObservation(farmId, {
          observationDate: record.observationDate,
          rainfallMm: record.rainfallMm,
          temperatureC: record.temperatureC,
          humidityPercentage: record.humidityPercentage,
          evapotranspirationMm: record.evapotranspirationMm,
          dataSource: record.dataSource
        })
      )
    );

    return res.status(200).json({
      message: `Climate data refreshed successfully for the last ${months} month(s)`,
      farmId,
      recordsUpdated: newClimateData.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error refreshing climate data:', error);
    return res.status(500).json({ error: 'internal_error', message: 'Failed to refresh climate data' });
  }
}

export default withErrorHandler(withAuth(handler));
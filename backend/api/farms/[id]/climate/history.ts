import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { ClimateService } from '../../../lib/climate-service';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET'])) return;

  const farmId = req.query.id as string;
  const limit = parseInt(req.query.limit as string) || 12; // Default to 12 months

  // Farm ownership check
  const farmCheck = await query(
    `SELECT id FROM farms WHERE id = $1 AND user_id = $2`,
    [farmId, req.user.userId]
  );

  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  try {
    // Get climate history
    const climateHistory = await ClimateService.getClimateHistory(farmId, limit);
    
    // Format for API response
    const formattedHistory = climateHistory.map(record => ({
      observationDate: record.observationDate,
      rainfallMm: record.rainfallMm,
      temperatureC: record.temperatureC,
      humidityPercentage: record.humidityPercentage,
      evapotranspirationMm: record.evapotranspirationMm,
      dataSource: record.dataSource
    }));

    return res.status(200).json({
      farmId,
      history: formattedHistory,
      count: formattedHistory.length
    });
  } catch (error) {
    console.error('Error fetching climate history:', error);
    return res.status(500).json({ error: 'internal_error', message: 'Failed to retrieve climate history' });
  }
}

export default withErrorHandler(withAuth(handler));
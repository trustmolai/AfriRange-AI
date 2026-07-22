import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET'])) return;

  const farmId = req.query.id as string;
  const unacknowledgedOnly = req.query.unacknowledged === 'true';

  // Farm ownership check
  const farmCheck = await query(
    `SELECT id FROM farms WHERE id = $1 AND user_id = $2`,
    [farmId, req.user.userId]
  );

  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  try {
    // Build query with optional filter for unacknowledged alerts
    let queryStr = `
      SELECT id, alert_type, risk_level, title, message, recommended_action,
             created_at, acknowledged_at
      FROM climate_alerts
      WHERE farm_id = $1`;
    
    const params: any[] = [farmId];
    
    if (unacknowledgedOnly) {
      queryStr += ` AND acknowledged_at IS NULL`;
    }
    
    queryStr += ` ORDER BY created_at DESC LIMIT 50`;

    const result = await query(queryStr, params);

    return res.status(200).json({
      alerts: result.rows.map(alert => ({
        id: alert.id,
        alertType: alert.alert_type,
        riskLevel: alert.risk_level,
        title: alert.title,
        message: alert.message,
        recommendedAction: alert.recommended_action,
        createdAt: alert.created_at,
        acknowledgedAt: alert.acknowledged_at,
        isAcknowledged: !!alert.acknowledged_at
      })),
      count: result.rows.length,
      unacknowledgedCount: result.rows.filter(a => !a.acknowledged_at).length
    });
  } catch (error) {
    console.error('Error fetching alerts:', error);
    return res.status(500).json({ error: 'internal_error', message: 'Failed to retrieve alerts' });
  }
}

export default withErrorHandler(withAuth(handler));
import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['PUT'])) return;

  const alertId = req.params.id as string;

  try {
    // First, check if the alert exists and get its farm_id for ownership verification
    const alertCheck = await query(
      `SELECT ca.id, ca.farm_id, f.user_id
       FROM climate_alerts ca
       JOIN farms f ON ca.farm_id = f.id
       WHERE ca.id = $1`,
      [alertId]
    );

    if (alertCheck.rowCount === 0) {
      return res.status(404).json({ error: 'alert_not_found', message: 'Alert not found' });
    }

    const alert = alertCheck.rows[0];

    // Check ownership
    if (alert.user_id !== req.user.userId) {
      return res.status(403).json({ error: 'unauthorized', message: 'Not authorized to acknowledge this alert' });
    }

    // Check if already acknowledged
    if (alert.acknowledged_at) {
      return res.status(400).json({ error: 'already_acknowledged', message: 'Alert has already been acknowledged' });
    }

    // Acknowledge the alert
    const result = await query(
      `UPDATE climate_alerts
       SET acknowledged_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING id, acknowledged_at`,
      [alertId]
    );

    return res.status(200).json({
      message: 'Alert acknowledged successfully',
      alertId: result.rows[0].id,
      acknowledgedAt: result.rows[0].acknowledged_at
    });
  } catch (error) {
    console.error('Error acknowledging alert:', error);
    return res.status(500).json({ error: 'internal_error', message: 'Failed to acknowledge alert' });
  }
}

export default withErrorHandler(withAuth(handler));
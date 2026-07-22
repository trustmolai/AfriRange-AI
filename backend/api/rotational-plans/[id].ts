import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET', 'PUT', 'DELETE'])) return;

  const planId = req.query.id as string;

  // Verify plan ownership via farm
  const ownershipCheck = await query(
    `SELECT rp.id, rp.farm_id FROM rotational_grazing_plans rp
     JOIN farms f ON rp.farm_id = f.id
     WHERE rp.id = $1 AND f.user_id = $2`,
    [planId, req.user.userId]
  );

  if (ownershipCheck.rowCount === 0) {
    return res.status(404).json({ error: 'plan_not_found', message: 'Rotational plan not found or access denied.' });
  }

  // GET /api/rotational-plans/{id}
  if (req.method === 'GET') {
    const result = await query(
      `SELECT rp.id, rp.farm_id, rp.plan_name, rp.start_date, rp.end_date, rp.created_at, rp.updated_at
       FROM rotational_grazing_plans rp
       WHERE rp.id = $1`,
      [planId]
    );

    const plan = result.rows[0];

    // Fetch paddocks in sequence
    const paddocksResult = await query(
      `SELECT rpp.id, rpp.paddock_id, rpp.grazing_start_date, rpp.grazing_end_date, rpp.rest_days, rpp.sequence_order,
              p.name AS paddock_name, p.area_ha
       FROM rotational_plan_paddocks rpp
       JOIN paddocks p ON rpp.paddock_id = p.id
       WHERE rpp.plan_id = $1
       ORDER BY rpp.sequence_order`,
      [planId]
    );

    return res.status(200).json({
      rotationalPlan: {
        id: plan.id,
        farmId: plan.farm_id,
        planName: plan.plan_name,
        startDate: plan.start_date,
        endDate: plan.end_date,
        createdAt: plan.created_at,
        updatedAt: plan.updated_at,
        paddocks: paddocksResult.rows.map(p => ({
          id: p.id,
          paddockId: p.paddock_id,
          paddockName: p.paddock_name,
          areaHa: parseFloat(p.area_ha),
          grazingStartDate: p.grazing_start_date,
          grazingEndDate: p.grazing_end_date,
          restDays: p.rest_days,
          sequenceOrder: p.sequence_order,
        })),
      },
    });
  }

  // PUT /api/rotational-plans/{id}
  if (req.method === 'PUT') {
    const { planName, startDate, endDate, paddocks } = req.body || {};

    const updates: string[] = [];
    const params: any[] = [planId];
    let paramIndex = 2;

    if (planName) {
      updates.push(`plan_name = $${paramIndex++}`);
      params.push(planName);
    }
    if (startDate) {
      updates.push(`start_date = $${paramIndex++}`);
      params.push(startDate);
    }
    if (endDate) {
      updates.push(`end_date = $${paramIndex++}`);
      params.push(endDate);
    }

    if (updates.length > 0) {
      updates.push(`updated_at = CURRENT_TIMESTAMP`);
      await query(
        `UPDATE rotational_grazing_plans SET ${updates.join(', ')} WHERE id = $1`,
        params
      );
    }

    // Update paddocks if provided
    if (Array.isArray(paddocks)) {
      // Delete existing
      await query('DELETE FROM rotational_plan_paddocks WHERE plan_id = $1', [planId]);
      
      // Insert new
      for (let i = 0; i < paddocks.length; i++) {
        const p = paddocks[i];
        if (p.paddockId) {
          await query(
            `INSERT INTO rotational_plan_paddocks (plan_id, paddock_id, grazing_start_date, grazing_end_date, rest_days, sequence_order)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [planId, p.paddockId, p.grazingStartDate, p.grazingEndDate, p.restDays || 45, i + 1]
          );
        }
      }
    }

    return res.status(200).json({ message: 'Rotational plan updated successfully.' });
  }

  // DELETE /api/rotational-plans/{id}
  if (req.method === 'DELETE') {
    // Cascade delete will handle plan_paddocks due to FK
    await query('DELETE FROM rotational_grazing_plans WHERE id = $1', [planId]);
    return res.status(200).json({ message: 'Rotational plan deleted successfully.' });
  }
}

export default withErrorHandler(withAuth(handler));
import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  const farmId = req.query.id as string;

  // Farm ownership check
  const farmCheck = await query(
    `SELECT id FROM farms WHERE id = $1 AND user_id = $2`,
    [farmId, req.user.userId]
  );

  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  // GET /api/farms/{id}/rotational-plans
  if (req.method === 'GET') {
    const result = await query(
      `SELECT rp.id, rp.farm_id, rp.plan_name, rp.start_date, rp.end_date, rp.created_at, rp.updated_at,
              json_agg(
                json_build_object(
                  'paddockId', rpp.paddock_id,
                  'paddockName', p.name,
                  'grazingStartDate', rpp.grazing_start_date,
                  'grazingEndDate', rpp.grazing_end_date,
                  'restDays', rpp.rest_days,
                  'sequenceOrder', rpp.sequence_order
                ) ORDER BY rpp.sequence_order
              ) AS paddocks
       FROM rotational_grazing_plans rp
       LEFT JOIN rotational_plan_paddocks rpp ON rp.id = rpp.plan_id
       LEFT JOIN paddocks p ON rpp.paddock_id = p.id
       WHERE rp.farm_id = $1
       GROUP BY rp.id
       ORDER BY rp.start_date DESC`,
      [farmId]
    );

    return res.status(200).json({
      rotationalPlans: result.rows.map(r => ({
        id: r.id,
        farmId: r.farm_id,
        planName: r.plan_name,
        startDate: r.start_date,
        endDate: r.end_date,
        createdAt: r.created_at,
        updatedAt: r.updated_at,
        paddocks: r.paddocks?.[0]?.paddockid ? r.paddocks : [],
      })),
    });
  }

  // POST /api/farms/{id}/rotational-plans
  if (req.method === 'POST') {
    const { planName, startDate, endDate, paddocks } = req.body || {};

    if (!planName || !startDate || !endDate || !Array.isArray(paddocks) || paddocks.length === 0) {
      return res.status(400).json({ 
        error: 'missing_fields', 
        message: 'planName, startDate, endDate, and paddocks array are required.' 
      });
    }

    // Validate paddocks belong to farm
    const paddockIds = paddocks.map((p: any) => p.paddockId);
    const placeholders = paddockIds.map((_, i) => `$${i + 4}`).join(',');
    const validPaddocks = await query(
      `SELECT id FROM paddocks WHERE id IN (${placeholders}) AND farm_id = $1`,
      [farmId, ...paddockIds]
    );

    if (validPaddocks.rowCount !== paddockIds.length) {
      return res.status(400).json({ error: 'invalid_paddocks', message: 'One or more paddocks do not belong to this farm.' });
    }

    // Create plan
    const planResult = await query(
      `INSERT INTO rotational_grazing_plans (farm_id, plan_name, start_date, end_date)
       VALUES ($1, $2, $3, $4)
       RETURNING id, farm_id, plan_name, start_date, end_date, created_at, updated_at`,
      [farmId, planName, startDate, endDate]
    );

    const plan = planResult.rows[0];

    // Create plan paddocks with sequence
    for (let i = 0; i < paddocks.length; i++) {
      const p = paddocks[i];
      await query(
        `INSERT INTO rotational_plan_paddocks (plan_id, paddock_id, grazing_start_date, grazing_end_date, rest_days, sequence_order)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [plan.id, p.paddockId, p.grazingStartDate, p.grazingEndDate, p.restDays || 45, i + 1]
      );
    }

    return res.status(201).json({
      message: 'Rotational grazing plan created successfully.',
      rotationalPlan: {
        id: plan.id,
        farmId: plan.farm_id,
        planName: plan.plan_name,
        startDate: plan.start_date,
        endDate: plan.end_date,
        createdAt: plan.created_at,
        updatedAt: plan.updated_at,
        paddocks: paddocks.map((p: any, i: number) => ({
          paddockId: p.paddockId,
          grazingStartDate: p.grazingStartDate,
          grazingEndDate: p.grazingEndDate,
          restDays: p.restDays || 45,
          sequenceOrder: i + 1,
        })),
      },
    });
  }
}

export default withErrorHandler(withAuth(handler));
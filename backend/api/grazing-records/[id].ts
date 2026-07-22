import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['PUT', 'DELETE'])) return;

  const recordId = req.query.id as string;

  const check = await query(
    `SELECT gr.id FROM grazing_records gr
     JOIN paddocks p ON gr.grazing_zone_id = p.id
     JOIN farms f ON p.farm_id = f.id
     WHERE gr.id = $1 AND f.user_id = $2`,
    [recordId, req.user.userId]
  );

  if (check.rowCount === 0) {
    return res.status(404).json({ error: 'record_not_found', message: 'Grazing record not found or access denied.' });
  }

  // PUT /api/grazing-records/{id}
  if (req.method === 'PUT') {
    const { grazingEndDate, notes } = req.body || {};

    const existing = (await query('SELECT grazing_start_date FROM grazing_records WHERE id = $1', [recordId])).rows[0];
    let days: number | null = null;

    if (grazingEndDate) {
      const start = new Date(existing.grazing_start_date);
      const end = new Date(grazingEndDate);
      days = Math.max(1, Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)));
    }

    const updateResult = await query(
      `UPDATE grazing_records
       SET grazing_end_date = COALESCE($1, grazing_end_date),
           grazing_days = COALESCE($2, grazing_days),
           notes = COALESCE($3, notes)
       WHERE id = $4
       RETURNING id, grazing_zone_id, livestock_group_id, grazing_start_date, grazing_end_date, number_of_animals, lsu_grazing, grazing_days, notes`,
      [grazingEndDate, days, notes, recordId]
    );

    const updated = updateResult.rows[0];
    return res.status(200).json({
      message: 'Grazing record updated successfully.',
      grazingRecord: {
        id: updated.id,
        grazingZoneId: updated.grazing_zone_id,
        livestockGroupId: updated.livestock_group_id,
        grazingStartDate: updated.grazing_start_date,
        grazingEndDate: updated.grazing_end_date,
        numberOfAnimals: updated.number_of_animals,
        lsuGrazing: parseFloat(updated.lsu_grazing),
        grazingDays: updated.grazing_days,
        notes: updated.notes,
      },
    });
  }

  // DELETE /api/grazing-records/{id}
  if (req.method === 'DELETE') {
    await query('DELETE FROM grazing_records WHERE id = $1', [recordId]);
    return res.status(200).json({ message: 'Grazing record deleted successfully.' });
  }
}

export default withErrorHandler(withAuth(handler));

import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET', 'POST'])) return;

  const paddockId = req.query.id as string;

  // Ownership verification via paddock->farm->user
  const zoneCheck = await query(
    `SELECT p.id, p.farm_id FROM paddocks p 
     JOIN farms f ON p.farm_id = f.id 
     WHERE p.id = $1 AND f.user_id = $2`,
    [paddockId, req.user.userId]
  );

  if (zoneCheck.rowCount === 0) {
    return res.status(404).json({ error: 'zone_not_found', message: 'Grazing zone not found or access denied.' });
  }

  // GET /api/grazing-zones/{id}/grazing-records
  if (req.method === 'GET') {
    const result = await query(
      `SELECT gr.id, gr.grazing_zone_id, gr.livestock_group_id, gr.grazing_start_date, gr.grazing_end_date,
              gr.number_of_animals, gr.lsu_grazing, gr.grazing_days, gr.notes, gr.created_at,
              lg.name AS livestock_group_name, lg.species
       FROM grazing_records gr
       JOIN livestock_groups lg ON gr.livestock_group_id = lg.id
       WHERE gr.grazing_zone_id = $1
       ORDER BY gr.grazing_start_date DESC`,
      [paddockId]
    );

    return res.status(200).json({
      grazingRecords: result.rows.map(r => ({
        id: r.id,
        grazingZoneId: r.grazing_zone_id,
        livestockGroupId: r.livestock_group_id,
        livestockGroupName: r.livestock_group_name,
        species: r.species,
        grazingStartDate: r.grazing_start_date,
        grazingEndDate: r.grazing_end_date,
        numberOfAnimals: r.number_of_animals,
        lsuGrazing: parseFloat(r.lsu_grazing),
        grazingDays: r.grazing_days,
        notes: r.notes,
        createdAt: r.created_at,
      })),
    });
  }

  // POST /api/grazing-zones/{id}/grazing-records
  if (req.method === 'POST') {
    const { livestockGroupId, grazingStartDate, grazingEndDate, numberOfAnimals, notes } = req.body || {};

    if (!livestockGroupId || !grazingStartDate || !numberOfAnimals) {
      return res.status(400).json({ error: 'missing_fields', message: 'Livestock group, start date, and number of animals are required.' });
    }

    // Lookup group LSU factor
    const groupResult = await query('SELECT lsu_value, number_of_animals FROM livestock_groups WHERE id = $1', [livestockGroupId]);
    if (groupResult.rowCount === 0) {
      return res.status(404).json({ error: 'group_not_found', message: 'Livestock group not found.' });
    }

    const group = groupResult.rows[0];
    const count = parseInt(numberOfAnimals, 10);
    const perAnimalLsu = parseFloat(group.lsu_value) / Math.max(group.number_of_animals, 1);
    const totalLsuGrazing = Math.round(count * perAnimalLsu * 100) / 100;

    // Calculate grazing days if end date provided
    let days: number | null = null;
    if (grazingEndDate) {
      const start = new Date(grazingStartDate);
      const end = new Date(grazingEndDate);
      days = Math.max(1, Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)));
    }

    const insertResult = await query(
      `INSERT INTO grazing_records (grazing_zone_id, livestock_group_id, grazing_start_date, grazing_end_date, number_of_animals, lsu_grazing, grazing_days, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, grazing_zone_id, livestock_group_id, grazing_start_date, grazing_end_date, number_of_animals, lsu_grazing, grazing_days, notes, created_at`,
      [paddockId, livestockGroupId, grazingStartDate, grazingEndDate || null, count, totalLsuGrazing, days, notes || null]
    );

    // Update paddock status to 'grazing'
    await query("UPDATE paddocks SET current_status = 'grazing' WHERE id = $1", [paddockId]);

    const newRecord = insertResult.rows[0];

    return res.status(201).json({
      message: 'Grazing movement recorded successfully.',
      grazingRecord: {
        id: newRecord.id,
        grazingZoneId: newRecord.grazing_zone_id,
        livestockGroupId: newRecord.livestock_group_id,
        grazingStartDate: newRecord.grazing_start_date,
        grazingEndDate: newRecord.grazing_end_date,
        numberOfAnimals: newRecord.number_of_animals,
        lsuGrazing: parseFloat(newRecord.lsu_grazing),
        grazingDays: newRecord.grazing_days,
        notes: newRecord.notes,
        createdAt: newRecord.created_at,
      },
    });
  }
}

export default withErrorHandler(withAuth(handler));

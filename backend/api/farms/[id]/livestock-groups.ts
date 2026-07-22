import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { calculateGroupLsuTlu } from '../../../lib/carrying-capacity';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET', 'POST'])) return;

  const farmId = req.query.id as string;

  // Farm ownership check
  const farmCheck = await query('SELECT id FROM farms WHERE id = $1 AND user_id = $2', [farmId, req.user.userId]);
  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  // GET /api/farms/{id}/livestock-groups
  if (req.method === 'GET') {
    const result = await query(
      `SELECT id, farm_id, name, species, animal_class, number_of_animals, average_weight_kg,
              lsu_value, tlu_value, notes, created_at, updated_at
       FROM livestock_groups
       WHERE farm_id = $1
       ORDER BY created_at DESC`,
      [farmId]
    );

    return res.status(200).json({
      livestockGroups: result.rows.map(g => ({
        id: g.id,
        farmId: g.farm_id,
        name: g.name,
        species: g.species,
        animalClass: g.animal_class,
        numberOfAnimals: g.number_of_animals,
        averageWeightKg: g.average_weight_kg ? parseFloat(g.average_weight_kg) : null,
        lsuValue: parseFloat(g.lsu_value),
        tluValue: parseFloat(g.tlu_value),
        notes: g.notes,
        createdAt: g.created_at,
        updatedAt: g.updated_at,
      })),
    });
  }

  // POST /api/farms/{id}/livestock-groups
  if (req.method === 'POST') {
    const { name, species, animalClass, numberOfAnimals, averageWeightKg, notes } = req.body || {};

    if (!name || !species || !numberOfAnimals) {
      return res.status(400).json({ error: 'missing_fields', message: 'Name, species, and number of animals are required.' });
    }

    const count = parseInt(numberOfAnimals, 10);
    const { lsu, tlu } = calculateGroupLsuTlu(species, count);

    const insertResult = await query(
      `INSERT INTO livestock_groups (farm_id, name, species, animal_class, number_of_animals, average_weight_kg, lsu_value, tlu_value, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, farm_id, name, species, animal_class, number_of_animals, average_weight_kg, lsu_value, tlu_value, notes, created_at`,
      [farmId, name, species, animalClass || 'mature', count, averageWeightKg || null, lsu, tlu, notes || null]
    );

    const newGroup = insertResult.rows[0];

    // Audit log
    await query(
      `INSERT INTO livestock_audit_logs (user_id, farm_id, action, metadata)
       VALUES ($1, $2, 'create_group', $3)`,
      [req.user.userId, farmId, JSON.stringify({ groupId: newGroup.id, lsu, tlu })]
    );

    return res.status(201).json({
      message: 'Livestock group created successfully.',
      livestockGroup: {
        id: newGroup.id,
        farmId: newGroup.farm_id,
        name: newGroup.name,
        species: newGroup.species,
        animalClass: newGroup.animal_class,
        numberOfAnimals: newGroup.number_of_animals,
        averageWeightKg: newGroup.average_weight_kg ? parseFloat(newGroup.average_weight_kg) : null,
        lsuValue: parseFloat(newGroup.lsu_value),
        tluValue: parseFloat(newGroup.tlu_value),
        notes: newGroup.notes,
        createdAt: newGroup.created_at,
      },
    });
  }
}

export default withErrorHandler(withAuth(handler));

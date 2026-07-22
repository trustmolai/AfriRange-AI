import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { calculateGroupLsuTlu } from '../../../lib/carrying-capacity';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET', 'PUT', 'DELETE'])) return;

  const groupId = req.query.id as string;

  const ownershipCheck = await query(
    `SELECT lg.id, lg.farm_id FROM livestock_groups lg
     JOIN farms f ON lg.farm_id = f.id
     WHERE lg.id = $1 AND f.user_id = $2`,
    [groupId, req.user.userId]
  );

  if (ownershipCheck.rowCount === 0) {
    return res.status(404).json({ error: 'group_not_found', message: 'Livestock group not found or access denied.' });
  }

  // GET /api/livestock-groups/{id}
  if (req.method === 'GET') {
    const result = await query(
      `SELECT id, farm_id, name, species, animal_class, number_of_animals, average_weight_kg,
              lsu_value, tlu_value, notes, created_at, updated_at
       FROM livestock_groups WHERE id = $1`,
      [groupId]
    );

    const g = result.rows[0];
    return res.status(200).json({
      livestockGroup: {
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
      },
    });
  }

  // PUT /api/livestock-groups/{id}
  if (req.method === 'PUT') {
    const { name, species, animalClass, numberOfAnimals, averageWeightKg, notes } = req.body || {};

    const existingGroup = (await query('SELECT species, number_of_animals FROM livestock_groups WHERE id = $1', [groupId])).rows[0];
    const finalSpecies = species || existingGroup.species;
    const finalCount = numberOfAnimals ? parseInt(numberOfAnimals, 10) : existingGroup.number_of_animals;

    const { lsu, tlu } = calculateGroupLsuTlu(finalSpecies, finalCount);

    const updateResult = await query(
      `UPDATE livestock_groups
       SET name = COALESCE($1, name),
           species = COALESCE($2, species),
           animal_class = COALESCE($3, animal_class),
           number_of_animals = COALESCE($4, number_of_animals),
           average_weight_kg = COALESCE($5, average_weight_kg),
           lsu_value = $6,
           tlu_value = $7,
           notes = COALESCE($8, notes)
       WHERE id = $9
       RETURNING id, farm_id, name, species, animal_class, number_of_animals, average_weight_kg, lsu_value, tlu_value, notes`,
      [name, species, animalClass, numberOfAnimals, averageWeightKg, lsu, tlu, notes, groupId]
    );

    const updated = updateResult.rows[0];
    return res.status(200).json({
      message: 'Livestock group updated successfully.',
      livestockGroup: {
        id: updated.id,
        farmId: updated.farm_id,
        name: updated.name,
        species: updated.species,
        animalClass: updated.animal_class,
        numberOfAnimals: updated.number_of_animals,
        averageWeightKg: updated.average_weight_kg ? parseFloat(updated.average_weight_kg) : null,
        lsuValue: parseFloat(updated.lsu_value),
        tluValue: parseFloat(updated.tlu_value),
        notes: updated.notes,
      },
    });
  }

  // DELETE /api/livestock-groups/{id}
  if (req.method === 'DELETE') {
    await query('DELETE FROM livestock_groups WHERE id = $1', [groupId]);
    return res.status(200).json({ message: 'Livestock group deleted successfully.' });
  }
}

export default withErrorHandler(withAuth(handler));

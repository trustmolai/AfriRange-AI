import type { NextApiResponse } from 'next';
import { query } from '../../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET'])) return;

  const { id } = req.query;

  const result = await query(
    `SELECT id, scientific_name, common_name, local_names, family, plant_type,
            palatability_rating, grazing_value, nutritional_value, toxicity_level,
            toxicity_description, veld_indicator_value, invasive_status,
            bush_encroachment_status, management_recommendation, created_at
     FROM plant_species_catalog
     WHERE id = $1`,
    [id]
  );

  if (result.rowCount === 0) {
    return res.status(404).json({ error: 'species_not_found', message: 'Species not found in catalog.' });
  }

  const sp = result.rows[0];

  return res.status(200).json({
    species: {
      id: sp.id,
      scientificName: sp.scientific_name,
      commonName: sp.common_name,
      localNames: sp.local_names,
      family: sp.family,
      plantType: sp.plant_type,
      palatabilityRating: sp.palatability_rating,
      grazingValue: sp.grazing_value,
      nutritionalValue: sp.nutritional_value,
      toxicityLevel: sp.toxicity_level,
      toxicityDescription: sp.toxicity_description,
      veldIndicatorValue: sp.veld_indicator_value,
      invasiveStatus: sp.invasive_status,
      bushEncroachmentStatus: sp.bush_encroachment_status,
      managementRecommendation: sp.management_recommendation,
      createdAt: sp.created_at,
    },
  });
}

export default withErrorHandler(withAuth(handler));

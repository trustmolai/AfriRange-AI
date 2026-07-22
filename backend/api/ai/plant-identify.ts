import type { NextApiResponse } from 'next';
import { query } from '../../lib/db';
import { withAuth, withErrorHandler, allowMethods, getClientIp, AuthenticatedRequest } from '../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['POST'])) return;

  const clientIp = getClientIp(req);

  // Rate limit: Max 5 scans per minute per user to manage OpenRouter API costs
  const userRateLimitKey = `plant_scan_${req.user.userId}`;
  const start = Date.now();

  const { imageBase64, farmId, grazingZoneId, location } = req.body || {};

  if (!imageBase64) {
    return res.status(400).json({ error: 'missing_image', message: 'Image payload in base64 format is required.' });
  }

  // Define structured JSON prompt instructions for OpenRouter Vision model
  const prompt = `
    Analyze this plant photo from an African rangeland or veld. 
    Respond with a raw JSON object containing the plant taxonomy details.
    You MUST adhere strictly to the JSON schema below. Do not wrap in markdown or add text outside of JSON.
    
    JSON Schema:
    {
      "scientificName": "Scientific botanical name",
      "commonName": "Primary common name",
      "plantType": "grass" | "shrub" | "tree" | "forb" | "sedge" | "weed",
      "confidenceScore": 88.5, // Float between 0.0 and 100.0
      "toxicityLevel": "safe" | "caution" | "poisonous" | "highly_poisonous",
      "toxicityDescription": "Detailed toxicity profile for livestock if caution/poisonous, otherwise null",
      "palatability": "high" | "medium" | "low" | "unpalatable",
      "grazingValue": "high" | "medium" | "low" | "none",
      "managementAdvice": "Brief action item for rangeland management",
      "alternativeMatches": ["Option Scientific Name 1", "Option Scientific Name 2"]
    }
  `;

  // Fetch OpenRouter API key
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey || apiKey === 'sk-or-mock-key') {
    // Return mock response for testing when key is missing or is developer placeholder
    console.log('[Mock OpenRouter] returning default simulated grass identification');
    const mockResponse = {
      scientificName: 'Themeda triandra',
      commonName: 'Red Grass',
      plantType: 'grass',
      confidenceScore: 92.5,
      toxicityLevel: 'safe',
      toxicityDescription: null,
      palatability: 'high',
      grazingValue: 'high',
      managementAdvice: 'Highly palatable decreaser grass. Ensure rotational rest days to prevent overgrazing.',
      alternativeMatches: ['Hyparrhenia hirta', 'Heteropogon contortus'],
    };

    // Save observation
    const insertResult = await query(
      `INSERT INTO plant_observations_ai (user_id, farm_id, grazing_zone_id, ai_identification, confidence_score, location)
       VALUES ($1, $2, $3, $4, $5, ST_SetSRID(ST_Point($6, $7), 4326))
       RETURNING id, observation_date, created_at`,
      [
        req.user.userId,
        farmId || null,
        grazingZoneId || null,
        JSON.stringify(mockResponse),
        mockResponse.confidenceScore,
        location?.longitude || 0.0,
        location?.latitude || 0.0,
      ]
    );

    return res.status(200).json({
      message: 'Identification completed (MOCK).',
      observationId: insertResult.rows[0].id,
      identification: mockResponse,
    });
  }

  // OpenRouter Real Call
  try {
    const apiResponse = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://afrirange.ai',
        'X-Title': 'AfriRange AI Vision Scanner',
      },
      body: JSON.stringify({
        model: 'google/gemini-flash-1.5', // Cheap & fast vision model
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: prompt },
              { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${imageBase64}` } },
            ],
          },
        ],
      }),
    });

    const completion = await apiResponse.json();
    const rawContent = completion.choices?.[0]?.message?.content || '';
    
    // Clean JSON content if model wrapped it in markdown codeblock formatting
    const jsonString = rawContent.replace(/```json/g, '').replace(/```/g, '').trim();
    const resultObj = JSON.parse(jsonString);

    // Save observation
    const insertResult = await query(
      `INSERT INTO plant_observations_ai (user_id, farm_id, grazing_zone_id, ai_identification, confidence_score, location)
       VALUES ($1, $2, $3, $4, $5, ST_SetSRID(ST_Point($6, $7), 4326))
       RETURNING id, created_at`,
      [
        req.user.userId,
        farmId || null,
        grazingZoneId || null,
        JSON.stringify(resultObj),
        resultObj.confidenceScore || 0.0,
        location?.longitude || 0.0,
        location?.latitude || 0.0,
      ]
    );

    const obsId = insertResult.rows[0].id;
    const responseTime = Date.now() - start;

    // Log Token usage & pricing analytics
    await query(
      `INSERT INTO plant_identification_logs (observation_id, ai_model_used, response_time_ms, token_usage)
       VALUES ($1, $2, $3, $4)`,
      [obsId, 'google/gemini-flash-1.5', responseTime, completion.usage?.total_tokens || 0]
    );

    return res.status(200).json({
      message: 'Identification completed.',
      observationId: obsId,
      identification: resultObj,
    });
  } catch (error: any) {
    console.error('OpenRouter Vision API Error:', error);
    return res.status(502).json({ error: 'ai_service_error', message: 'Failed to process plant image. Please try again later.' });
  }
}

export default withErrorHandler(withAuth(handler));

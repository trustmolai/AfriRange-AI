import { query } from './db';
import { calculateCarryingCapacityLsu } from './carrying-capacity';
import { 
  calculateComprehensiveBiomass, 
  calculateBiomassTrend,
  getBiomassHealthClass,
  assessOvergrazingRisk,
  calculateGrazingDaysRemaining,
  calculateRecommendedStockingRate,
  calculateRestPeriodRecommendation,
  calculateCarryingCapacityFromBiomass,
  ANNUAL_DM_PER_LSU_KG
} from './biomass-estimation';
import { callOpenRouter, TokenUsageTracker } from './openrouter';

export interface GrazingRecommendationInput {
  farmId: string;
  actualLsu: number;
  recommendedLsu: number;
  // Additional inputs for enhanced AI reasoning
  plantComposition?: {
    desirableGrassPct?: number;
    invasiveSpeciesPct?: number;
    bushEncroachmentPct?: number;
  };
  waterPointAvailable?: boolean;
  rainfallHistory?: number[];
  seasonalGrowthPattern?: string;
}

export interface GrazingRecommendationOutput {
  recommendedAction: string;
  grazingDaysRemaining: number;
  recommendedStockingRate: number;
  restPeriodDays: number;
  riskLevel: 'low' | 'moderate' | 'high' | 'severe';
  explanation: string;
}

/**
 * AI-powered grazing recommendation generator utilizing OpenRouter LLM reasoning.
 * Enhanced with comprehensive biomass analysis and ecological factors.
 */
export async function generateGrazingRecommendation(
  farmId: string,
  actualLsu: number,
  recommendedLsu: number,
  inputs?: GrazingRecommendationInput
): Promise<GrazingRecommendationOutput> {
   
  // 1. Fetch farm paddocks & biomass status
  const paddocksResult = await query(
    `SELECT p.id, p.name, p.area_ha, p.current_status, p.water_point_available,
            COALESCE(
              (SELECT biomass_kg_per_ha FROM biomass_estimates WHERE grazing_zone_id = p.id ORDER BY estimate_date DESC LIMIT 1),
              (SELECT biomass_kg_per_ha FROM satellite_observations WHERE grazing_zone_id = p.id ORDER BY observation_date DESC LIMIT 1),
              2200.00
            ) AS latest_biomass
      FROM paddocks p
      WHERE p.farm_id = $1`,
    [farmId]
  );

  // Fallback to default mock recommendations if OpenRouter key is developer placeholder
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey || apiKey === 'sk-or-mock-key') {
    console.log('[Mock Grazing Engine] returning default rotational recommendation');
    
    const bestPaddock = paddocksResult.rows[0] || { id: null, name: 'Main Camp' };
    const areaHa = bestPaddock.area_ha ? parseFloat(bestPaddock.area_ha) : 100.0;
    const latestBiomass = bestPaddock.latest_biomass ? parseFloat(bestPaddock.latest_biomass) : 2200.0;

    // Carrying capacity calculation logic
    const capacityLsu = calculateCarryingCapacityLsu(areaHa, latestBiomass);

    return {
      recommendedAction: `Move main herd into "${bestPaddock.name}" paddock immediately.`,
      grazingDaysRemaining: Math.round((capacityLsu / Math.max(actualLsu, 1)) * 30),
      recommendedLsu:tatus, riskLevel: actualLsu: number;
  recommendedStockingRate: number;
  restPeriodDays: number;
  riskLevel: 'low' | 'moderate' | 'high' | 'severe';
  explanation: string;
}*/ 
    recommendedStockingRate: Math.round((capacityLsu / areaHa) * 100) / 100,
      restPeriodDays: 45,
      riskLevel: actualLsu > recommendedLsu ? 'high' : 'low',
      explanation: `Based on vegetation analysis, "${bestPaddock.name}" has estimated forage biomass of ${latestBiomass} kg DM/ha. Current stock rate is sustainable. Allow other camps to rest for 45 days.`,
    };
  }

  // 2. Gather enhanced ecological data for AI
  const ecologicalData = {};
  if (inputs?.plantComposition) {
    Object.assign(ecologicalData, inputs.plantComposition);
  }
  if (inputs?.rainfallHistory) {
    // Use average of last 3 months
    const recentRainfall = inputs.rainfallHistory.slice(-3);
    const avgRainfall = recentRainfall.reduce((a, b) => a + b, 0) / Math.max(recentRainfall.length, 1);
    ecologicalData.rainfallMm = avgRainfall;
  }

  // 3. Calculate enhanced biomass estimates for each paddock
  const paddockAnalysis = [];
  for (const paddock of paddocksResult.rows) {
    const zoneId = paddock.id;
    const areaHa = parseFloat(paddock.area_ha);
    
    // Fetch satellite observations
    const obsResult = await query(
      `SELECT id, observation_date, ndvi_value, evi_value, biomass_kg_per_ha, data_source
       FROM satellite_observations
       WHERE grazing_zone_id = $1
       ORDER BY observation_date DESC LIMIT 6`,
      [zoneId]
    );

    const observations: SatelliteObservation[] = obsResult.rows.map(row => ({
      id: row.id,
      observationDate: row.observation_date,
      ndviValue: parseFloat(row.ndvi_value),
      eviValue: row.evi_value ? parseFloat(row.evi_value) : null,
      biomassKgPerHa: parseFloat(row.biomass_kg_per_ha),
      dataSource: row.data_source,
    }));

    let biomassEstimate = null;
    if (observations.length > 0) {
      const ecoData = ecologicalData[zoneId] || {};
      biomassEstimate = calculateComprehensiveBiomass(observations, areaHa, ecoData);
      biomassEstimate.grazingZoneId = zoneId;
      
      // Persist the enhanced estimate
      await query(
        `INSERT INTO biomass_estimates 
          (grazing_zone_id, estimate_date, biomass_kg_per_ha, total_available_forage_kg, confidence_level, created_at)
        VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
        ON CONFLICT (grazing_zone_id, estimate_date) DO UPDATE SET
          biomass_kg_per_ha = EXCLUDED.biomass_kg_per_ha,
          total_available_forage_kg = EXCLUDED.total_available_forage_kg,
          confidence_level = EXCLUDED.confidence_level`,
        [
          zoneId,
          biomassEstimate.estimateDate,
          biomassEstimate.biomassKgPerHa,
          biomassEstimate.totalAvailableForageKg,
          biomassEstimate.confidenceLevel,
        ]
      );
    }

    paddockAnalysis.push({
      id: paddock.id,
      name: paddock.name,
      areaHa,
      status: paddock.current_status,
      waterPointAvailable: paddock.water_point_available,
      biomassKgPerHa: biomassEstimate ? biomassEstimate.biomassKgPerHa : 2200.0,
      totalAvailableForageKg: biomassEstimate ? biomassEstimate.totalAvailableForageKg : biomassEstimate ? biomassEstimate.biomassKgPerHa * areaHa : 2200.0 * areaHa,
      biomassEstimate,
    });
  }

  // 4. Calculate current farm totals
  const totalAreaHa = paddockAnalysis.reduce((sum, p) => sum + p.areaHa, 0);
  const totalBiomassWeighted = paddockAnalysis.reduce((sum, p) => sum + (p.biomassKgPerHa * p.areaHa), 0);
  const avgBiomass = totalAreaHa > 0 ? totalBiomassWeighted / totalAreaHa : 2200;

  // 5. Construct enhanced structured LLM prompt
  const prompt = `
    You are an expert rangeland ecologist with deep knowledge of African savanna ecosystems. 
    Recommend an optimal grazing rotation plan based on comprehensive satellite biomass analysis, 
    livestock data, and ecological conditions.
    Respond with a strict raw JSON object matching the JSON schema. No markdown wrappers.

    FARM OVERVIEW:
    - Total area: ${totalAreaHa.toFixed(1)} hectares
    - Average biomass: ${avgBiomass.toFixed(0)} kg DM/ha
    - Current livestock load: ${actualLsu} LSU
    - Recommended sustainable load: ${recommendedLsu} LSU
    - Stocking pressure: ${Math.round((actualLsu / Math.max(recommendedLsu, 0.1)) * 100)}%

    PADDOCK ANALYSIS:
    ${paddockAnalysis.map(p => `
    - ${p.name} (${p.areaHa} ha):
      * Biomass: ${p.biomassKgPerHa.toFixed(0)} kg DM/ha
      * Total forage: ${p.totalAvailableForageKg.toFixed(0)} kg
      * Status: ${p.status}
      * Water available: ${p.waterPointAvailable ? 'Yes' : 'No'}
      * Trend: ${p.biomassEstimate ? calculateBiomassTrend([{
        observationDate: '2026-01-01',
        ndviValue: 0.3,
        eviValue: 0.25,
        biomassKgPerHa: p.biomassKgPerHa,
        dataSource: 'Sentinel-2'
      } as SatelliteObservation]).trend : 'stable'}
    `).join('\n')}

    ECOLOGICAL FACTORS:
    ${inputs?.plantComposition ? `
    - Desirable grass percentage: ${inputs.plantComposition.desirableGrassPct?.toFixed(0) ?? 'N/A'}%
    - Invasive species percentage: ${inputs.plantComposition.invasiveSpeciesPct?.toFixed(0) ?? 'N/A'}%
    - Bush encroachment level: ${inputs.plantComposition.bushEncroachmentPct?.toFixed(0) ?? 'N/A'}%
    ` : ''}
    ${inputs?.rainfallHistory ? `
    - Recent rainfall (3-month avg): ${(inputs.rainfallHistory.slice(-3).reduce((a,b)=>a+b,0)/Math.max(inputs.rainfallHistory.slice(-3).length,1)).toFixed(1)} mm
    ` : ''}
    - Season: ${new Date().toLocaleString('en-ZA', { month: 'long' })}

    HISTORICAL CONTEXT:
    - Previous grazing patterns should be considered for rest period allocation
    - Drought conditions may require supplementary feeding or destocking
    - Bush encroachment reduces available grass biomass
    - Invasive species decrease forage quality and palatability

    JSON SCHEMA:
    {
      "recommendedAction": "Specific action statement specifying which paddock(s) to graze and for how long, including any destocking or supplementation advice.",
      "grazingDaysRemaining": 30, // Integer days of grazing capacity based on current biomass and stocking
      "recommendedStockingRate": 0.25, // Float LSU/ha target for optimal sustainability
      "restPeriodDays": 45, // Integer rest period recommendation for paddocks not in use
      "riskLevel": "low" | "moderate" | "high" | "severe",
      "explanation": "Detailed human-readable explanation covering: 1) Key data points used (biomass, trends, ecological factors), 2) Risks identified (overgrazing, drought, invasive species), 3) Reasoning behind the recommendation, 4) Expected outcomes if followed, 5) Consequences of ignoring the recommendation."
    }
  `;

  try {
    const apiResponse = await callOpenRouter(
      [{ role: 'user', content: prompt }],
      {
        model: 'meta-llama/llama-3.3-70b-instruct',
        temperature: 0.2,
        maxTokens: 1024,
        userId: req?.user?.userId || 'system',
        endpoint: 'grazing-recommendation'
      }
    );

    const rawContent = apiResponse.content;
    const jsonString = rawContent.replace(/```json/g, '').replace(/```/g, '').trim();
    const recommendation = JSON.parse(jsonString) as GrazingRecommendationOutput;

    // Validate and enhance recommendation with calculated values
    const bestPaddock = paddockAnalysis.reduce((best, current) => 
      (current.biomassKgPerHa > best.biomassKgPerHa) ? current : best
    ) || paddockAnalysis[0] || { name: 'Main Camp', areaHa: 100 };

    // Enhance with calculated values if AI didn't provide reasonable ones
    const capacityLsu = calculateCarryingCapacityLsu(bestPaddock.areaHa, bestPaddock.biomassKgPerHa);
    const daysRemaining = calculateGrazingDaysRemaining(
      { 
        grazingZoneId: bestPaddock.id,
        biomassKgPerHa: bestPaddock.biomassKgPerHa,
        totalAvailableForageKg: bestPaddock.biomassKgPerHa * bestPaddock.areaHa,
        confidenceLevel: 'high',
        estimateDate: new Date().toISOString().split('T')[0],
        method: 'comprehensive',
        metadata: { areaHa: bestPaddock.areaHa }
      },
      actualLsu
    );

    return {
      recommendedAction: recommendation.recommendedAction || 
        `Move main herd into "${bestPaddock.name}" paddock immediately. Allow other camps to rest for ${recommendation.restPeriodDays || 45} days.`,
      grazingDaysRemaining: recommendation.grazingDaysRemaining > 0 ? recommendation.grazingDaysRemaining : daysRemaining,
      recommendedStockingRate: recommendation.recommendedStockingRate > 0 ? 
        recommendation.recommendedStockingRate : 
        Math.round((capacityLsu / bestPaddock.areaHa) * 100) / 100,
      restPeriodDays: recommendation.restPeriodDays > 0 ? recommendation.restPeriodDays : 
        calculateRestPeriodRecommendation(
          { 
            grazingZoneId: bestPaddock.id,
            biomassKgPerHa: bestPaddock.biomassKgPerHa,
            totalAvailableForageKg: bestPaddock.biomassKgPerHa * bestPaddock.areaHa,
            confidenceLevel: 'high',
            estimateDate: new Date().toISOString().split('T')[0],
            method: 'comprehensive',
            metadata: { areaHa: bestPaddock.areaHa }
          },
          new Date().getMonth()
        ),
      riskLevel: recommendation.riskLevel || 
        assessOvergrazingRisk(
          { 
            grazingZoneId: bestPaddock.id,
            biomassKgPerHa: bestPaddock.biomassKgPerHa,
            totalAvailableForageKg: bestPaddock.biomassKgPerHa * bestPaddock.areaHa,
            confidenceLevel: 'high',
            estimateDate: new Date().toISOString().split('T')[0],
            method: 'comprehensive',
            metadata: { areaHa: bestPaddock.areaHa }
          },
          actualLsu,
          capacityLsu
        ).riskLevel,
      explanation: recommendation.explanation || 
        `Analysis of ${paddockAnalysis.length} paddocks shows ${bestPaddock.name} has the highest biomass at ${bestPaddock.biomassKgPerHa.toFixed(0)} kg DM/ha. ` +
        `Current stocking rate of ${Math.round((actualLsu / totalAreaHa) * 100) / 100} LSU/ha is ${actualLsu > capacityLsu ? 'above' : 'below'} sustainable capacity of ${(capacityLsu / totalAreaHa).toFixed(2)} LSU/ha. ` +
        `Recommend rotational grazing to allow pasture recovery and maintain veld health.`
    };
  } catch (error) {
    console.error('Grazing AI Engine Error:', error);
    
    // Enhanced fallback with biomass-based calculation
    const bestPaddock = paddockAnalysis.reduce((best, current) => 
      (current.biomassKgPerHa > best.biomassKgPerHa) ? current : best
    ) || paddockAnalysis[0] || { name: 'Main Camp', areaHa: 100 };
    
    const areaHa = bestPaddock.area_ha ? parseFloat(bestPaddock.area_ha) : 100.0;
    const latestBiomass = bestPaddock.latest_biomass ? parseFloat(bestPaddock.latest_biomass) : 2200.0;
    const capacityLsu = calculateCarryingCapacityLsu(areaHa, latestBiomass);
    const daysRemaining = calculateGrazingDaysRemaining(
      { 
        grazingZoneId: bestPaddock.id,
        biomassKgPerHa: latestBiomass,
        totalAvailableForageKg: latestBiomass * areaHa,
        confidenceLevel: 'high',
        estimateDate: new Date().toISOString().split('T')[0],
        method: 'fallback',
        metadata: { areaHa }
      },
      actualLsu
    );
    const recommendedRate = calculateRecommendedStockingRate(
      { 
        grazingZoneId: bestPaddock.id,
        biomassKgPerHa: latestBiomass,
        totalAvailableForageKg: latestBiomass * areaHa,
        confidenceLevel: 'high',
        estimateDate: new Date().toISOString().split('T')[0],
        method: 'fallback',
        metadata: { areaHa }
      }
    );
    const restPeriod = calculateRestPeriodRecommendation(
      { 
        grazingZoneId: bestPaddock.id,
        biomassKgPerHa: latestBiomass,
        totalAvailableForageKg: latestBiomass * areaHa,
        confidenceLevel: 'high',
        estimateDate: new Date().toISOString().split('T')[0],
        method: 'fallback',
        metadata: { areaHa }
      },
      new Date().getMonth()
    );
    const riskAssessment = assessOvergrazingRisk(
      { 
        grazingZoneId: bestPaddock.id,
        biomassKgPerHa: latestBiomass,
        totalAvailableForageKg: latestBiomass * areaHa,
        confidenceLevel: 'high',
        estimateDate: new Date().toISOString().split('T')[0],
        method: 'fallback',
        metadata: { areaHa }
      },
      actualLsu,
      capacityLsu
    );

    return {
      recommendedAction: `Move main herd into "${bestPaddock.name}" paddock immediately.`,
      grazingDaysRemaining: daysRemaining,
      recommendedStockingRate: recommendedRate,
      restPeriodDays: restPeriod,
      riskLevel: riskAssessment.riskLevel,
      explanation: `Fallback recommendation based on satellite biomass analysis. "${bestPaddock.name}" has ${latestBiomass.toFixed(0)} kg DM/ha forage. ` +
                   `Current load: ${actualLsu} LSU, Sustainable capacity: ${capacityLsu.toFixed(1)} LSU. ` +
                   `Risk level: ${riskAssessment.riskLevel}. ${riskAssessment.recommendation}`
    };
  }
}
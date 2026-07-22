// Enhanced Drought prediction and climate intelligence service
import { query } from './db';
import { ClimateService, ClimateRecord } from './climate-service';
import { 
  calculateCarryingCapacityLsu 
} from './carrying-capacity';

export interface DroughtForecastOutput {
  forecastPeriodDays: number;
  droughtRiskLevel: 'low' | 'moderate' | 'high' | 'severe';
  droughtRiskScore: number; // 0-100
  rainfallProbability: number; // % chance of adequate rainfall
  forageShortProbability: number; // % chance of feed deficit
  waterStressProbability: number; // % chance of water scarcity
  heatStressProbability: number; // % chance of THI >= 72
  forageDaysRemaining: number; // Estimated days until forage depletion
  spiValue: number; // Standardized Precipitation Index
  aniValue: number; // Agricultural Nomad Index (vegetation health)
  aiExplanation: string;
}

export interface AlertPayload {
  alertType: string;
  riskLevel: string;
  title: string;
  message: string;
  recommendedAction: string;
}

// Climate indices for enhanced drought monitoring
interface ClimateIndices {
  spi3: number; // 3-month Standardized Precipitation Index
  spi6: number; // 6-month Standardized Precipitation Index
  ani: number; // Agricultural Nomad Index (NDVI-based)
  ti: number; // Temperature Index
  hi: number; // Hydroclimatic Index
}

// Enhanced drought forecasting with multiple indices and better science
export async function generateDroughtForecast(
  farmId: string,
  forecastPeriodDays: number
): Promise<DroughtForecastOutput> {
  // 1. Get comprehensive climate data
  const climateHistory = await ClimateService.getClimateHistory(farmId, 24); // 2 years
  const currentClimate = climateHistory[0];
  const climateStats = await ClimateService.getClimateStatistics(farmId);
  
  // 2. Calculate advanced climate indices
  const indices = await calculateClimateIndicators(farmId, climateHistory);
  
  // 3. Get vegetation and biomass data from satellite observations
  const vegData = await getVegetationAndBiomassData(farmId);
  
  // 4. Get livestock and farm characteristics
  const farmMetrics = await getFarmAndLivestockMetrics(farmId);
  
  // 5. Calculate comprehensive drought risk using multiple indices
  const droughtAssessment = calculateComprehensiveDroughtRisk(
    indices, 
    vegData, 
    farmMetrics, 
    currentClimate
  );
  
  // 6. Calculate forecast probabilities
  const probabilities = calculateForecastProbabilities(
    droughtAssessment,
    climateStats,
    farmMetrics
  );
  
  // 7. Generate AI explanation (using enhanced prompt)
  let aiExplanation: string;
  const apiKey = process.env.OPENROUTER_API_KEY;
  
  if (!apiKey || apiKey === 'sk-or-mock-key') {
    aiExplanation = buildEnhancedExplanation(
      droughtAssessment, 
      probabilities, 
      indices, 
      vegData, 
      farmMetrics, 
      currentClimate
    );
  } else {
    aiExplanation = await fetchAIEnhancedExplanation(
      farmId, 
      droughtAssessment, 
      probabilities, 
      indices, 
      vegData, 
      farmMetrics, 
      currentClimate
    );
  }

  return {
    forecastPeriodDays,
    droughtRiskLevel: droughtAssessment.riskLevel,
    droughtRiskScore: droughtAssessment.score,
    rainfallProbability: probabilities.rainfall,
    forageShortProbability: probabilities.forageShortage,
    waterStressProbability: probabilities.waterStress,
    heatStressProbability: probabilities.heatStress,
    forageDaysRemaining: pastureDaysRemaining(vegData, farmMetrics),
    spiValue: indices.spi3,
    aniValue: indices.ani,
    aiExplanation
  };
}

/**
 * Calculate multiple climate indices for comprehensive drought assessment
 */
async function calculateClimateIndicators(
  farmId: string, 
  climateHistory: ClimateRecord[]
): Promise<ClimateIndices> {
  // Extract rainfall time series
  const rainfallSeries = climateHistory.map(record => record.rainfallMm);
  
  // Calculate SPI for different time scales
  const spi3 = ClimateService.calculateSPI(rainfallSeries, 3);
  const spi6 = ClimateService.calculateSPI(rainfallSeries, 6);
  
  // Calculate Temperature Index (deviation from optimal growing temp)
  const tempSeries = climateHistory.map(record => record.temperatureC);
  const avgTemp = tempSeries.reduce((sum, t) => sum + t, 0) / tempSeries.length;
  const ti = Math.max(0, Math.min(1, (avgTemp - 15) / 20)); // Optimal 15-35°C for grass growth
  
  // Calculate Hydroclimatic Index (P/PET ratio simplified)
  const etSeries = climateHistory.map(record => record.evapotranspirationMm);
  const avgPPT = rainfallSeries.reduce((sum, r) => sum + r, 0) / rainfallSeries.length;
  const avgPET = etSeries.reduce((sum, e) => sum + e, 0) / etSeries.length;
  const hi = avgPET > 0 ? Math.min(2, avgPPT / avgPET) : 2;
  
  // Agricultural Nomad Index (simplified vegetation health predictor)
  // Based on precipitation adequacy and temperature stress
  const ani = Math.max(0, Math.min(1, 
    (rainfallSeries[0] / Math.max(1, rainfallSeries.slice(0,3).reduce((sum, r)=>sum+r,0)/3)) * 0.6 +
    (1 - Math.abs(tempSeries[0] - 25) / 20) * 0.4 // Penalty for temp deviation from 25°C ideal
  ));
  
  return {
    spi3,
    spi6,
    ani,
    ti,
    hi
  };
}

/**
 * Get vegetation index and biomass data from satellite observations
 */
async function getVegetationAndBiomassData(farmId: string) {
  const result = await query(
    `SELECT 
       COALESCE(
         (SELECT ndvi_value FROM satellite_observations so
          JOIN paddocks p ON so.grazing_zone_id = p.id
          WHERE p.farm_id = $1
          AND observation_date >= CURRENT_DATE - INTERVAL '30 days'
          ORDER BY observation_date DESC LIMIT 1),
         0.4
       ) AS avg_ndvi,
       
       COALESCE(
         (SELECT AVG(ndvi_value) FROM satellite_observations so
          JOIN paddocks p ON so.grazing_zone_id = p.id
          WHERE p.farm_id = $1
          AND observation_date >= CURRENT_DATE - INTERVAL '90 days'
          AND observation_date < CURRENT_DATE - INTERVAL '30 days'),
         0.5
       ) AS baseline_ndvi,
       
       COALESCE(
         (SELECT biomass_kg_per_ha FROM satellite_observations so
          JOIN paddocks p ON so.grazing_zone_id = p.id
          WHERE p.farm_id = $1
          ORDER BY observation_date DESC LIMIT 1),
         2000
       ) AS latest_biomass_kg_ha,
       
       COALESCE(
         (SELECT AVG(biomass_kg_per_ha) FROM satellite_observations so
          JOIN paddocks p ON so.grazing_zone_id = p.id
          WHERE p.farm_id = $1
          AND observation_date >= CURRENT_DATE - INTERVAL '90 days'
          AND observation_date < CURRENT_DATE - INTERVAL '30 days'),
         2200
       ) AS baseline_biomass_kg_ha`,

    [farmId]
  );

  const row = result.rows[0];
  return {
    ndvi: parseFloat(row.avg_ndvi),
    baselineNdvi: parseFloat(row.baseline_ndvi),
    biomassKgPerHa: parseFloat(row.latest_biomass_kg_ha),
    baselineBiomassKgPerHa: parseFloat(row.baseline_biomass_kg_ha)
  };
}

/**
 * Get farm characteristics and livestock metrics
 */
async function getFarmAndLivestockMetrics(farmId: string) {
  const result = await query(
    `SELECT 
       COALESCE(SUM(area_ha), 100) AS total_area_ha,
       COALESCE(AVG(baseline_lsu_per_ha), 0.20) AS avg_lsu_per_ha,
       
       COALESCE(SUM(lsu_value), 50) AS total_lsu,
       COALESCE(SUM(tlu_value), 70) AS total_tlu,
       
       COALESCE((
         SELECT STRING_AGG(DISTINCT species, ',') 
         FROM livestock_groups 
         WHERE farm_id = $1
       ), 'mixed') AS livestock_mix,
       
       COALESCE((
         SELECT COUNT(*) 
         FROM water_points 
         WHERE farm_id = $1 AND status = 'functional'
       ), 2) AS functionalWaterPoints`,

    [farmId]
  );

  const row = result.rows[0];
  return {
    totalAreaHa: parseFloat(row.total_area_ha),
    avgLsuPerHa: parseFloat(row.avg_lsu_per_ha),
    totalLsu: parseFloat(row.total_lsu),
    totalTlu: parseFloat(row.total_tlu),
    livestockMix: row.livestock_mix,
    functionalWaterPoints: parseInt(row.functionalWaterPoints)
  };
}

/**
 * Calculate comprehensive drought risk using multiple indices and factors
 */
function calculateComprehensiveDroughtRisk(
  indices: ClimateIndices,
  vegData: any,
  farmMetrics: any,
  currentClimate: ClimateRecord
) {
  // Component scores (0-100, higher = worse drought conditions)
  
  // 1. Precipitation deficit (SPI-based) - 25% weight
  const spiScore = Math.max(0, Math.min(100, (-indices.spi3) * 20 + 50)); // SPI -2 to +2 maps to 0-100
  
  // 2. Vegetation condition (ANI and NDVI anomaly) - 25% weight
  const ndviAnomaly = 1 - (vegData.ndvi / Math.max(0.1, vegData.baselineNdvi));
  const vegScore = Math.max(0, Math.min(100, 
    (1 - indices.ani) * 50 + 
    Math.max(0, ndviAnomaly * 100) * 0.5
  ));
  
  // 3. Soil moisture/water stress (Temperature-Humidity-Precipitation interaction) - 20% weight
  const thpIndex = 
    (1 - Math.min(1, Math.max(0, currentClimate.rainfallMm / 100))) * 0.4 + // Rainfall deficit
    (currentClimate.temperatureC / 50) * 0.3 + // Temperature stress
    (1 - currentClimate.humidityPercentage / 100) * 0.3; // Humidity deficit
  const waterScore = Math.max(0, Math.min(100, thpIndex * 100));
  
  // 4. Forecast-based risk (using longer-term SPI) - 15% weight
  const forecastRisk = Math.max(0, Math.min(100, (-indices.spi6) * 15 + 50));
  
  // 5. Human/livestock pressure factor - 15% weight
  const stockingPressure = Math.min(1, farmMetrics.totalLsu / (farmMetrics.totalAreaHa * farmMetrics.avgLsuPerHa * 1.5));
  const pressureScore = stockingPressure * 100;
  
  // Weighted composite score
  const compositeScore = 
    spiScore * 0.25 +
    vegScore * 0.25 +
    waterScore * 0.20 +
    forecastRisk * 0.15 +
    pressureScore * 0.15;
  
  // Classify risk level
  let riskLevel: 'low' | 'moderate' | 'high' | 'severe' = 'low';
  if (compositeScore >= 80) riskLevel = 'severe';
  else if (compositeScore >= 60) riskLevel = 'high';
  else if (compositeScore >= 40) riskLevel = 'moderate';
  
  return {
    score: parseFloat(compositeScore.toFixed(1)),
    riskLevel,
    components: {
      spi: parseFloat(spiScore.toFixed(1)),
      vegetation: parseFloat(vegScore.toFixed(1)),
      water: parseFloat(waterScore.toFixed(1)),
      forecast: parseFloat(forecastRisk.toFixed(1)),
      pressure: parseFloat(pressureScore.toFixed(1))
    }
  };
}

/**
 * Calculate forecast probabilities for different outcomes
 */
function calculateForecastProbabilities(
  droughtAssessment: any,
  climateStats: any,
  farmMetrics: any
) {
  // Base probabilities from drought assessment
  const baseDroughtRisk = droughtAssessment.score / 100;
  
  // Rainfall probability (inverse of drought tendency, adjusted for season)
  let rainfallProb = Math.max(10, Math.min(90, 70 - (droughtAssessment.components.spi - 50) * 0.8));
  // Adjust for climatological season
  const month = new Date().getMonth();
  const seasonalFactor = Math.sin(month * Math.PI / 6) * 0.2 + 0.8; // Seasonal variation
  rainfallProb = Math.max(10, Math.min(90, rainfallProb * seasonalFactor));
  
  // Forage shortage probability (based on biomass, stocking rate, and drought)
  const daysUntilDepletion = pastureDaysRemaining(null, farmMetrics); // Will calculate properly below
  const baseForageRisk = Math.min(0.9, Math.max(0.1, 
    (droughtAssessment.score / 100) * 0.6 + 
    (farmMetrics.totalLsu / Math.max(1, farmMetrics.totalAreaHa * 0.25)) * 0.4
  ));
  const forageProb = Math.max(10, Math.min(90, baseForageRisk * 100));
  
  // Water stress probability (combination of drought and water infrastructure)
  const waterRisk = Math.min(0.9, Math.max(0.1,
    droughtAssessment.components.water / 100 * 0.7 +
    (1 - Math.min(1, farmMetrics.functionalWaterPoints / Math.max(1, farmMetrics.totalAreaHa / 100))) * 0.3
  ));
  const waterProb = Math.max(10, Math.min(90, waterRisk * 100));
  
  // Heat stress probability (temperature and humidity based)
  const tempFactor = Math.max(0, Math.min(1, (climateStats.temperatureAnomaly + 5) / 10)); // Normalize around 0
  const humidityFactor = 1 - Math.min(1, Math.max(0, (50 - 30) / 20)); // Low humidity increases heat stress
  const heatBase = Math.max(0, Math.min(1, 
    (droughtAssessment.score / 100) * 0.4 +
    tempFactor * 0.4 +
    humidityFactor * 0.2
  ));
  const heatProb = Math.max(5, Math.min(95, heatBase * 100));
  
  return {
    rainfall: parseFloat(rainfallProb.toFixed(1)),
    forageShortage: parseFloat(forageProb.toFixed(1)),
    waterStress: parseFloat(waterProb.toFixed(1)),
    heatStress: parseFloat(heatProb.toFixed(1))
  };
}

/**
 * Calculate days until pasture depletion based on current biomass and livestock demand
 */
function pastureDaysRemaining(vegData: any | null, farmMetrics: any): number {
  if (!vegData) {
    // Fallback calculation
    const dailyDemand = farmMetrics.totalLsu * 11.25; // kg DM/day per LSU
    const totalForage = farmMetrics.totalAreaHa * 2000 * 0.4; // Assume 2000 kg/ha, 40% utilization
    return dailyDemand > 0 ? Math.max(0, Math.round(totalForage / dailyDemand)) : 365;
  }
  
  const dailyDemand = farmMetrics.totalLsu * 11.25;
  const availableForage = farmMetrics.totalAreaHa * 
    vegData.biomassKgPerHa * 
    0.4; // 40% utilization rate
    
  return dailyDemand > 0 ? Math.max(0, Math.round(availableForage / dailyDemand)) : 365;
}

/**
 * Generate enhanced AI explanation for drought forecast
 */
function buildEnhancedExplanation(
  droughtAssessment: any,
  probabilities: any,
  indices: ClimateIndices,
  vegData: any,
  farmMetrics: any,
  currentClimate: ClimateRecord
): string {
  const riskLevel = droughtAssessment.riskLevel.toUpperCase();
  
  let explanation = [
    `ENHANCED DROUGHT RISK ASSESSMENT: ${riskLevel}`,
    `Overall Risk Score: ${droughtAssessment.score}/100`,
    '',
    'CLIMATE INDICATORS:',
    `• 3-Month SPI: ${indices.spi3.toFixed(2)} (${getSPICategory(indices.spi3)})`,
    `• 6-Month SPI: ${indices.spi6.toFixed(2)} (${getSPICategory(indices.spi6)})`,
    `• Agricultural Nomad Index: ${(indices.ani * 100).toFixed(0)}%`,
    `• Temperature Index: ${(indices.ti * 100).toFixed(0)}%`,
    `• Hydroclimatic Index: ${indices.hi.toFixed(2)}`,
    '',
    'CURRENT CONDITIONS:',
    `• Rainfall: ${currentClimate.rainfallMm} mm`,
    `• Temperature: ${currentClimate.temperatureC}°C`,
    `• Humidity: ${currentClimate.humidityPercentage}%`,
    `• Vegetation (NDVI): ${vegData.ndvi.toFixed(3)}`,
    `• Biomass: ${vegData.biomassKgPerHa.toFixed(0)} kg DM/ha`,
    '',
    'RISK COMPONENT BREAKDOWN:',
    `• Precipitation Deficit: ${droughtAssessment.components.spi.toFixed(0)}`,
    `• Vegetation Stress: ${droughtAssessment.components.vegetation.toFixed(0)}`,
    `• Water Stress: ${droughtAssessment.components.water.toFixed(0)}`,
    `• Forecast Risk: ${droughtAssessment.components.forecast.toFixed(0)}`,
    `• Grazing Pressure: ${droughtAssessment.components.pressure.toFixed(0)}`,
    '',
    'FORECAST PROBABILITIES (next ${30} days):',
    `• Adequate Rainfall: ${probabilities.rainfall}%`,
    `• Forage Shortage Risk: ${probabilities.forageShortage}%`,
    `• Water Stress Risk: ${probabilities.waterStress}%`,
    `• Heat Stress Risk: ${probabilities.heatStress}%`,
    '',
    'RECOMMENDATIONS:',
    getRecommendations(droughtAssessment.riskLevel, probabilities, farmMetrics)
  ].join('\n');
  
  return explanation;
}

/**
 * Get SPI category description
 */
function getSPICategory(spi: number): string {
  if (spi >= 2.0) return 'Extremely Wet';
  if (spi >= 1.5) return 'Very Wet';
  if (spi >= 1.0) return 'Moderately Wet';
  if (spi >= 0.5) return 'Slightly Wet';
  if (spi >= -0.5) return 'Near Normal';
  if (spi >= -1.0) return 'Moderately Dry';
  if (spi >= -1.5) return 'Severely Dry';
  return 'Extremely Dry';
}

/**
 * Generate specific recommendations based on risk assessment
 */
function getRecommendations(
  riskLevel: string,
  probabilities: any,
  farmMetrics: any
): string {
  const recs = [];
  
  if (riskLevel === 'SEVERE') {
    recs.push('• IMMEDIATE ACTION: Begin emergency livestock reduction (30-50%)');
    recs.push('• Secure emergency water supplies for remaining herd');
    recs.push('• Activate drought contingency plan with agricultural extension');
    recs.push('• Consider temporary relocation to grazing reserves if available');
  } else if (riskLevel === 'HIGH') {
    recs.push('• Prepare for potential livestock reductions (10-20%)');
    recs.push('• Identify alternative water sources and storage options');
    regs.push('• Begin supplemental feeding preparations');
    recs.push('• Review and update drought response plan');
  } else if (riskLevel === 'MODERATE') {
    recs.push('• Increase monitoring frequency to weekly');
    recs.push('• Prepare forage reserves and supplement supplies');
    recs.push('• Consider early weaning to reduce nutritional demands');
    recs.push('• Evaluate water point efficiency and repair needs');
  } else {
    recs.push('• Continue normal grazing management with standard monitoring');
    recs.push('• Maintain forage reserves for unexpected dry spells');
    recs.push('• Keep vaccination and health programs up to date');
  }
  
  // Add specific recommendations based on probabilities
  if (probabilities.forageShortage > 60) {
    res.push('• Begin forage conservation: hay preparation and storage');
    res.push('• Explore alternative feed sources (crop residues, browse)');
  }
  
  if (probabilities.waterStress > 60) {
    res.push('• Inspect and repair water infrastructure immediately');
    res.push('• Consider water harvesting and storage enhancement');
    res.push('• Schedule water point maintenance before peak demand');
  }
  
  if (probabilities.heatStress > 60) {
    res.push('• Modify grazing schedules to cooler hours (early morning/late evening)');
    res.push('• Ensure adequate shade structures at water points and resting areas');
    res.push('• Increase water point frequency during hot periods');
  }
  
  return res.join('\n');
}

/**
 * Generate enhanced alert payloads based on comprehensive assessment
 */
export function generateEnhancedAlerts(
  droughtAssessment: any,
  probabilities: any,
  indices: ClimateIndices,
  vegData: any,
  farmMetrics: any
): AlertPayload[] {
  const alerts: AlertPayload[] = [];
  
  // Drought alert with enhanced logic
  if (droughtAssessment.score >= 60) {
    alerts.push({
      alertType: 'drought',
      riskLevel: droughtAssessment.riskLevel,
      title: `${droughtAssessment.riskLevel.toUpperCase()} DROUGHT ALERT`,
      message: `Multi-index drought assessment indicates ${droughtAssessment.riskLevel} risk (Score: ${droughtAssessment.score}/100). ` +
               `SPI-3: ${indices.spi3.toFixed(2)}, Vegetation health: ${(indices.ani*100).toFixed(0)}%.`,
      recommendedAction: getDroughtRecommendations(droughtAssessment.riskLevel, farmMetrics)
    });
  }
  
  // Forage shortage alert with prediction horizon
  const daysRemaining = pastureDaysRemaining(vegData, farmMetrics);
  if (daysRemaining < 60) {
    alerts.push({
      alertType: 'forage_shortage',
      riskLevel: daysRemaining < 20 ? 'severe' : daysRemaining < 40 ? 'high' : 'moderate',
      title: `FORAGE ALERT: ${daysRemaining} DAYS REMAINING AT CURRENT USAGE`,
      message: `Based on current biomass levels (${vegData.biomassKgPerHa.toFixed(0)} kg DM/ha) and livestock density, ` +
               `projected forage depletion in ${daysRemaining} days. ` +
               `SPI-3 indicates ${getSPICategory(indices.spi3)} conditions.`,
      recommendedAction: getForageRecommendations(daysRemaining, farmMetrics)
    });
  }
  
  // Water stress alert
  const waterRiskScore = (droughtAssessment.components.water / 100) * 100;
  if (waterRiskScore >= 60) {
    alerts.push({
      alertType: 'water_stress',
      riskLevel: waterRiskScore >= 80 ? 'severe' : waterRiskScore >= 60 ? 'high' : 'moderate',
      title: `WATER STRESS ALERT: ${waterRiskScore.toFixed(0)}% RISK`,
      message: `Combined hydrological indices indicate elevated water stress risk. ` +
               `Hydroclimatic Index: ${indices.hi.toFixed(2)} (optimal >1.5). ` +
               `Functional water points: ${farmMetrics.functionalWaterPoints}/${Math.max(1, Math.round(farmMetrics.totalAreaHa/100))}.`,
      recommendedAction: getWaterRecommendations(waterRiskScore, farmMetrics)
    });
  }
  
  // Heat stress alert (enhanced with THI calculation)
  const thi = 0.8 * currentClimate.temperatureC + (currentClimate.humidityPercentage / 100) * (currentClimate.temperatureC - 14.4) + 46.4;
  if (thi >= 72) {
    alerts.push({
      alertType: 'heat_stress',
      riskLevel: thi >= 84 ? 'severe' : thi >= 78 ? 'high' : 'moderate',
      title: `HEAT STRESS ALERT: THI ${thi.toFixed(1)}`,
      message: `Temperature-Humidity Index indicates ${getThreatLevel(thi)} heat stress risk. ` +
               `Current conditions: ${currentClimate.temperatureC}°C, ${currentClimate.humidityPercentage}% humidity.`,
      recommendedAction: getHeatRecommendations(thi)
    });
  }
  
  return alerts;
}

/**
 * Get threat level description for THI
 */
function getThreatLevel(thi: number): string {
  if (thi >= 84) return 'severe';
  if (thi >= 78) return 'high';
  return 'moderate';
}

/**
 * Get specific drought recommendations
 */
function getDroughtRecommendations(riskLevel: string, farmMetrics: any): string {
  switch (riskLevel) {
    case 'severe':
      return 'IMPLEMENT EMERGENCY PLAN: Reduce livestock by 40-60% immediately. ' +
             'Activate water trucking if necessary. Contact disaster relief agencies.';
    case 'high':
      return 'ACTIVATE DROUGHT RESPONSE: Prepare to reduce livestock by 20-30%. ' +
             'Increase surveillance of vegetation and water sources. ' +
             'Prepare supplemental feeding sites.';
    case 'moderate':
      return 'ENHANCE MONITORING: Check forage conditions twice weekly. ' +
             'Prepare contingency plans for 10-15% reduction if conditions worsen. ' +
             'Inspect water systems for efficiency improvements.';
    default:
      return 'MAINTAIN VIGILANCE: Continue standard monitoring practices. ' +
             'Review drought preparedness plans and resources.';
  }
}

/**
 * Get specific forage recommendations
 */
function getForageRecommendations(daysRemaining: number, farmMetrics: any): string {
  if (daysRemaining < 20) {
    return 'EMERGENCY FEEDING: Initiate supplementary feeding program immediately. ' +
           'Consider culling non-productive animals. Explore emergency grazing options.';
  } else if (daysRemaining < 40) {
    return 'PREPARATORY MEASURES: Begin supplemental feed procurement. ' +
           'Consider early weaning to reduce lactation demands. ' +
           'Evaluate standing hay crop potential.';
  } else {
    return 'PROACTIVE MANAGEMENT: Monitor forage growth rates. ' +
           'Consider rotational grazing to maximize forage utilization before decline. ' +
           'Maintain animal health to optimize feed efficiency.';
  }
}

/**
 * Get specific water recommendations
 */
function getWaterRecommendations(riskScore: number, farmMetrics: any): string {
  if (riskScore >= 80) {
    return 'IMMEDIATE WATER ACTIONS: Implement water rationing for livestock. ' +
           'Haul water if necessary. Repair all leaks immediately. ' +
           'Consider shared water points with neighboring farms.';
  } else if (riskScore >= 60) {
    return 'WATER CONSERVATION: Fix leaking troughs and pipes. ' +
           'Schedule drinking to cooler hours. Investigate water harvesting options. ' +
           'Monitor water points twice daily for functionality.';
  } else {
    return 'WATER MANAGEMENT: Maintain current schedule. ' +
           'Preventative maintenance on all water infrastructure. ' +
           'Consider water quality testing for livestock health.';
  }
}

/**
 * Get specific heat stress recommendations
 */
function getHeatRecommendations(thi: number): string {
  if (thi >= 84) {
    return 'EXTREME HEAT PROTOCOL: Cease all livestock movement between 10am-4pm. ' +
           'Provide continuous access to shade and cool water. ' +
           'Consider electrolytes in water. Monitor for signs of heat stroke hourly.';
  } else if (thi >= 78) {
    return 'HEAT STRESS MITIGATION: Restrict activity to early morning and late evening. ' +
           'Ensure shade availability at all resting and watering points. ' +
           'Increase water point density if possible.';
  } else {
    return 'HEAT AWARENESS: Provide shade where possible. ' +
           'Monitor animals for increased respiration rates. ' +
           'Ensure water sources are clean and accessible.';
  }
}

/**
 * Fetch AI-enhanced explanation from OpenRouter
 */
async function fetchAIEnhancedExplanation(
  farmId: string,
  droughtAssessment: any,
  probabilities: any,
  indices: ClimateIndices,
  vegData: any,
  farmMetrics: any,
  currentClimate: ClimateRecord
): Promise<string> {
  const prompt = `
    You are a senior rangeland scientist and drought expert providing 
    a comprehensive briefing to African livestock farmers.
    
    COMPREHENSIVE DROUGHT ASSESSMENT REPORT
    ======================================
    
    FARM ID: ${farmId}
    ASSESSMENT DATE: ${new Date().toISOString().split('T')[0]}
    
    CLIMATE INDICES:
    - 3-Month Standardized Precipitation Index (SPI-3): ${indices.spi3.toFixed(2)}
    - 6-Month Standardized Precipitation Index (SPI-6): ${indices.spi6.toFixed(2)}
    - Agricultural Nomad Index (ANI): ${(indices.ani * 100).toFixed(0)}%
    - Temperature Index: ${(indices.ti * 100).toFixed(0)}%
    - Hydroclimatic Index (H/PET): ${indices.hi.toFixed(2)}
    
    CURRENT OBSERVATIONS:
    - Rainfall: ${currentClimate.rainfallMm} mm
    - Temperature: ${currentClimate.temperatureC}°C
    - Relative Humidity: ${currentClimate.humidityPercentage}%
    - Vegetation Condition (NDVI): ${vegData.ndvi.toFixed(3)}
    - Available Forage Biomass: ${vegData.biomassKgPerHa.toFixed(0)} kg DM/ha
    - Evapotranspiration: ${currentClimate.evapotranspirationMm} mm
    
    FARM CHARACTERISTICS:
    - Total Area: ${farmMetrics.totalAreaHa} hectares
    - Livestock Density: ${(farmMetrics.totalLsu / farmMetrics.totalAreaHa).toFixed(2)} LSU/ha
    - Total Livestock: ${farmMetrics.totalLsu} LSU (${farmMetrics.totalTlu} TLU)
    - Livestock Composition: ${farmMetrics.livestockMix}
    - Functional Water Points: ${farmMetrics.functionalWaterPoints}
    
    RISK ASSESSMENT:
    - Overall Drought Risk: ${droughtAssessment.riskLevel.toUpperCase()} (${droughtAssessment.score}/100)
    - Component Breakdown:
      * Precipitation Deficit: ${droughtAssessment.components.spi.toFixed(0)}
      * Vegetation Stress: ${droughtAssessment.components.vegetation.toFixed(0)}
      * Water Stress: ${droughtAssessment.components.water.toFixed(0)}
      * Forecast Conditions: ${droughtAssessment.components.forecast.toFixed(0)}
      * Grazing Pressure Pressure: ${droughtAssessment.components.pressure.toFixed(0)}
    
    PROBABILISTIC FORECASTS (next 30 days):
    - Probability of Adequate Rainfall: ${probabilities.rainfall}%
    - Probability of Forage Shortage: ${probabilities.forageShortage}%
    - Probability of Water Stress: ${probabilities.waterStress}%
    - Probability of Heat Stress: ${probabilities.heatStress}%
    
    PROJECTED OUTLOOK:
    - Days of Forage Remaining at Current Use: ${pastureDaysRemaining(vegData, farmMetrics)} days
    - Recommended Stocking Rate: ${(farmMetrics.totalAreaHa * 0.20).toFixed(1)} LSU/ha
    - Current Stocking Rate: ${(farmMetrics.totalLsu / farmMetrics.totalAreaHa).toFixed(2)} LSU/ha
    
    REQUIRED OUTPUT:
    Provide a comprehensive but farmer-friendly briefing that includes:
    1. Executive summary of current conditions and risks
    2. Detailed explanation of what each index means for their operation
    3. Specific, actionable recommendations prioritized by urgency
    4. Expected conditions if no action is taken over next 60 days
    5. Signs to watch for that would indicate need to change plans
    6. Resources where they can get additional help
    
    Use clear, non-technical language where possible, but explain necessary technical terms.
    Format with clear sections and bullet points for easy reading.
  `;

  try {
    const apiKey = process.env.OPENROUTER_API_KEY!;
    const resp = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://afrirange.ai',
        'X-Title': 'AfriRange AI Climate Intelligence',
      },
      body: JSON.stringify({
        model: 'meta-llama/llama-3.3-70b',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.3,
        max_tokens: 1500
      }),
    });
    const completion = await resp.json();
    return completion.choices?.[0]?.message?.content || 
           'Unable to generate enhanced AI explanation. Please try again later.';
  } catch (error) {
    console.error('AI explanation error:', error);
    return 'Enhanced explanation service temporarily unavailable. ' +
           'Please refer to the standard assessment for guidance.';
  }
}
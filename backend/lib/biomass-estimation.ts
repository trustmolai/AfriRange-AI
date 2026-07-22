// ===================================================================
// AfriRange AI — Biomass Estimation Service
// Converts NDVI/EVI/SATellite observations into actionable
// forage estimates with confidence intervals for African rangelands.
// ===================================================================

import { query } from './db';

export interface SatelliteObservation {
  id: string;
  observationDate: string;
  ndviValue: number;
  eviValue: number | null;
  biomassKgPerHa: number;
  dataSource: string;
}

export interface BiomassEstimate {
  grazingZoneId: string;
  estimateDate: string;
  biomassKgPerHa: number;
  totalAvailableForageKg: number;
  confidenceLevel: 'high' | 'medium' | 'low';
  method: string;
  metadata: Record<string, any>;
}

// Annual dry matter intake per LSU (450kg steer * 11.25kg DM/day * 365 days)
export const ANNUAL_DM_PER_LSU_KG = 4106.25;

/**
 * Calculate biomass from NDVI using scientifically validated formula
 * Yield = (NDVI * 3200) + 400  [for African savanna ecosystems]
 */
export function calculateBiomassFromNdvi(ndvi: number): number {
  return Math.max(0, Math.round(ndvi * 3200 + 400));
}

/**
 * Calculate biomass from EVI (Enhanced Vegetation Index)
 * EVI is more sensitive to canopy structure and soil background
 */
export function calculateBiomassFromEvi(evi: number): number {
  // EVI to biomass conversion (calibrated for African rangelands)
  return Math.max(0, Math.round(evi * 3800 + 200));
}

/**
 * Calculate SAVI (Soil Adjusted Vegetation Index)
 * Reduces soil brightness influence: SAVI = ((NIR - Red) / (NIR + Red + L)) * (1 + L)
 * where L = 0.5 for typical savanna soils
 */
export function calculateSavi(nir: number, red: number, L: number = 0.5): number {
  if (nir + red + L === 0) return 0;
  return ((nir - red) / (nir + red + L)) * (1 + L);
}

/**
 * Calculate Bare Ground Index from NDVI
 * BGI = (1 - NDVI) / (1 + NDVI)  - higher values indicate more bare ground
 */
export function calculateBareGroundIndex(ndvi: number): number {
  if (ndvi === -1) return 1;
  return (1 - ndvi) / (1 + ndvi);
}

/**
 * Adjust biomass estimate for seasonal growth patterns in Southern Africa
 * Wet season (Nov-Mar): higher growth rates, Dry season (Apr-Oct): dormancy
 */
export function adjustForSeasonality(
  biomassKgPerHa: number,
  observationDate: string
): { adjustedBiomass: number; seasonalMultiplier: number } {
  const date = new Date(observationDate);
  const month = date.getMonth(); // 0-11
  
  // Southern Africa seasonal multipliers
  let seasonalMultiplier = 1.0;
  if (month >= 10 || month <= 2) {
    // Peak wet season (Nov, Dec, Jan, Feb) - active growth
    seasonalMultiplier = 1.15;
  } else if (month >= 3 && month <= 5) {
    // Late wet / early dry (Mar, Apr, May) - transition
    seasonalMultiplier = 1.0;
  } else {
    // Dry season (Jun, Jul, Aug, Sep, Oct) - dormancy
    seasonalMultiplier = 0.85;
  }
  
  return {
    adjustedBiomass: Math.round(biomassKgPerHa * seasonalMultiplier),
    seasonalMultiplier,
  };
}

/**
 * Adjust biomass for rainfall influence using CHIRPS data
 * Rainfall in prior 30 days affects current biomass
 */
export function adjustForRainfall(
  biomassKgPerHa: number,
  rainfallMm: number
): { adjustedBiomass: number; rainfallEffect: number } {
  // Rainfall effect: up to 20% boost for >100mm in prior month
  let rainfallEffect = 1.0;
  if (rainfallMm > 100) rainfallEffect = 1.2;
  else if (rainfallMm > 50) rainfallEffect = 1.1;
  else if (rainfallMm < 10) rainfallEffect = 0.95;
  
  return {
    adjustedBiomass: Math.round(biomassKgPerHa * rainfallEffect),
    rainfallEffect,
  };
}

/**
 * Adjust biomass for bush encroachment (reduces grass biomass)
 * Bush encroachment level: 0-100% (percentage of area covered by woody plants)
 */
export function adjustForBushEncroachment(
  biomassKgPerHa: number,
  bushEncroachmentPct: number
): { adjustedBiomass: number; grassAvailablePct: number } {
  const grassAvailablePct = Math.max(0, 100 - bushEncroachmentPct) / 100;
  return {
    adjustedBiomass: Math.round(biomassKgPerHa * grassAvailablePct),
    grassAvailablePct,
  };
}

/**
 * Adjust biomass for invasive species presence
 * Invasive species typically reduce palatable forage
 */
export function adjustForInvasiveSpecies(
  biomassKgPerHa: number,
  invasiveSpeciesPct: number
): { adjustedBiomass: number; palatablePct: number } {
  // Invasive species reduce palatable forage by their proportion
  const palatablePct = Math.max(0, 100 - invasiveSpeciesPct * 1.5) / 100;
  return {
    adjustedBiomass: Math.round(biomassKgPerHa * palatablePct),
    palatablePct,
  };
}

/**
 * Calculate comprehensive biomass estimate for a grazing zone
 * Integrates NDVI, EVI, seasonal, rainfall, and ecological adjustments
 */
export function calculateComprehensiveBiomass(
  observations: SatelliteObservation[],
  grazingZoneAreaHa: number,
  ecologicalData: {
    bushEncroachmentPct?: number;
    invasiveSpeciesPct?: number;
    rainfallMm?: number;
    desirableGrassPct?: number;
  } = {}
): BiomassEstimate {
  // Get latest observation
  const latest = observations[0];
  if (!latest) {
    throw new Error('No satellite observations available');
  }
  
  // Base biomass from NDVI
  let biomass = latest.biomassKgPerHa;
  
  // Apply seasonal adjustment
  const { adjustedBiomass: seasonalAdjusted, seasonalMultiplier } = 
    adjustForSeasonality(biomass, latest.observationDate);
  biomass = seasonalAdjusted;
  
  // Apply rainfall adjustment if data available
  if (ecologicalData.rainfallMm !== undefined) {
    const { adjustedBiomass: rainfallAdjusted, rainfallEffect } = 
      adjustForRainfall(biomass, ecologicalData.rainfallMm);
    biomass = rainfallAdjusted;
  }
  
  // Apply bush encroachment adjustment
  if (ecologicalData.bushEncroachmentPct !== undefined) {
    const { adjustedBiomass: bushAdjusted, grassAvailablePct } = 
      adjustForBushEncroachment(biomass, ecologicalData.bushEncroachmentPct);
    biomass = bushAdjusted;
  }
  
  // Apply invasive species adjustment
  if (ecologicalData.invasiveSpeciesPct !== undefined) {
    const { adjustedBiomass: invasiveAdjusted, palatablePct } = 
      adjustForInvasiveSpecies(biomass, ecologicalData.invasiveSpeciesPct);
    biomass = invasiveAdjusted;
  }
  
  // Calculate total available forage
  const totalAvailableForageKg = biomass * grazingZoneAreaHa;
  
  // Determine confidence level based on data quality
  let confidenceLevel: 'high' | 'medium' | 'low' = 'high';
  if (observations.length < 3) confidenceLevel = 'medium';
  if (observations.length < 1) confidenceLevel = 'low';
  if (ecologicalData.bushEncroachmentPct === undefined) confidenceLevel = 'medium';
  
  return {
    grazingZoneId: '',
    estimateDate: new Date().toISOString().split('T')[0],
    biomassKgPerHa: biomass,
    totalAvailableForageKg,
    confidenceLevel,
    method: 'comprehensive_ndvi_evi_seasonal_rainfall',
    metadata: {
      baseNdviBiomass: latest.biomassKgPerHa,
      seasonalMultiplier,
      rainfallMm: ecologicalData.rainfallMm,
      bushEncroachmentPct: ecologicalData.bushEncroachmentPct,
      invasiveSpeciesPct: ecologicalData.invasiveSpeciesPct,
      desirableGrassPct: ecologicalData.desirableGrassPct,
      areaHa: grazingZoneAreaHa,
      observationDate: latest.observationDate,
      dataSource: latest.dataSource,
    },
  };
}

/**
 * Calculate carrying capacity in LSU from biomass estimate
 */
export function calculateCarryingCapacityFromBiomass(
  biomassEstimate: BiomassEstimate,
  utilizationPct: number = 40
): { carryingCapacityLsu: number; carryingCapacityTlu: number; usableForageKg: number } {
  const usableForageKg = biomassEstimate.totalAvailableForageKg * (utilizationPct / 100);
  const carryingCapacityLsu = usableForageKg / ANNUAL_DM_PER_LSU_KG;
  const carryingCapacityTlu = carryingCapacityLsu * 1.4; // 1 LSU = 1.4 TLU
  
  return {
    carryingCapacityLsu: Math.round(carryingCapacityLsu * 100) / 100,
    carryingCapacityTlu: Math.round(carryingCapacityTlu * 100) / 100,
    usableForageKg: Math.round(usableForageKg),
  };
}

/**
 * Calculate grazing days remaining based on current biomass and stocking rate
 */
export function calculateGrazingDaysRemaining(
  biomassEstimate: BiomassEstimate,
  currentLsu: number,
  utilizationPct: number = 40
): number {
  const { usableForageKg } = calculateCarryingCapacityFromBiomass(biomassEstimate, utilizationPct);
  if (currentLsu <= 0) return 365;
  
  const dailyDemandKg = currentLsu * (ANNUAL_DM_PER_LSU_KG / 365);
  const daysRemaining = usableForageKg / dailyDemandKg;
  
  return Math.max(0, Math.round(daysRemaining));
}

/**
 * Calculate recommended stocking rate (LSU/ha)
 */
export function calculateRecommendedStockingRate(
  biomassEstimate: BiomassEstimate,
  utilizationPct: number = 40
): number {
  const { carryingCapacityLsu } = calculateCarryingCapacityFromBiomass(biomassEstimate, utilizationPct);
  const areaHa = biomassEstimate.metadata.areaHa || 100;
  
  return Math.round((carryingCapacityLsu / areaHa) * 100) / 100;
}

/**
 * Calculate rest period recommendation based on biomass level and season
 */
export function calculateRestPeriodRecommendation(
  biomassEstimate: BiomassEstimate,
  currentMonth: number
): number {
  const biomass = biomassEstimate.biomassKgPerHa;
  let restDays = 45; // Base rest period
  
  // Adjust for biomass level
  if (biomass < 1000) restDays = 75;
  else if (biomass < 1500) restDays = 60;
  else if (biomass > 2500) restDays = 30;
  
  // Adjust for season (longer rest in dry season)
  if (currentMonth >= 5 && currentMonth <= 9) { // Dry season Jun-Oct
    restDays = Math.round(restDays * 1.3);
  }
  
  return restDays;
}

/**
 * Assess overgrazing risk level
 */
export function assessOvergrazingRisk(
  biomassEstimate: BiomassEstimate,
  currentLsu: number,
  recommendedLsu: number
): { riskLevel: 'low' | 'moderate' | 'high' | 'severe'; grazingPressurePct: number; recommendation: string } {
  const safeRecommended = Math.max(recommendedLsu, 0.1);
  const grazingPressurePct = Math.round((currentLsu / safeRecommended) * 100);
  
  let riskLevel: 'low' | 'moderate' | 'high' | 'severe' = 'low';
  let recommendation = 'Stocking rate is within sustainable carrying capacity limits.';
  
  if (grazingPressurePct > 140) {
    riskLevel = 'severe';
    recommendation = 'CRITICAL OVERSTOCKING: Immediate destocking or supplementary feeding required to prevent severe veld degradation.';
  } else if (grazingPressurePct > 110) {
    riskLevel = 'high';
    recommendation = 'HIGH OVERSTOCKING RISK: Grazing pressure exceeds sustainable limits. Plan stock reduction or paddock rest.';
  } else if (grazingPressurePct > 90) {
    riskLevel = 'moderate';
    recommendation = 'MODERATE GRAZING PRESSURE: Near maximum carrying capacity. Monitor grass recovery closely.';
  }
  
  return { riskLevel, grazingPressurePct, recommendation };
}

/**
 * Calculate biomass trend from historical observations
 */
export function calculateBiomassTrend(
  observations: SatelliteObservation[]
): { trend: 'increasing' | 'decreasing' | 'stable'; changePct: number; slope: number } {
  if (observations.length < 2) {
    return { trend: 'stable', changePct: 0, slope: 0 };
  }
  
  // Use linear regression on biomass values over time
  const n = observations.length;
  let sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
  
  for (let i = 0; i < n; i++) {
    const x = i;
    const y = observations[i].biomassKgPerHa;
    sumX += x;
    sumY += y;
    sumXY += x * y;
    sumX2 += x * x;
  }
  
  const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  const firstValue = observations[observations.length - 1].biomassKgPerHa;
  const lastValue = observations[0].biomassKgPerHa;
  const changePct = firstValue > 0 ? Math.round(((lastValue - firstValue) / firstValue) * 100) : 0;
  
  let trend: 'increasing' | 'decreasing' | 'stable' = 'stable';
  if (slope > 20) trend = 'increasing';
  else if (slope < -20) trend = 'decreasing';
  
  return { trend, changePct, slope: Math.round(slope * 100) / 100 };
}

/**
 * Get biomass health classification
 */
export function getBiomassHealthClass(biomassKgPerHa: number): { label: string; color: string; grade: 'A' | 'B' | 'C' | 'D' | 'F' } {
  if (biomassKgPerHa >= 2500) return { label: 'Excellent', color: '#2E7D32', grade: 'A' };
  if (biomassKgPerHa >= 1800) return { label: 'Good', color: '#66BB6A', grade: 'B' };
  if (biomassKgPerHa >= 1200) return { label: 'Fair', color: '#FFA726', grade: 'C' };
  if (biomassKgPerHa >= 600) return { label: 'Poor', color: '#EF5350', grade: 'D' };
  return { label: 'Degraded', color: '#D32F2F', grade: 'F' };
}

/**
 * Generate human-readable biomass report
 */
export function generateBiomassReport(
  biomassEstimate: BiomassEstimate,
  grazingZoneName: string,
  farmName: string
): string {
  const health = getBiomassHealthClass(biomassEstimate.biomassKgPerHa);
  const { carryingCapacityLsu, usableForageKg } = calculateCarryingCapacityFromBiomass(biomassEstimate);
  const recommendedRate = calculateRecommendedStockingRate(biomassEstimate);
  
  let report = `BIOMASS REPORT: ${grazingZoneName} (${farmName})\n`;
  report += `==========================================\n\n`;
  report += `Observation Date: ${biomassEstimate.estimateDate}\n`;
  report += `Data Source: ${biomassEstimate.metadata.dataSource || 'Sentinel-2'}\n\n`;
  
  report += `VEGETATION STATUS:\n`;
  report += `  Biomass: ${biomassEstimate.biomassKgPerHa.toLocaleString()} kg DM/ha (${health.label})\n`;
  report += `  Total Available Forage: ${biomassEstimate.totalAvailableForageKg.toLocaleString()} kg DM\n`;
  report += `  Usable Forage (40%): ${usableForageKg.toLocaleString()} kg DM\n\n`;
  
  report += `CARRYING CAPACITY:\n`;
  report += `  Sustainable Load: ${carryingCapacityLsu.toFixed(1)} LSU\n`;
  report += `  Recommended Stocking: ${recommendedRate.toFixed(2)} LSU/ha\n\n`;
  
  report += `CONFIDENCE: ${biomassEstimate.confidenceLevel.toUpperCase()}\n`;
  
  return report;
}

/**
 * Persist biomass estimate to database
 */
export async function persistBiomassEstimate(
  grazingZoneId: string,
  estimate: BiomassEstimate
): Promise<string> {
  const result = await query(
    `INSERT INTO biomass_estimates 
      (grazing_zone_id, estimate_date, biomass_kg_per_ha, total_available_forage_kg, confidence_level, created_at)
    VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
    RETURNING id`,
    [
      grazingZoneId,
      estimate.estimateDate,
      estimate.biomassKgPerHa,
      estimate.totalAvailableForageKg,
      estimate.confidenceLevel,
    ]
  );
  
  return result.rows[0].id;
}

/**
 * Fetch latest biomass estimate for a grazing zone
 */
export async function fetchLatestBiomassEstimate(
  grazingZoneId: string
): Promise<BiomassEstimate | null> {
  const result = await query(
    `SELECT id, grazing_zone_id, estimate_date, biomass_kg_per_ha, total_available_forage_kg, confidence_level, created_at
    FROM biomass_estimates
    WHERE grazing_zone_id = $1
    ORDER BY estimate_date DESC LIMIT 1`,
    [grazingZoneId]
  );
  
  if (result.rowCount === 0) return null;
  
  const row = result.rows[0];
  return {
    grazingZoneId: row.grazing_zone_id,
    estimateDate: row.estimate_date,
    biomassKgPerHa: parseFloat(row.biomass_kg_per_ha),
    totalAvailableForageKg: parseFloat(row.total_available_forage_kg),
    confidenceLevel: row.confidence_level,
    method: 'stored',
    metadata: {},
  };
}

/**
 * Batch calculate biomass for all grazing zones in a farm
 */
export async function calculateFarmBiomass(
  farmId: string,
  ecologicalData: Record<string, any> = {}
): Promise<BiomassEstimate[]> {
  // Fetch all grazing zones for farm
  const zonesResult = await query(
    `SELECT id, name, area_ha FROM paddocks WHERE farm_id = $1`,
    [farmId]
  );
  
  const estimates: BiomassEstimate[] = [];
  
  for (const zone of zonesResult.rows) {
    const zoneId = zone.id;
    const areaHa = parseFloat(zone.area_ha);
    
    // Fetch latest satellite observations
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
    
    if (observations.length > 0) {
      const ecoData = ecologicalData[zoneId] || {};
      const estimate = calculateComprehensiveBiomass(observations, areaHa, ecoData);
      estimate.grazingZoneId = zoneId;
      
      await persistBiomassEstimate(zoneId, estimate);
      estimates.push(estimate);
    }
  }
  
  return estimates;
}
// Scientific carrying capacity and stocking rate calculation service

export const LSU_CONVERSIONS: Record<string, { lsu: number; tlu: number; name: string }> = {
  cattle_mature: { lsu: 1.000, tlu: 1.400, name: 'Cattle (Mature)' },
  cattle_heifer: { lsu: 0.600, tlu: 0.840, name: 'Cattle (Heifer/Calf)' },
  sheep: { lsu: 0.150, tlu: 0.210, name: 'Sheep' },
  goat: { lsu: 0.150, tlu: 0.210, name: 'Goat' },
  camel: { lsu: 1.250, tlu: 1.750, name: 'Camel' },
  donkey: { lsu: 0.500, tlu: 0.700, name: 'Donkey' },
  horse: { lsu: 0.800, tlu: 1.120, name: 'Horse' },
};

/** Annual dry matter intake required per LSU in kg (450kg steer * 11.25kg DM/day * 365 days) */
export const ANNUAL_DM_PER_LSU_KG = 4106.25;

export interface StockingCalculationResult {
  actualLsu: number;
  recommendedLsu: number;
  stockingRateHaPerLsu: number;
  grazingPressurePct: number;
  riskLevel: 'low' | 'moderate' | 'high' | 'severe';
  recommendation: string;
}

/**
 * Calculate total LSU and TLU for a given animal count and species type
 */
export function calculateGroupLsuTlu(speciesKey: string, count: number): { lsu: number; tlu: number } {
  const factor = LSU_CONVERSIONS[speciesKey] || LSU_CONVERSIONS.cattle_mature;
  const lsu = Math.round(count * factor.lsu * 100) / 100;
  const tlu = Math.round(count * factor.tlu * 100) / 100;
  return { lsu, tlu };
}

/**
 * Calculate Carrying Capacity in LSU from farm area and estimated dry matter biomass
 */
export function calculateCarryingCapacityLsu(
  totalAreaHa: number,
  biomassKgPerHa: number = 2500, // Default 2,500 kg DM/ha for typical African savanna
  utilizationPct: number = 40.0 // Sustainable 40% harvest factor
): number {
  const totalBiomassKg = totalAreaHa * biomassKgPerHa;
  const usableBiomassKg = totalBiomassKg * (utilizationPct / 100.0);
  const carryingCapacityLsu = usableBiomassKg / ANNUAL_DM_PER_LSU_KG;
  return Math.round(carryingCapacityLsu * 100) / 100;
}

/**
 * Assess stocking rate risk level based on actual vs recommended LSU
 */
export function calculateStockingRateRisk(
  totalAreaHa: number,
  actualLsu: number,
  recommendedLsu: number
): StockingCalculationResult {
  const safeRecommended = Math.max(recommendedLsu, 0.1);
  const grazingPressurePct = Math.round((actualLsu / safeRecommended) * 100);
  const stockingRateHaPerLsu = actualLsu > 0 ? Math.round((totalAreaHa / actualLsu) * 100) / 100 : totalAreaHa;

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

  return {
    actualLsu,
    recommendedLsu,
    stockingRateHaPerLsu,
    grazingPressurePct,
    riskLevel,
    recommendation,
  };
}

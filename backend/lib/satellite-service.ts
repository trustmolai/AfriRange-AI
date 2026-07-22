// Satellite pre-computed NDVI data fetcher mock service

export interface SatelliteRecord {
  observationDate: string;
  ndviValue: number;
  eviValue: number;
  biomassKgPerHa: number;
  dataSource: string;
}

/**
 * Fetch simulated NDVI vegetation metrics representing pre-aggregated Sentinel-2 stats
 */
export async function getPaddockSatelliteData(paddockId: string, limit: number = 6): Promise<SatelliteRecord[]> {
  const records: SatelliteRecord[] = [];
  const now = new Date();

  // Generate historical seasonal profile points (last 6 months)
  for (let i = limit - 1; i >= 0; i--) {
    const date = new Date(now.getFullYear(), now.getMonth() - i, 15);
    const month = date.getMonth();
    
    // Simulate typical seasonal chlorophyll index curve (Peak wet season vs dry winter)
    // Southern Africa peak: Jan/Feb (High NDVI), dry peak: Jun/Jul (Low NDVI)
    let ndviValue = 0.35; // default baseline dry
    if (month >= 10 || month <= 3) {
      ndviValue = 0.65; // wet summer growth
    } else if (month >= 4 && month <= 9) {
      ndviValue = 0.28; // dry winter dormant
    }

    // Add small random fluctuation
    ndviValue = Math.max(0.1, Math.min(1.0, ndviValue + (Math.random() - 0.5) * 0.08));
    const eviValue = ndviValue * 0.85;

    // Biomass Dry Matter Yield calculation formula: Yield = (NDVI * 3200) + 400
    const biomassKgPerHa = Math.round(ndviValue * 3200 + 400);

    records.push({
      observationDate: date.toISOString().split('T')[0],
      ndviValue: parseFloat(ndviValue.toFixed(4)),
      eviValue: parseFloat(eviValue.toFixed(4)),
      biomassKgPerHa,
      dataSource: 'Sentinel-2',
    });
  }

  return records;
}

import 'package:test/test.dart';
import 'package:afrirange_ai/backend/lib/biomass-estimation.dart';

void main() {
  group('Biomass Estimation Service', () {
    
    test('calculateBiomassFromNdvi returns correct values', () {
      expect(calculateBiomassFromNdvi(0.0), equals(400));
      expect(calculateBiomassFromNdvi(0.5), equals(2000));
      expect(calculateBiomassFromNdvi(1.0), equals(3600));
      expect(calculateBiomassFromNdvi(-0.5), equals(0)); // max(0, -0.5*3200+400) = max(0, -1200) = 0
    });

    test('calculateBiomassFromEvi returns correct values', () {
      expect(calculateBiomassFromEvi(0.0), equals(200));
      expect(calculateBiomassFromEvi(0.5), equals(2100));
      expect(calculateBiomassFromEvi(1.0), equals(4000));
    });

    test('calculateSavi returns correct values', () {
      expect(calculateSavi(0.5, 0.3), closeTo(0.235, epsilon: 0.001));
      expect(calculateSavi(0.8, 0.2), closeTo(0.483, epsilon: 0.001));
      expect(calculateSavi(0.0, 0.5), equals(0.0));
    });

    test('calculateBareGroundIndex returns correct values', () {
      expect(calculateBareGroundIndex(0.0), equals(1.0));
      expect(calculateBareGroundIndex(0.5), equals(0.333, epsilon: 0.001));
      expect(calculateBareGroundIndex(1.0), equals(0.0));
      expect(calculateBareGroundIndex(-0.5), equals(3.0));
    });

    test('adjustForSeasonality applies correct multipliers', () {
      // Test wet season (Jan)
      final wetResult = adjustForSeasonality(1000, '2026-01-15');
      expect(wetResult.seasonalMultiplier, equals(1.15));
      expect(wetResult.adjustedBiomass, equals(1150));
      
      // Test dry season (Jul)
      final dryResult = adjustForSeasonality(1000, '2026-07-15');
      expect(dryResult.seasonalMultiplier, equals(0.85));
      expect(dryResult.adjustedBiomass, equals(850));
      
      // Test transition (Apr)
      final transitionResult = adjustForSeasonality(1000, '2026-04-15');
      expect(transitionResult.seasonalMultiplier, equals(1.0));
      expect(transitionResult.adjustedBiomass, equals(1000));
    });

    test('adjustForRainfall applies correct multipliers', () {
      expect(adjustForRainfall(1000, 150).rainfallEffect, equals(1.2));
      expect(adjustForRainfall(1000, 150).adjustedBiomass, equals(1200));
      
      expect(adjustForRainfall(1000, 75).rainfallEffect, equals(1.1));
      expect(adjustForRainfall(1000, 75).adjustedBiomass, equals(1100));
      
      expect(adjustForRainfall(1000, 5).rainfallEffect, equals(0.95));
      expect(adjustForRainfall(1000, 5).adjustedBiomass, equals(950));
    });

    test('adjustForBushEncroachment reduces biomass correctly', () {
      expect(adjustForBushEncroachment(1000, 0).grassAvailablePct, equals(1.0));
      expect(adjustForBushEncroachment(1000, 0).adjustedBiomass, equals(1000));
      
      expect(adjustForBushEncroachment(1000, 50).grassAvailablePct, equals(0.5));
      expect(adjustForBushEncroachment(1000, 50).adjustedBiomass, equals(500));
      
      expect(adjustForBushEncroachment(1000, 100).grassAvailablePct, equals(0.0));
      expect(adjustForBushEncroachment(1000, 100).adjustedBiomass, equals(0));
    });

    test('adjustForInvasiveSpecies reduces palatable forage correctly', () {
      expect(adjustForInvasiveSpecies(1000, 0).palatablePct, equals(1.0));
      expect(adjustForInvasiveSpecies(1000, 0).adjustedBiomass, equals(1000));
      
      expect(adjustForInvasiveSpecies(1000, 20).palatablePct, equals(0.7));
      expect(adjustForInvasiveSpecies(1000, 20).adjustedBiomass, equals(700));
      
      expect(adjustForInvasiveSpecies(1000, 60).palatablePct, equals(0.1));
      expect(adjustForInvasiveSpecies(1000, 60).adjustedBiomass, equals(100));
    });

    test('calculateComprehensiveBiomass integrates all factors', () {
      final observations = [
        SatelliteObservation(
          id: 'obs1',
          observationDate: '2026-06-15',
          ndviValue: 0.5,
          eviValue: 0.4,
          biomassKgPerHa: 2000, // (0.5 * 3200) + 400
          dataSource: 'Sentinel-2',
        ),
      ];
      
      final result = calculateComprehensiveBiomass(
        observations,
        100.0, // 100 ha
        {
          'bushEncroachmentPct': 20,
          'invasiveSpeciesPct': 10,
          'rainfallMm': 75,
          'desirableGrassPct': 70,
        },
      );
      
      // Base biomass: 2000 kg/ha
      // Seasonal adjustment (June): 0.85 -> 1700
      // Rainfall adjustment (75mm): 1.1 -> 1870
      // Bush encroachment (20%): 0.8 -> 1496
      // Invasive species (10%): 0.85 -> 1271.6 -> 1272
      // Total forage: 1272 * 100 = 127200 kg
      
      expect(result.biomassKgPerHa, equals(1272));
      expect(result.totalAvailableForageKg, equals(127200));
      expect(result.confidenceLevel, equals('high'));
    });

    test('calculateCarryingCapacityFromBiomass works correctly', () {
      const estimate = BiomassEstimate(
        grazingZoneId: 'zone1',
        estimateDate: '2026-06-15',
        biomassKgPerHa: 2000,
        totalAvailableForageKg: 200000, // 2000 kg/ha * 100 ha
        confidenceLevel: 'high',
        method: 'test',
        metadata: {'areaHa': 100.0},
      );
      
      final result = calculateCarryingCapacityFromBiomass(estimate, 40);
      
      // Usable forage: 200000 * 0.4 = 80000 kg
      // Carrying capacity LSU: 80000 / 4106.25 = 19.48
      // Carrying capacity TLU: 19.48 * 1.4 = 27.27
      
      expect(result.carryingCapacityLsu, closeTo(19.48, epsilon: 0.01));
      expect(result.carryingCapacityTlu, closeTo(27.27, epsilon: 0.01));
      expect(result.usableForageKg, equals(80000));
    });

    test('calculateGrazingDaysRemaining works correctly', () {
      const estimate = BiomassEstimate(
        grazingZoneId: 'zone1',
        estimateDate: '2026-06-15',
        biomassKgPerHa: 2000,
        totalAvailableForageKg: 200000, // 2000 kg/ha * 100 ha
        confidenceLevel: 'high',
        method: 'test',
        metadata: {'areaHa': 100.0},
      );
      
      // With 10 LSU grazing:
      // Daily demand: 10 * (4106.25/365) = 112.5 kg/day
      // Days remaining: 200000 * 0.4 / 112.5 = 711 days
      final days = calculateGrazingDaysRemaining(estimate, 10);
      expect(days, equals(711));
      
      // With 0 LSU grazing:
      final daysZero = calculateGrazingDaysRemaining(estimate, 0);
      expect(daysZero, equals(365)); // Max capped at 365
    });

    test('calculateRecommendedStockingRate works correctly', () {
      const estimate = BiomassEstimate(
        grazingZoneId: 'zone1',
        estimateDate: '2026-06-15',
        biomassKgPerHa: 2000,
        totalAvailableForageKg: 200000,
        confidenceLevel: 'high',
        method: 'test',
        metadata: {'areaHa': 100.0},
      );
      
      // Carrying capacity LSU: 200000 * 0.4 / 4106.25 = 19.48 LSU
      // Stocking rate: 19.48 LSU / 100 ha = 0.1948 LSU/ha
      final rate = calculateRecommendedStockingRate(estimate, 40);
      expect(rate, closeTo(0.19, epsilon: 0.01));
    });

    test('calculateRestPeriodRecommendation adjusts for biomass and season', () {
      const estimateLowBiomass = BiomassEstimate(
        grazingZoneId: 'zone1',
        estimateDate: '2026-06-15',
        biomassKgPerHa: 800,
        totalAvailableForageKg: 80000,
        confidenceLevel: 'high',
        method: 'test',
        metadata: {'areaHa': 100.0},
      );
      
      const estimateHighBiomass = BiomassEstimate(
        grazingZoneId: 'zone1',
        estimateDate: '2026-06-15',
        biomassKgPerHa: 3000,
        totalAvailableForageKg: 300000,
        confidenceLevel: 'high',
        method: 'test',
        metadata: {'areaHa': 100.0},
      );
      
      // Low biomass (<1000) in June (month 5) should give 75 * 1.3 = 97.5 -> 98 days
      final restLow = calculateRestPeriodRecommendation(estimateLowBiomass, 5);
      expect(restLow, equals(98));
      
      // High biomass (>2500) in June should give 30 * 1.3 = 39 days
      final restHigh = calculateRestPeriodRecommendation(estimateHighBiomass, 5);
      expect(restHigh, equals(39));
    });

    test('assessOvergrazingRisk returns correct risk levels', () {
      const estimate = BiomassEstimate(
        grazingZoneId: 'zone1',
        estimateDate: '2026-06-15',
        biomassKgPerHa: 2000,
        totalAvailableForageKg: 200000,
        confidenceLevel: 'high',
        method: 'test',
        metadata: {'areaHa': 100.0},
      );
      
      // Test severe overstocking (200% of carrying capacity)
      final severeRisk = assessOvergrazingRisk(estimate, 40, 20); // 40 actual vs 20 recommended
      expect(severeRisk.riskLevel, equals('severe'));
      expect(severeRisk.grazingPressurePct, equals(200));
      
      // Test high overstocking (120%)
      final highRisk = assessOvergrazingRisk(estimate, 24, 20);
      expect(highRisk.riskLevel, equals('high'));
      expect(highRisk.grazingPressurePct, equals(120));
      
      // Test moderate overstocking (95%)
      final moderateRisk = assessOvergrazingRisk(estimate, 19, 20);
      expect(moderateRisk.riskLevel, equals('moderate'));
      expect(moderateRisk.grazingPressurePct, equals(95));
      
      // Test normal (80%)
      final lowRisk = assessOvergrazingRisk(estimate, 16, 20);
      expect(lowRisk.riskLevel, equals('low'));
      expect(lowRisk.grazingPressurePct, equals(80));
    });

    test('calculateBiomassTrend identifies trends correctly', () {
      const observations = [
        SatelliteObservation(
          id: 'obs1',
          observationDate: '2026-01-15',
          ndviValue: 0.3,
          eviValue: 0.25,
          biomassKgPerHa: 1360,
          dataSource: 'Sentinel-2',
        ),
        SatelliteObservation(
          id: 'obs2',
          observationDate: '2026-02-15',
          ndviValue: 0.35,
          eviValue: 0.3,
          biomassKgPerHa: 1520,
          dataSource: 'Sentinel-2',
        ),
        SatelliteObservation(
          id: 'obs3',
          observationDate: '2026-03-15',
          ndviValue: 0.4,
          eviValue: 0.35,
          biomassKgPerHa: 1680,
          dataSource: 'Sentinel-2',
        ),
      ];
      
      final trend = calculateBiomassTrend(observations);
      expect(trend.trend, equals('increasing'));
      expect(trend.changePct, greaterThan(0));
      expect(trend.slope, greaterThan(0));
    });

    test('getBiomassHealthClass returns correct classifications', () {
      expect(getBiomassHealthClass(2600).label, equals('Excellent'));
      expect(getBiomassHealthClass(2600).grade, equals('A'));
      
      expect(getBiomassHealthClass(2000).label, equals('Good'));
      expect(getBiomassHealthClass(2000).grade, equals('B'));
      
      expect(getBiomassHealthClass(1400).label, equals('Fair'));
      expect(getBiomassHealthClass(1400).grade, equals('C'));
      
      expect(getBiomassHealthClass(800).label, equals('Poor'));
      expect(getBiomassHealthClass(800).grade, equals('D'));
      
      expect(getBiomassHealthClass(300).label, equals('Degraded'));
      expect(getBiomassHealthClass(300).grade, equals('F'));
    });
  });
}
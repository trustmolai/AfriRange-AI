import 'package:flutter_test/flutter_test.dart';
import 'package:afrirange_ai/features/veld_management/carrying_capacity_calculator.dart';

void main() {
  group('CarryingCapacityCalculator Unit Tests', () {
    test('calculateVcs computes ecological score accurately', () {
      final vcs = CarryingCapacityCalculator.calculateVcs(
        decreaserPct: 50.0,
        increaserIIPct: 30.0,
        toxicInvaderPct: 5.0,
      );

      // Decreaser (50*1) = 50
      // Increaser I (15*0.7) = 10.5
      // Increaser II (30*0.4) = 12
      // Toxic (5*1.5) = -7.5
      // Total = 65.0
      expect(vcs, closeTo(65.0, 0.1));
    });

    test('calculateLsuPerHa respects minimum and maximum bounds', () {
      final lowCapacity = CarryingCapacityCalculator.calculateLsuPerHa(vcs: 10.0, ndvi: 0.20);
      expect(lowCapacity, greaterThanOrEqualTo(0.05));

      final highCapacity = CarryingCapacityCalculator.calculateLsuPerHa(vcs: 95.0, ndvi: 0.75);
      expect(highCapacity, lessThanOrEqualTo(0.60));
    });

    test('calculateRestDays returns appropriate rotational rest durations', () {
      expect(CarryingCapacityCalculator.calculateRestDays(35.0), equals(75)); // Severe rest
      expect(CarryingCapacityCalculator.calculateRestDays(50.0), equals(45)); // Moderate rest
      expect(CarryingCapacityCalculator.calculateRestDays(70.0), equals(30)); // Prime condition rest
    });
  });
}

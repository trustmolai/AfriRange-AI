import 'package:latlong2/latlong.dart';
import 'dart:math';

class AreaCalculator {
  /// Geodesic area calculation in hectares using the Shoelace formula on WGS84 coordinates.
  /// Converts lat/lng spherical polygon points into approximate surface area in hectares.
  static double calculateHectares(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    const double earthRadiusMeters = 6378137.0; // WGS84 equatorial radius
    double totalAreaSquareMeters = 0.0;

    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];

      final lat1Rad = p1.latitude * (pi / 180.0);
      final lat2Rad = p2.latitude * (pi / 180.0);
      final lng1Rad = p1.longitude * (pi / 180.0);
      final lng2Rad = p2.longitude * (pi / 180.0);

      totalAreaSquareMeters += (lng2Rad - lng1Rad) * (2 + sin(lat1Rad) + sin(lat2Rad));
    }

    totalAreaSquareMeters = (totalAreaSquareMeters * earthRadiusMeters * earthRadiusMeters / 2.0).abs();
    
    // Convert square meters to hectares (1 ha = 10,000 m²)
    final hectares = totalAreaSquareMeters / 10000.0;
    return double.parse(hectares.toStringAsFixed(2));
  }
}

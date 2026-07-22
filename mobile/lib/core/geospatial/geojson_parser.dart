import 'dart:convert';
import 'package:latlong2/latlong.dart';

class GeoJsonParser {
  /// Convert a list of LatLng boundary points into standard GeoJSON Polygon format JSON string.
  static String pointsToGeoJsonPolygon(List<LatLng> points) {
    if (points.isEmpty) return '';

    final coordinates = points.map((p) => [p.longitude, p.latitude]).toList();
    
    // Ensure ring is closed
    if (coordinates.first[0] != coordinates.last[0] || coordinates.first[1] != coordinates.last[1]) {
      coordinates.add([coordinates.first[0], coordinates.first[1]]);
    }

    final geoJsonMap = {
      'type': 'Polygon',
      'coordinates': [coordinates],
    };

    return jsonEncode(geoJsonMap);
  }

  /// Parse a GeoJSON Polygon JSON map/string into a List of LatLng points.
  static List<LatLng> geoJsonToPoints(dynamic geoJson) {
    Map<String, dynamic> map;
    if (geoJson is String) {
      map = jsonDecode(geoJson);
    } else if (geoJson is Map<String, dynamic>) {
      map = geoJson;
    } else {
      return [];
    }

    if (map['type'] != 'Polygon' || map['coordinates'] == null) return [];

    final rawRing = (map['coordinates'] as List).first as List;
    return rawRing.map((coord) {
      final lng = (coord[0] as num).toDouble();
      final lat = (coord[1] as num).toDouble();
      return LatLng(lat, lng);
    }).toList();
  }

  /// Convert a single LatLng point into GeoJSON Point JSON string.
  static String pointToGeoJsonPoint(LatLng point) {
    return jsonEncode({
      'type': 'Point',
      'coordinates': [point.longitude, point.latitude],
    });
  }

  /// Parse GeoJSON Point to LatLng.
  static LatLng? geoJsonPointToLatLng(dynamic geoJson) {
    Map<String, dynamic> map;
    if (geoJson is String) {
      map = jsonDecode(geoJson);
    } else if (geoJson is Map<String, dynamic>) {
      map = geoJson;
    } else {
      return null;
    }

    if (map['type'] != 'Point' || map['coordinates'] == null) return null;
    final coords = map['coordinates'] as List;
    return LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
  }
}

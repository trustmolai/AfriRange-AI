import 'package:latlong2/latlong.dart';
import '../../../core/geospatial/geojson_parser.dart';

class GrazingZoneModel {
  final String id;
  final String farmId;
  final String name;
  final double areaHa;
  final int targetRestDays;
  final double baselineLsuPerHa;
  final String currentStatus; // 'rested', 'grazing', 'overgrazed', 'recovering'
  final List<LatLng> boundaryPoints;
  final String? syncStatus;

  const GrazingZoneModel({
    required this.id,
    required this.farmId,
    required this.name,
    required this.areaHa,
    this.targetRestDays = 45,
    this.baselineLsuPerHa = 0.200,
    this.currentStatus = 'rested',
    required this.boundaryPoints,
    this.syncStatus = 'synced',
  });

  factory GrazingZoneModel.fromJson(Map<String, dynamic> json) {
    return GrazingZoneModel(
      id: json['id'] as String,
      farmId: json['farmId'] as String,
      name: json['name'] as String,
      areaHa: (json['areaHa'] as num?)?.toDouble() ?? 0.0,
      targetRestDays: json['targetRestDays'] as int? ?? 45,
      baselineLsuPerHa: (json['baselineLsuPerHa'] as num?)?.toDouble() ?? 0.200,
      currentStatus: json['currentStatus'] as String? ?? 'rested',
      boundaryPoints: json['boundary'] != null
          ? GeoJsonParser.geoJsonToPoints(json['boundary'])
          : [],
      syncStatus: json['syncStatus'] as String? ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'name': name,
      'areaHa': areaHa,
      'targetRestDays': targetRestDays,
      'baselineLsuPerHa': baselineLsuPerHa,
      'currentStatus': currentStatus,
      'boundary': GeoJsonParser.pointsToGeoJsonPolygon(boundaryPoints),
      'syncStatus': syncStatus,
    };
  }
}

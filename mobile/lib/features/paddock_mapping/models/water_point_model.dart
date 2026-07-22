import 'package:latlong2/latlong.dart';
import '../../../core/geospatial/geojson_parser.dart';

class WaterPointModel {
  final String id;
  final String farmId;
  final String name;
  final String waterType; // 'borehole', 'dam', 'trough', 'river', 'spring'
  final String status; // 'functional', 'maintenance_needed', 'dry'
  final double? flowRateLph;
  final LatLng location;
  final String? syncStatus;

  const WaterPointModel({
    required this.id,
    required this.farmId,
    required this.name,
    this.waterType = 'borehole',
    this.status = 'functional',
    this.flowRateLph,
    required this.location,
    this.syncStatus = 'synced',
  });

  factory WaterPointModel.fromJson(Map<String, dynamic> json) {
    return WaterPointModel(
      id: json['id'] as String,
      farmId: json['farmId'] as String,
      name: json['name'] as String,
      waterType: json['waterType'] as String? ?? 'borehole',
      status: json['status'] as String? ?? 'functional',
      flowRateLph: (json['flowRateLph'] as num?)?.toDouble(),
      location: json['location'] != null
          ? GeoJsonParser.geoJsonPointToLatLng(json['location']) ?? const LatLng(0, 0)
          : const LatLng(0, 0),
      syncStatus: json['syncStatus'] as String? ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'name': name,
      'waterType': waterType,
      'status': status,
      'flowRateLph': flowRateLph,
      'location': GeoJsonParser.pointToGeoJsonPoint(location),
      'syncStatus': syncStatus,
    };
  }
}

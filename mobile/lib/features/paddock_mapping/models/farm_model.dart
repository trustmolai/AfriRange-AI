import 'package:latlong2/latlong.dart';
import '../../../core/geospatial/geojson_parser.dart';

class FarmModel {
  final String id;
  final String name;
  final String? description;
  final String country;
  final String? region;
  final String? district;
  final String biome;
  final double totalAreaHa;
  final List<LatLng> boundaryPoints;
  final String? syncStatus; // 'synced', 'pending_create', 'pending_update'

  const FarmModel({
    required this.id,
    required this.name,
    this.description,
    required this.country,
    this.region,
    this.district,
    required this.biome,
    required this.totalAreaHa,
    required this.boundaryPoints,
    this.syncStatus = 'synced',
  });

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      country: json['country'] as String? ?? 'South Africa',
      region: json['region'] as String?,
      district: json['district'] as String?,
      biome: json['biome'] as String? ?? 'Savanna',
      totalAreaHa: (json['totalAreaHa'] as num?)?.toDouble() ?? 0.0,
      boundaryPoints: json['boundary'] != null
          ? GeoJsonParser.geoJsonToPoints(json['boundary'])
          : [],
      syncStatus: json['syncStatus'] as String? ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'country': country,
      'region': region,
      'district': district,
      'biome': biome,
      'totalAreaHa': totalAreaHa,
      'boundary': GeoJsonParser.pointsToGeoJsonPolygon(boundaryPoints),
      'syncStatus': syncStatus,
    };
  }
}

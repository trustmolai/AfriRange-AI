class VegetationHealthModel {
  final String id;
  final String observationDate;
  final double ndviValue;
  final double? eviValue;
  final double biomassKgPerHa;
  final String dataSource;

  const VegetationHealthModel({
    required this.id,
    required this.observationDate,
    required this.ndviValue,
    this.eviValue,
    required this.biomassKgPerHa,
    required this.dataSource,
  });

  factory VegetationHealthModel.fromJson(Map<String, dynamic> json) {
    return VegetationHealthModel(
      id: json['id'] as String? ?? '',
      observationDate: json['observationDate'] as String? ?? '',
      ndviValue: (json['ndviValue'] as num?)?.toDouble() ?? 0.0,
      eviValue: (json['eviValue'] as num?)?.toDouble(),
      biomassKgPerHa: (json['biomassKgPerHa'] as num?)?.toDouble() ?? 0.0,
      dataSource: json['dataSource'] as String? ?? 'Sentinel-2',
    );
  }

  /// NDVI health classification for display
  String get healthLabel {
    if (ndviValue >= 0.6) return 'Excellent';
    if (ndviValue >= 0.4) return 'Good';
    if (ndviValue >= 0.25) return 'Fair';
    if (ndviValue >= 0.15) return 'Poor';
    return 'Bare / Degraded';
  }

  /// Color hex for NDVI gauge rendering
  int get healthColorValue {
    if (ndviValue >= 0.6) return 0xFF2E7D32; // Dark green
    if (ndviValue >= 0.4) return 0xFF66BB6A; // Green
    if (ndviValue >= 0.25) return 0xFFFFA726; // Orange
    if (ndviValue >= 0.15) return 0xFFEF5350; // Red
    return 0xFF8D6E63; // Brown
  }
}

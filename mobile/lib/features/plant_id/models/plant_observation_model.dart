class PlantObservationModel {
  final String id;
  final String? farmId;
  final String? grazingZoneId;
  final String scientificName;
  final String commonName;
  final String plantType; // 'grass', 'shrub', 'tree', 'forb', 'sedge', 'weed'
  final double confidenceScore;
  final String toxicityLevel; // 'safe', 'caution', 'poisonous', 'highly_poisonous'
  final String? toxicityDescription;
  final String palatability; // 'high', 'medium', 'low', 'unpalatable'
  final String grazingValue;
  final String managementAdvice;
  final List<String> alternativeMatches;
  final bool userConfirmed;
  final String? userCorrection;
  final String observationDate;

  const PlantObservationModel({
    required this.id,
    this.farmId,
    this.grazingZoneId,
    required this.scientificName,
    required this.commonName,
    required this.plantType,
    required this.confidenceScore,
    required this.toxicityLevel,
    this.toxicityDescription,
    required this.palatability,
    required this.grazingValue,
    required this.managementAdvice,
    required this.alternativeMatches,
    this.userConfirmed = false,
    this.userCorrection,
    required this.observationDate,
  });

  factory PlantObservationModel.fromJson(Map<String, dynamic> json) {
    final ai = json['aiIdentification'] ?? json;
    return PlantObservationModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String?,
      grazingZoneId: json['grazingZoneId'] as String?,
      scientificName: ai['scientificName'] as String? ?? 'Unknown species',
      commonName: ai['commonName'] as String? ?? 'Unknown',
      plantType: ai['plantType'] as String? ?? 'grass',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      toxicityLevel: ai['toxicityLevel'] as String? ?? 'safe',
      toxicityDescription: ai['toxicityDescription'] as String?,
      palatability: ai['palatability'] as String? ?? 'medium',
      grazingValue: ai['grazingValue'] as String? ?? 'medium',
      managementAdvice: ai['managementAdvice'] as String? ?? '',
      alternativeMatches: List<String>.from(ai['alternativeMatches'] ?? []),
      userConfirmed: json['userConfirmed'] as bool? ?? false,
      userCorrection: json['userCorrection'] as String?,
      observationDate: json['observationDate'] as String? ?? '',
    );
  }
}

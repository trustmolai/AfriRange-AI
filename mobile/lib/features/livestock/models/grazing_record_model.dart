class GrazingRecordModel {
  final String id;
  final String grazingZoneId;
  final String livestockGroupId;
  final String? livestockGroupName;
  final String? species;
  final String grazingStartDate;
  final String? grazingEndDate;
  final int numberOfAnimals;
  final double lsuGrazing;
  final int? grazingDays;
  final String? notes;
  final String? syncStatus;

  const GrazingRecordModel({
    required this.id,
    required this.grazingZoneId,
    required this.livestockGroupId,
    this.livestockGroupName,
    this.species,
    required this.grazingStartDate,
    this.grazingEndDate,
    required this.numberOfAnimals,
    required this.lsuGrazing,
    this.grazingDays,
    this.notes,
    this.syncStatus = 'synced',
  });

  factory GrazingRecordModel.fromJson(Map<String, dynamic> json) {
    return GrazingRecordModel(
      id: json['id'] as String,
      grazingZoneId: json['grazingZoneId'] as String,
      livestockGroupId: json['livestockGroupId'] as String,
      livestockGroupName: json['livestockGroupName'] as String?,
      species: json['species'] as String?,
      grazingStartDate: json['grazingStartDate'] as String,
      grazingEndDate: json['grazingEndDate'] as String?,
      numberOfAnimals: json['numberOfAnimals'] as int? ?? 1,
      lsuGrazing: (json['lsuGrazing'] as num?)?.toDouble() ?? 0.0,
      grazingDays: json['grazingDays'] as int?,
      notes: json['notes'] as String?,
      syncStatus: json['syncStatus'] as String? ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grazingZoneId': grazingZoneId,
      'livestockGroupId': livestockGroupId,
      'grazingStartDate': grazingStartDate,
      'grazingEndDate': grazingEndDate,
      'numberOfAnimals': numberOfAnimals,
      'lsuGrazing': lsuGrazing,
      'grazingDays': grazingDays,
      'notes': notes,
      'syncStatus': syncStatus,
    };
  }
}

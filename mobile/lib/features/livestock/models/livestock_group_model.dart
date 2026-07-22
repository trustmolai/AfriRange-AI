import '../../../core/livestock/lsu_calculator.dart';

class LivestockGroupModel {
  final String id;
  final String farmId;
  final String name;
  final String species;
  final String animalClass;
  final int numberOfAnimals;
  final double? averageWeightKg;
  final double lsuValue;
  final double tluValue;
  final String? notes;
  final String? syncStatus;

  const LivestockGroupModel({
    required this.id,
    required this.farmId,
    required this.name,
    required this.species,
    this.animalClass = 'mature',
    required this.numberOfAnimals,
    this.averageWeightKg,
    required this.lsuValue,
    required this.tluValue,
    this.notes,
    this.syncStatus = 'synced',
  });

  factory LivestockGroupModel.fromJson(Map<String, dynamic> json) {
    return LivestockGroupModel(
      id: json['id'] as String,
      farmId: json['farmId'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      animalClass: json['animalClass'] as String? ?? 'mature',
      numberOfAnimals: json['numberOfAnimals'] as int? ?? 1,
      averageWeightKg: (json['averageWeightKg'] as num?)?.toDouble(),
      lsuValue: (json['lsuValue'] as num?)?.toDouble() ?? 0.0,
      tluValue: (json['tluValue'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      syncStatus: json['syncStatus'] as String? ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'name': name,
      'species': species,
      'animalClass': animalClass,
      'numberOfAnimals': numberOfAnimals,
      'averageWeightKg': averageWeightKg,
      'lsuValue': lsuValue,
      'tluValue': tluValue,
      'notes': notes,
      'syncStatus': syncStatus,
    };
  }
}

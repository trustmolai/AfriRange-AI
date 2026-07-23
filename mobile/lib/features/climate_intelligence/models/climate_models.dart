class ClimateModel {
  final String? id;
  final DateTime observationDate;
  final double rainfallMm;
  final double temperatureC;
  final double humidityPercentage;
  final double evapotranspirationMm;
  final String dataSource;
  final double? soilMoisture;

  ClimateModel({
    this.id,
    required this.observationDate,
    required this.rainfallMm,
    required this.temperatureC,
    required this.humidityPercentage,
    required this.evapotranspirationMm,
    required this.dataSource,
    this.soilMoisture,
  });

  factory ClimateModel.fromJson(Map<String, dynamic> json) {
    return ClimateModel(
      id: json['id'] as String?,
      observationDate: json['observationDate'] is DateTime
          ? json['observationDate']
          : DateTime.parse(json['observationDate'] as String),
      rainfallMm: (json['rainfallMm'] as num).toDouble(),
      temperatureC: (json['temperatureC'] as num).toDouble(),
      humidityPercentage: (json['humidityPercentage'] as num).toDouble(),
      evapotranspirationMm: (json['evapotranspirationMm'] as num).toDouble(),
      dataSource: json['dataSource'] as String,
      soilMoisture: json['soilMoisture'] != null
          ? (json['soilMoisture'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'observationDate': observationDate.toIso8601String(),
      'rainfallMm': rainfallMm,
      'temperatureC': temperatureC,
      'humidityPercentage': humidityPercentage,
      'evapotranspirationMm': evapotranspirationMm,
      'dataSource': dataSource,
      if (soilMoisture != null) 'soilMoisture': soilMoisture,
    };
  }
}

class DroughtForecastModel {
  final String id;
  final DateTime forecastDate;
  final int forecastPeriodDays;
  final String droughtRiskLevel;
  final double droughtRiskScore;
  final double rainfallProbability;
  final double forageShortageProbability;
  final double waterStressProbability;
  final double heatStressProbability;
  final int forageDaysRemaining;
  final double? spiValue;
  final double? aniValue;
  final String aiExplanation;
  final DateTime? createdAt;

  DroughtForecastModel({
    required this.id,
    required this.forecastDate,
    required this.forecastPeriodDays,
    required this.droughtRiskLevel,
    required this.droughtRiskScore,
    required this.rainfallProbability,
    required this.forageShortageProbability,
    required this.waterStressProbability,
    required this.heatStressProbability,
    required this.forageDaysRemaining,
    this.spiValue,
    this.aniValue,
    required this.aiExplanation,
    this.createdAt,
  });

  factory DroughtForecastModel.fromJson(Map<String, dynamic> json) {
    return DroughtForecastModel(
      id: json['id'] as String,
      forecastDate: json['forecastDate'] is DateTime
          ? json['forecastDate']
          : DateTime.parse(json['forecastDate'] as String),
      forecastPeriodDays: json['forecastPeriodDays'] as int,
      droughtRiskLevel: json['droughtRiskLevel'] as String,
      droughtRiskScore: (json['droughtRiskScore'] as num).toDouble(),
      rainfallProbability: (json['rainfallProbability'] as num).toDouble(),
      forageShortageProbability:
          (json['forageShortageProbability'] as num).toDouble(),
      waterStressProbability:
          (json['waterStressProbability'] as num).toDouble(),
      heatStressProbability:
          (json['heatStressProbability'] as num).toDouble(),
      forageDaysRemaining: json['forageDaysRemaining'] as int,
      spiValue: json['spiValue'] != null
          ? (json['spiValue'] as num).toDouble()
          : null,
      aniValue: json['aniValue'] != null
          ? (json['aniValue'] as num).toDouble()
          : null,
      aiExplanation: json['aiExplanation'] as String,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt']
              : DateTime.parse(json['createdAt'] as String))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'forecastDate': forecastDate.toIso8601String(),
      'forecastPeriodDays': forecastPeriodDays,
      'droughtRiskLevel': droughtRiskLevel,
      'droughtRiskScore': droughtRiskScore,
      'rainfallProbability': rainfallProbability,
      'forageShortageProbability': forageShortageProbability,
      'waterStressProbability': waterStressProbability,
      'heatStressProbability': heatStressProbability,
      'forageDaysRemaining': forageDaysRemaining,
      'spiValue': spiValue,
      'aniValue': aniValue,
      'aiExplanation': aiExplanation,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class ClimateAlertModel {
  final String id;
  final String alertType;
  final String riskLevel;
  final String title;
  final String message;
  final String recommendedAction;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final bool isAcknowledged;

  ClimateAlertModel({
    required this.id,
    required this.alertType,
    required this.riskLevel,
    required this.title,
    required this.message,
    required this.recommendedAction,
    required this.createdAt,
    this.acknowledgedAt,
    this.isAcknowledged = false,
  });

  factory ClimateAlertModel.fromJson(Map<String, dynamic> json) {
    return ClimateAlertModel(
      id: json['id'] as String,
      alertType: json['alertType'] as String,
      riskLevel: json['riskLevel'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      recommendedAction: json['recommendedAction'] as String,
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt']
          : DateTime.parse(json['createdAt'] as String),
      acknowledgedAt: json['acknowledgedAt'] != null
          ? (json['acknowledgedAt'] is DateTime
              ? json['acknowledgedAt']
              : DateTime.parse(json['acknowledgedAt'] as String))
          : null,
      isAcknowledged: json['isAcknowledged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alertType': alertType,
      'riskLevel': riskLevel,
      'title': title,
      'message': message,
      'recommendedAction': recommendedAction,
      'createdAt': createdAt.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'isAcknowledged': isAcknowledged,
    };
  }
}
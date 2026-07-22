class ClimateModel {
  final String observationDate;
  final double rainfallMm;
  final double temperatureC;
  final double humidityPercentage;
  final double evapotranspirationMm;
  final String dataSource;
  final double? soilMoisture;

  ClimateModel({
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
      observationDate: json['observationDate'],
      rainfallMm: (json['rainfallMm'] as num).toDouble(),
      temperatureC: (json['temperatureC'] as num).toDouble(),
      humidityPercentage: (json['humidityPercentage'] as num).toDouble(),
      evapotransipationMm: (json['evapotranspirationMm'] as num).toDouble(),
      dataSource: json['dataSource'],
      soilMoisture: json['soilMoisture'] != null 
          ? (json['soilMoisture'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'observationDate': observationDate,
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
  final String forecastDate;
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
  final String createdAt;

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
    required this.createdAt,
  });

  factory DroughtForecastModel.fromJson(Map<String, dynamic> json) {
    return DroughtForecastModel(
      id: json['id'],
      forecastDate: json['forecastDate'],
      forecastPeriodDays: json['forecastPeriodDays'],
      droughtRiskLevel: json['droughtRiskLevel'],
      droughtRiskScore: (json['droughtRiskScore'] as num).toDouble(),
      rainfallProbability: (json['rainfallProbability'] as num).toDouble(),
      forageShortageProbability: 
          (json['forageShortageProbability'] as num).toDouble(),
      waterStressProbability: 
          (json['waterStressProbability'] as num).toDouble(),
      heatStressProbability: 
          (json['heatStressProbability'] as num).toDouble(),
      forageDaysRemaining: json['forageDaysRemaining'],
      spiValue: json['spiValue'] != null 
          ? (json['spiValue'] as num).toDouble() 
          : null,
      aniValue: json['aniValue'] != null 
          ? (json['aniValue'] as num).toDouble() 
          : null,
      aiExplanation: json['aiExplanation'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'forecastDate': forecastDate,
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
      'createdAt': createdAt,
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
  final String createdAt;
  final String? acknowledgedAt;
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
    required this.isAcknowledged,
  });

  factory ClimateAlertModel.fromJson(Map<String, dynamic> json) {
    return ClimateAlertModel(
      id: json['id'],
      alertType: json['alertType'],
      riskLevel: json['riskLevel'],
      title: json['title'],
      message: json['message'],
      recommendedAction: json['recommendedAction'],
      createdAt: json['createdAt'],
      acknowledgedAt: json['acknowledgedAt'],
      isAcknowledged: json['isAcknowledged'] ?? false,
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
      'createdAt': createdAt,
      'acknowledgedAt': acknowledgedAt,
      'isAcknowledged': isAcknowledged,
    };
  }
}
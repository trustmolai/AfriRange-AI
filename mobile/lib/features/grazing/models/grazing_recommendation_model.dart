class GrazingRecommendationModel {
  final String id;
  final String? grazingZoneId;
  final String recommendationDate;
  final String recommendedAction;
  final int grazingDaysRemaining;
  final double? recommendedStockingRate;
  final int restPeriodDays;
  final String riskLevel; // 'low', 'moderate', 'high', 'severe'
  final String aiExplanation;

  const GrazingRecommendationModel({
    required this.id,
    this.grazingZoneId,
    required this.recommendationDate,
    required this.recommendedAction,
    required this.grazingDaysRemaining,
    this.recommendedStockingRate,
    required this.restPeriodDays,
    required this.riskLevel,
    required this.aiExplanation,
  });

  factory GrazingRecommendationModel.fromJson(Map<String, dynamic> json) {
    return GrazingRecommendationModel(
      id: json['id'] as String? ?? '',
      grazingZoneId: json['grazingZoneId'] as String?,
      recommendationDate: json['recommendationDate'] as String? ?? '',
      recommendedAction: json['recommendedAction'] as String? ?? '',
      grazingDaysRemaining: json['grazingDaysRemaining'] as int? ?? 0,
      recommendedStockingRate: (json['recommendedStockingRate'] as num?)?.toDouble(),
      restPeriodDays: json['restPeriodDays'] as int? ?? 45,
      riskLevel: json['riskLevel'] as String? ?? 'low',
      aiExplanation: json['aiExplanation'] as String? ?? '',
    );
  }

  /// Risk level display color
  int get riskColorValue {
    switch (riskLevel) {
      case 'severe':
        return 0xFFD32F2F; // Dark red
      case 'high':
        return 0xFFEF5350; // Red
      case 'moderate':
        return 0xFFFFA726; // Orange
      default:
        return 0xFF66BB6A; // Green
    }
  }

  /// Human-readable risk label
  String get riskDisplayLabel {
    switch (riskLevel) {
      case 'severe':
        return '⚠️ SEVERE OVERGRAZING RISK';
      case 'high':
        return '🔴 HIGH RISK';
      case 'moderate':
        return '🟠 MODERATE RISK';
      default:
        return '🟢 LOW RISK';
    }
  }
}

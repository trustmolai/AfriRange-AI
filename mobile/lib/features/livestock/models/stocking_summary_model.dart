class StockingSummaryModel {
  final String farmId;
  final double totalAreaHa;
  final double actualLsu;
  final double actualTlu;
  final double recommendedLsu;
  final double recommendedTlu;
  final double stockingRateHaPerLsu;
  final double grazingPressurePct;
  final String riskLevel; // 'low', 'moderate', 'high', 'severe'
  final String recommendation;

  const StockingSummaryModel({
    required this.farmId,
    required this.totalAreaHa,
    required this.actualLsu,
    required this.actualTlu,
    required this.recommendedLsu,
    required this.recommendedTlu,
    required this.stockingRateHaPerLsu,
    required this.grazingPressurePct,
    required this.riskLevel,
    required this.recommendation,
  });

  factory StockingSummaryModel.fromJson(Map<String, dynamic> json) {
    return StockingSummaryModel(
      farmId: json['farmId'] as String? ?? '',
      totalAreaHa: (json['totalAreaHa'] as num?)?.toDouble() ?? 0.0,
      actualLsu: (json['actualLsu'] as num?)?.toDouble() ?? 0.0,
      actualTlu: (json['actualTlu'] as num?)?.toDouble() ?? 0.0,
      recommendedLsu: (json['recommendedLsu'] as num?)?.toDouble() ?? 0.0,
      recommendedTlu: (json['recommendedTlu'] as num?)?.toDouble() ?? 0.0,
      stockingRateHaPerLsu: (json['stockingRateHaPerLsu'] as num?)?.toDouble() ?? 0.0,
      grazingPressurePct: (json['grazingPressurePct'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['riskLevel'] as String? ?? 'low',
      recommendation: json['recommendation'] as String? ?? '',
    );
  }
}

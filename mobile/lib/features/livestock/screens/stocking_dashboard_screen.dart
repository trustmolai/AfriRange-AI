import 'package:flutter/material.dart';
import '../models/stocking_summary_model.dart';
import 'livestock_list_screen.dart';

class StockingDashboardScreen extends StatefulWidget {
  const StockingDashboardScreen({super.key});

  @override
  State<StockingDashboardScreen> createState() => _StockingDashboardScreenState();
}

class _StockingDashboardScreenState extends State<StockingDashboardScreen> {
  final StockingSummaryModel _summary = const StockingSummaryModel(
    farmId: 'f1',
    totalAreaHa: 1450.50,
    actualLsu: 169.50,
    actualTlu: 237.30,
    recommendedLsu: 290.10,
    recommendedTlu: 406.14,
    stockingRateHaPerLsu: 8.56,
    grazingPressurePct: 58.42,
    riskLevel: 'low',
    recommendation: 'Stocking rate is within sustainable carrying capacity limits.',
  );

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'severe':
        return const Color(0xFF8B0000); // Dark Red
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(_summary.riskLevel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rangeland Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_work),
            tooltip: 'Herd Groups',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const LivestockListScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Risk Card Indicator
            Card(
              color: riskColor.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: riskColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('VELD STOCKING RISK LEVEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      _summary.riskLevel.toUpperCase(),
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: riskColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _summary.recommendation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Analytics Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildMetricCard('Current Load', '${_summary.actualLsu.toStringAsFixed(1)} LSU', Icons.pets),
                _buildMetricCard('Target Limit', '${_summary.recommendedLsu.toStringAsFixed(1)} LSU', Icons.verified_user),
                _buildMetricCard('Stocking Ratio', '${_summary.stockingRateHaPerLsu.toStringAsFixed(2)} Ha/LSU', Icons.compare_arrows),
                _buildMetricCard('Grazing Pressure', '${_summary.grazingPressurePct.toStringAsFixed(1)} %', Icons.show_chart),
              ],
            ),
            const SizedBox(height: 20),

            // Ecological guidelines helper card
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Veld Carrying Capacity Guidelines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('• LSU: 1 Large Stock Unit = 450kg steer equivalent.'),
                    Text('• Target Ratio: Highveld Grassland baseline limit is typically 5.0 - 8.0 Ha/LSU.'),
                    Text('• Rotation advice: Keep grazing periods short (< 14 days) and allow paddocks at least 45-60 days rest.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

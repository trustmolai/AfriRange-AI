import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/climate_api_service.dart';
import '../../auth/providers/auth_provider.dart';

class ClimateDashboardScreen extends StatelessWidget {

  const ClimateDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Climate Intelligence Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Climate Data',
            onPressed: () {
              // Trigger refresh
              final climateService = 
                  Provider.of<ClimateApiService>(context, listen: false);
              climateService.refreshClimateData(
                  Provider.of<AuthProvider>(context, listen: false).currentUser?.farmId ?? '');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final climateService = 
              Provider.of<ClimateApiService>(context, listen: false);
          await climateService.refreshClimateData(
              Provider.of<AuthProvider>(context, listen: false).currentUser?.farmId ?? '');
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Conditions Card
              _buildCurrentConditionsCard(context),
              
              const SizedBox(height: 24),
              
              // Climate Trends
              _buildSectionTitle('Climate Trends'),
              _buildClimateTrendsCharts(context),
              
              const SizedBox(height: 24),
              
              // Drought Risk Assessment
              _buildSectionTitle('Drought Risk Assessment'),
              _buildDroughtRiskCard(context),
              
              const SizedBox(height: 24),
              
              // Forecast Summary
              _buildSectionTitle('Forecast Outlook'),
              _buildForecastSummary(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to detailed forecast view
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DroughtForecastScreen(),
            ),
          );
        },
        tooltip: 'View Detailed Forecasts',
        child: const Icon(Icons.waves),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildCurrentConditionsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Conditions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Consumer<ClimateApiService>(
              builder: (context, climateService, child) {
                // In a real implementation, we would have state management
                // For now, showing placeholder
                return Column(
                  children: [
                    _buildMetricRow('Temperature', '24.5°C', Icons.thermostat),
                    _buildMetricRow('Rainfall (24h)', '3.2 mm', Icons.water_drop),
                    _buildMetricRow('Humidity', '65%', Icons.water),
                    _buildMetricRow('Evapotranspiration', '4.2 mm', Icons.opacity),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClimateTrendsCharts(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Trends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // In a real app, we would use charts like fl_chart or syncfusion
            // For now, showing placeholder
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Temperature & Rainfall Trends\n(Last 12 Months)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDroughtRiskCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Drought Risk Assessment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Drought risk indicator
            _buildRiskIndicator(
              'Overall Drought Risk',
              'Moderate',
              55, // score out of 100
              Colors.orange,
            ),
            const SizedBox(height: 16),
            // Risk factors
            const Text('Risk Factors:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildRiskFactorRow('Precipitation Deficit', 'Moderate', 60),
            _buildRiskFactorRow('Vegetation Stress', 'Low', 30),
            _buildRiskFactorRow('Water Availability', 'Moderate', 55),
            _buildRiskFactorRow('Temperature Anomaly', 'Low', 25),
            _buildRiskFactorRow('Grazing Pressure', 'Low', 35),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskIndicator(String label, String level, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(
              level,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _________________________________________________________________________________________
     
  Widget _buildRiskFactorRow(String label, String level, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRiskColor(score).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$level ($score%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getRiskColor(score),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(int score) {
    if (score >= 70) return Colors.red;
    if (score >= 40) return Colors.orange;
    return Colors.green;
  }

  Widget _buildForecastSummary(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Forecast Outlook',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Forecast tiles for 30, 60, 90 days
            Row(
              children: [
                Expanded(
                  child: _buildForecastTile(
                    '30-Day Outlook',
                    'Moderate Risk',
                    '55%',
                    'Prepare for potential water restrictions',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildForecastTile(
                    '60-Day Outlook',
                    'High Risk',
                    '70%',
                    'Consider livestock reduction planning',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildForecastTile(
                    '90-Day Outlook',
                    'Very High Risk',
                    '80%',
                    'Implement drought contingency plan',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastTile(
      String title, String riskLevel, String riskScore, String recommendation) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getRiskColorFromText(riskLevel),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$riskLevel ($riskScore%)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recommendation,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColorFromText(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'very high':
        return Colors.deepRed;
      default:
        return Colors.grey;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DroughtForecastScreen extends StatelessWidget {
  const DroughtForecastScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drought Forecasts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Forecasts',
            onPressed: () {
              // Refresh forecasts
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Forecast tabs
              DefaultTabController(
                length: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: '30-Day Forecast'),
                        Tab(text: '60-Day Forecast'),
                        Tab(text: '90-Day Forecast'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 400,
                      child: TabBarView(
                        children: [
                          _buildForecastTab(30),
                          _buildForecastTab(60),
                          _buildForecastTab(90),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Generate new forecasts
        },
        tooltip: 'Generate New Forecast',
        child: const Icon(Icons.psychology),
      ),
    );
  }

  Widget _buildForecastTab(int days) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Forecast summary card
          _buildForecastSummaryCard(days),
          const SizedBox(height: 24),
          
          // Detailed metrics
          _buildSectionTitle('Detailed Metrics'),
          _buildDetailedMetrics(days),
          
          const SizedBox(height: 24),
          
          // AI Explanation
          _buildSectionTitle('Expert Analysis'),
          _buildAIExplanation(days),
          
          const SizedBox(height: 24),
          
          // Recommendations
          _buildSectionTitle('Recommended Actions'),
          _buildRecommendations(days),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildForecastSummaryCard(int days) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$days-Day Drought Outlook',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildRiskBadge(55), // Placeholder score
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Drought Risk Level', 'Moderate', Icons.warning),
            _buildMetricRow('Risk Score', '55/100', Icons.analytics),
            _buildMetricRow('Rainfall Probability', '65%', Icons.water_drop),
            _buildMetricRow('Forage Shortage Risk', '40%', Icons.grass),
            _buildMetricRow('Water Stress Risk', '50%', Icons.opacity),
            _buildMetricRow('Heat Stress Risk', '30%', Icons.ac_unit),
            _buildMetricRow('Forecasted Forage Days', '45 days', Icons.grass),
            const Divider(height: 24),
            _buildMetricRow(
                'SPI-3 Value', '-0.8 (Moderately Dry)', Icons.show_chart),
            _buildMetricRow('ANI Value', '0.65 (65%)', Icons.nature),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(int score) {
    Color color;
    String label;
    
    if (score >= 80) {
      color = Colors.red;
      label = 'SEVERE';
    } else if (score >= 60) {
      color = Colors.orange;
      label = 'HIGH';
    } else if (score >= 40) {
      color = Colors.amber;
      label = 'MODERATE';
    } else {
      color = Colors.green;
      label = 'LOW';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetrics(int days) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow('Temperature Anomaly', '+1.2°C', 'Above average'),
            _buildDivider(),
            _buildDetailRow('Rainfall Deviation', '-25%', 'Below normal'),
            _buildDivider(),
            _buildDetailRow('Vegetation Health Index', '0.58', 'Declining'),
            _buildDivider(),
            _buildDetailRow('Soil Moisture Level', '42%', 'Below optimal'),
            _buildDivider(),
            _buildDetailRow('Evapotranspiration Rate', '4.8 mm/day', 'Elevated'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 16);
  }

  Widget _buildAIExplanation(int days) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_alt,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Expert Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Based on current climate indicators, vegetation trends, and hydrological modeling, '
              'the region is experiencing moderate drought conditions. The primary drivers are '
              'below-average precipitation over the past 6 months combined with elevated '
              'temperatures increasing evapotranspiration demand. Vegetation indices show '
              'early signs of stress, particularly in shallow-rooted species. '
              '\n\n'
              'Looking forward, climate models suggest a 65% probability of near-normal '
              'precipitation over the next 30 days, but confidence decreases beyond that '
              'horizon. Soil moisture reserves are adequate for short-term needs but would '
              'be depleted without significant recharge events.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(int days) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 24,
                  color: Colors.green[700],
                ),
                SizedBox(width: 12),
                Text(
                  'Management Recommendations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecommendationItem(
                    '• Increase monitoring frequency to twice weekly',
                    'Track changes in vegetation and soil moisture closely',
                  ),
                  _buildRecommendationItem(
                    '• Review water infrastructure',
                    'Check all water points for leaks and efficiency',
                  ),
                  _buildRecommendationItem(
                    '• Prepare supplementary feed',
                    'Begin procuring hay and concentrate supplements',
                  ),
                  _buildRecommendationItem(
                    '• Consider early weaning',
                    'Reduce nutritional demands on lactating females',
                  ),
                  _buildRecommendationItem(
                    '• Develop grazing plan',
                    'Prioritize use of drought-resistant paddocks first',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
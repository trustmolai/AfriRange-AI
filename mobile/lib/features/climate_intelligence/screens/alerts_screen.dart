import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Climate Alerts'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              // Handle filter selection
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Alerts'),
              ),
              const PopupMenuItem(
                value: 'unacknowledged',
                child: Text('Unacknowledged Only'),
              ),
              const PopupMenuItem(
                value: 'acknowledged',
                child: Text('Acknowledged Only'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              // Refresh alerts
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh alerts
        },
        child: Consumer<ClimateApiService>(
          builder: (context, climateService, _) {
            // In a real implementation, we would fetch alerts here
            // For now, showing placeholder
            return _buildAlertsList(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Manual trigger for testing/checking conditions
        },
        label: const Text('Check Conditions'),
        icon: const Icon(Icons.query_stats),
      ),
    );
  }

  Widget _buildAlertsList(BuildContext context) {
    return Column(
      children: [
        // Summary stats
        _buildAlertSummary(),
        const SizedBox(height: 16),
        
        // Alerts list
        Expanded(
          child: ListView(
            children: [
              _buildAlertCard(
                'DROUGHT ALERT: MODERATE RISK',
                'Multi-index assessment indicates moderate drought risk (Score: 52/100). '
                'SPI-3: -0.6, Vegetation stress detected.',
                'Drought',
                'moderate',
                false, // not acknowledged
                DateTime.now().subtract(const Duration(hours: 3)),
              ),
              _buildAlertCard(
                'WATER STRESS ALERT: HIGH RISK',
                'Combined hydrological indicators show elevated water stress risk. '
                'Hydroclimatic Index: 0.8 (optimal >1.5).',
                'Water Stress',
                'high',
                true, // acknowledged
                DateTime.now().subtract(const Duration(days: 1)),
              ),
              _buildAlertCard(
                'HEAT STRESS ALERT: MODERATE RISK',
                'Temperature-Humidity Index: 75.2 indicates moderate heat stress risk.',
                'Heat Stress',
                'moderate',
                false, // not acknowledged
                DateTime.now().subtract(const Duration(hours: 12)),
              ),
              _buildAlertCard(
                'FORAGE ALERT: 35 DAYS REMAINING',
                'Based on current biomass levels and livestock density, '
                'projected forage depletion in 35 days.',
                'Forage Shortage',
                'high',
                false, // not acknowledged
                DateTime.now().subtract(const Duration(days: 2)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatBox('Total Alerts', '4', Icons.notifications),
            _buildStatBox('Unacknowledged', '3', Icons.notifications_active),
            _buildStatBox('Critical', '0', Icons.priority_high),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(
    String title,
    String message,
    String type,
    String riskLevel,
    bool isAcknowledged,
    DateTime timestamp,
  ) {
    // Determine colors based on risk level
    Color borderColor;
    Color bgColor;
    IconData icon;
    
    switch (type.toLowerCase()) {
      case 'drought':
        borderColor = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.1);
        icon = Icons.water_drop;
        break;
      case 'water_stress':
        borderColor = Colors.blue;
        bgColor = Colors.blue.withOpacity(0.1);
        icon = Icons.opacity;
        break;
      case 'heat_stress':
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        icon = Icons.ac_unit;
        break;
      case 'forage_shortage':
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        icon = Icons.grass;
        break;
      default:
        borderColor = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.1);
        icon = Icons.notifications;
    }
    
    Color statusColor = isAcknowledged ? Colors.green : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: !isAcknowledged,
          backgroundColor: bgColor,
          title: Row(
            children: [
              Icon(icon, color: borderColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAcknowledged ? 'ACKNOWLEDGED' : 'PENDING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Issued: ${_formatTimeAgo(timestamp)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!isAcknowledged)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Acknowledge alert
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('ACKNOWLEDGE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}
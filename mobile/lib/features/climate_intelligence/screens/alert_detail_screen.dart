import 'package:flutter/material.dart';

class AlertDetailScreen extends StatelessWidget {
  final String alertId;

  const AlertDetailScreen({Key? key, required this.alertId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // In a real app, we would fetch the alert details using alertId
    // For now, showing placeholder data
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert Header
              _buildAlertHeader(),
              
              const SizedBox(height: 24),
              
              // Alert Details
              _buildAlertDetailsSection(),
              
              const SizedBox(height: 24),
              
              // Recommended Actions
              _buildRecommendationsSection(),
              
              const SizedBox(height: 24),
              
              // Acknowledgement Section
              _buildAcknowledgementSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertHeader() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade300,
              Colors.orange.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.water_drop,
              size: 36,
              color: Colors.orange,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DROUGHT ALERT: MODERATE RISK',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Issued: ${_formatDate(DateTime.now().subtract(const Duration(hours: 3)))}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  Widget _buildAlertDetailsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alert Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 16),
            _buildDetailRow('Alert Type', 'Drought'),
            _buildDetailRow('Risk Level', 'Moderate'),
            _buildDetailRow(
                'Issue Date', _formatDate(DateTime.now().subtract(const Duration(hours: 3)))),
            _buildDetailRow(
                'Valid Until', _formatDate(DateTime.now().add(const Duration(days: 7)))),
            _buildDetailRow('Status', 'Active - Requires Attention'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Card(
      elevation: 2,
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
                  color: Colors.blue[700],
                ),
                SizedBox(width: 12),
                Text(
                  'Recommended Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Immediate Actions (Next 24-48 hours):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildActionItem(
              'Increase monitoring frequency',
              'Check vegetation conditions and soil moisture every 3-4 days',
            ),
            _buildActionItem(
              'Inspect water infrastructure',
              'Check all water points for functionality and repair any leaks',
            ),
            _buildActionItem(
              'Review forage reserves',
              'Assess current hay and supplement supplies',
            ),
            const Divider(height: 16),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Short-term Actions (Next 1-2 weeks):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildActionItem(
              'Prepare supplementary feeding',
              'Begin procuring hay and concentrate supplements',
            ),
            _buildActionItem(
              'Consider early weaning',
              'Reduce nutritional demands on lactating animals if appropriate',
            ),
            _buildActionItem(
              'Review grazing plan',
              'Identify paddocks for rest and recovery',
            ),
            const Divider(height: 16),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Contingency Planning:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildActionItem(
              'Develop livestock reduction plan',
              'Identify animals for potential sale or relocation if conditions worsen',
            ),
            _buildActionItem(
              'Explore alternative water sources',
              'Investigate rainwater harvesting or water sharing agreements',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcknowledgementSection() {
    return Card(
      elevation: 2,
      child: Padding(
Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 24,
                  color: Colors.green[700],
                ),
                SizedBox(width: 12),
                Text(
                  'Acknowledge Alert',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Acknowledging this alert indicates that you have reviewed the information '
              'and understand the recommended actions. This does not imply that all '
              'actions have been completed, but rather that you are aware of the situation '
              'and have begun implementing appropriate responses.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                // Acknowledge the alert
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alert acknowledged successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                // In a real app, we would call the API to acknowledge
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('ACKNOWLEDGE ALERT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
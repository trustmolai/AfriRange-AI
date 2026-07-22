import 'package:flutter/material.dart';
import '../models/plant_observation_model.dart';
import '../../../shared/widgets/afri_button.dart';

class PlantDetailScreen extends StatelessWidget {
  final PlantObservationModel observation;
  final VoidCallback onConfirmed;
  final Function(String correctedName) onCorrected;

  const PlantDetailScreen({
    super.key,
    required this.observation,
    required this.onConfirmed,
    required this.onCorrected,
  });

  Color _getToxicityColor(String level) {
    switch (level.toLowerCase()) {
      case 'highly_poisonous':
        return const Color(0xFFD32F2F); // High-contrast Red
      case 'poisonous':
        return Colors.redAccent;
      case 'caution':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPoisonous = observation.toxicityLevel == 'poisonous' || observation.toxicityLevel == 'highly_poisonous';
    final toxicityColor = _getToxicityColor(observation.toxicityLevel);

    return Scaffold(
      appBar: AppBar(title: const Text('Plant Taxonomy Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // High-Contrast Red Warning Alert Modal card for Poisonous Plants
            if (isPoisonous)
              Card(
                color: toxicityColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: toxicityColor, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: toxicityColor, size: 36),
                          const SizedBox(width: 8),
                          Text(
                            'TOXIC WARNING',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: toxicityColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This species (${observation.scientificName}) is classified as ${observation.toxicityLevel.replaceAll('_', ' ').toUpperCase()}.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        observation.toxicityDescription ?? 'No details available.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'DISCLAIMER: AI botanical results are advisory. Always verify diagnostic findings with local agricultural officers before grazing.',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Main Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      observation.commonName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      observation.scientificName,
                      style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    _buildRowDetail('Plant Category', observation.plantType.toUpperCase()),
                    _buildRowDetail('Palatability', observation.palatability.toUpperCase()),
                    _buildRowDetail('Grazing Value', observation.grazingValue.toUpperCase()),
                    _buildRowDetail('Model Confidence', '${observation.confidenceScore.toStringAsFixed(1)}%'),
                    const SizedBox(height: 16),
                    const Text('Management Guidelines', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(observation.managementAdvice),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // User verification action sheet
            Row(
              children: [
                Expanded(
                  child: AfriButton(
                    label: 'CONFIRM MATCH',
                    onPressed: () {
                      onConfirmed();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AfriButton(
                    label: 'INCORRECT',
                    isSecondary: true,
                    onPressed: () {
                      _showCorrectionDialog(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCorrectionDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Correction'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter correct scientific/common name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onCorrected(controller.text.trim());
                Navigator.pop(ctx); // Close Dialog
                Navigator.pop(context); // Close Detail Screen
              }
            },
            child: const Text('Submit', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

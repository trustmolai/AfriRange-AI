import 'package:flutter/material.dart';
import '../models/plant_observation_model.dart';

class ObservationHistoryScreen extends StatefulWidget {
  const ObservationHistoryScreen({super.key});

  @override
  State<ObservationHistoryScreen> createState() => _ObservationHistoryScreenState();
}

class _ObservationHistoryScreenState extends State<ObservationHistoryScreen> {
  final List<PlantObservationModel> _observations = [
    const PlantObservationModel(
      id: 'o1',
      scientificName: 'Dichapetalum cymosum',
      commonName: 'Gifblaar',
      plantType: 'shrub',
      confidenceScore: 94.5,
      toxicityLevel: 'highly_poisonous',
      toxicityDescription: 'Monofluoroacetate poisoning risk.',
      palatability: 'unpalatable',
      grazingValue: 'none',
      managementAdvice: 'Keep cattle out of camps.',
      alternativeMatches: [],
      observationDate: '2026-07-20',
      userConfirmed: false,
    ),
    const PlantObservationModel(
      id: 'o2',
      scientificName: 'Themeda triandra',
      commonName: 'Red Grass',
      plantType: 'grass',
      confidenceScore: 91.0,
      toxicityLevel: 'safe',
      palatability: 'high',
      grazingValue: 'high',
      managementAdvice: 'Rotate paddocks.',
      alternativeMatches: [],
      observationDate: '2026-07-19',
      userConfirmed: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Observation History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _observations.length,
        itemBuilder: (context, index) {
          final obs = _observations[index];
          final isToxic = obs.toxicityLevel == 'poisonous' || obs.toxicityLevel == 'highly_poisonous';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: isToxic ? Colors.red.withOpacity(0.12) : const Color(0xFF2E7D32).withOpacity(0.12),
                child: Icon(
                  isToxic ? Icons.warning : Icons.eco,
                  color: isToxic ? Colors.red : const Color(0xFF2E7D32),
                ),
              ),
              title: Text(obs.commonName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${obs.scientificName} • ${obs.observationDate}'),
              trailing: Chip(
                label: Text(
                  obs.toxicityLevel.toUpperCase(),
                  style: TextStyle(color: isToxic ? Colors.white : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: isToxic ? Colors.red : Colors.lightGreenAccent,
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/grazing_record_model.dart';

class GrazingHistoryScreen extends StatefulWidget {
  final String paddockId;
  final String paddockName;

  const GrazingHistoryScreen({
    super.key,
    required this.paddockId,
    required this.paddockName,
  });

  @override
  State<GrazingHistoryScreen> createState() => _GrazingHistoryScreenState();
}

class _GrazingHistoryScreenState extends State<GrazingHistoryScreen> {
  final List<GrazingRecordModel> _history = [
    const GrazingRecordModel(
      id: 'h1',
      grazingZoneId: 'gz1',
      livestockGroupId: 'lg1',
      livestockGroupName: 'Main Breeding Herd',
      species: 'cattle_mature',
      grazingStartDate: '2026-06-01',
      grazingEndDate: '2026-06-15',
      numberOfAnimals: 120,
      lsuGrazing: 120.0,
      grazingDays: 14,
    ),
    const GrazingRecordModel(
      id: 'h2',
      grazingZoneId: 'gz1',
      livestockGroupId: 'lg3',
      livestockGroupName: 'Dorper Sheep Flock',
      species: 'sheep',
      grazingStartDate: '2026-05-10',
      grazingEndDate: '2026-05-24',
      numberOfAnimals: 150,
      lsuGrazing: 22.5,
      grazingDays: 14,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grazing History: ${widget.paddockName}'),
      ),
      body: _history.isEmpty
          ? const Center(child: Text('No grazing history found for this paddock.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final rec = _history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              rec.livestockGroupName ?? 'Unknown Herd',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Chip(
                              label: Text('${rec.grazingDays ?? 0} Days'),
                              backgroundColor: const Color(0xFF2E7D32).withOpacity(0.12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Duration: ${rec.grazingStartDate} to ${rec.grazingEndDate ?? "Active"}'),
                        const SizedBox(height: 6),
                        Text(
                          'Stock: ${rec.numberOfAnimals} Animals (${rec.lsuGrazing.toStringAsFixed(1)} LSU)',
                          style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

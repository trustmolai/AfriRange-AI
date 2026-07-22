import 'package:flutter/material.dart';
import '../models/livestock_group_model.dart';
import 'add_livestock_group_screen.dart';

class LivestockListScreen extends StatefulWidget {
  const LivestockListScreen({super.key});

  @override
  State<LivestockListScreen> createState() => _LivestockListScreenState();
}

class _LivestockListScreenState extends State<LivestockListScreen> {
  final List<LivestockGroupModel> _groups = [
    const LivestockGroupModel(
      id: 'lg1',
      farmId: 'f1',
      name: 'Main Breeding Herd',
      species: 'cattle_mature',
      numberOfAnimals: 120,
      lsuValue: 120.0,
      tluValue: 168.0,
      notes: 'Brahman cross mature cows',
    ),
    const LivestockGroupModel(
      id: 'lg2',
      farmId: 'f1',
      name: 'Replacement Heifers',
      species: 'cattle_heifer',
      numberOfAnimals: 45,
      lsuValue: 27.0,
      tluValue: 37.8,
    ),
    const LivestockGroupModel(
      id: 'lg3',
      farmId: 'f1',
      name: 'Dorper Sheep Flock',
      species: 'sheep',
      numberOfAnimals: 150,
      lsuValue: 22.5,
      tluValue: 31.5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    double totalLsu = _groups.fold(0.0, (sum, g) => sum + g.lsuValue);
    double totalTlu = _groups.fold(0.0, (sum, g) => sum + g.tluValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Livestock Groups'),
      ),
      body: Column(
        children: [
          // Total LSU Info Card
          Container(
            width: double.infinity,
            color: const Color(0xFF2E7D32),
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('Total LSU', totalLsu.toStringAsFixed(1)),
                _buildSummaryStat('Total TLU', totalTlu.toStringAsFixed(1)),
                _buildSummaryStat('Total Animals', _groups.fold(0, (sum, g) => sum + g.numberOfAnimals).toString()),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final group = _groups[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF2E7D32),
                      child: Icon(Icons.pets, color: Colors.white),
                    ),
                    title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${group.numberOfAnimals} Animals • Species: ${group.species.replaceAll('_', ' ')}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${group.lsuValue.toStringAsFixed(1)} LSU', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        Text('${group.tluValue.toStringAsFixed(1)} TLU', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => AddLivestockGroupScreen(
                onGroupAdded: (newGroup) {
                  setState(() {
                    _groups.add(newGroup);
                  });
                },
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Herd/Group'),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

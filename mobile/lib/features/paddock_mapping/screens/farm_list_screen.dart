import 'package:flutter/material.dart';
import '../models/farm_model.dart';
import 'polygon_drawing_screen.dart';

class FarmListScreen extends StatefulWidget {
  const FarmListScreen({super.key});

  @override
  State<FarmListScreen> createState() => _FarmListScreenState();
}

class _FarmListScreenState extends State<FarmListScreen> {
  final List<FarmModel> _farms = [
    const FarmModel(
      id: 'f1',
      name: 'Klipfontein Ranch',
      description: 'Main commercial beef & veld unit',
      country: 'South Africa',
      region: 'Free State',
      district: 'Bloemfontein',
      biome: 'Highveld Grassland',
      totalAreaHa: 1450.50,
      boundaryPoints: [],
    ),
    const FarmModel(
      id: 'f2',
      name: 'Otjiwarongo Reserve',
      description: 'Mixed cattle & game camp',
      country: 'Namibia',
      region: 'Otjozondjupa',
      biome: 'Bushveld Savanna',
      totalAreaHa: 3200.00,
      boundaryPoints: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Farms'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _farms.length,
        itemBuilder: (context, index) {
          final farm = _farms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2E7D32),
                child: Icon(Icons.landscape, color: Colors.white),
              ),
              title: Text(farm.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${farm.biome} • ${farm.country}'),
                  const SizedBox(height: 4),
                  Text(
                    '${farm.totalAreaHa.toStringAsFixed(2)} Hectares',
                    style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected Farm: ${farm.name}')),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => PolygonDrawingScreen(
                title: 'Draw Farm Boundary',
                onPolygonCompleted: (points, calculatedHa) {
                  setState(() {
                    _farms.add(
                      FarmModel(
                        id: 'f_${DateTime.now().millisecondsSinceEpoch}',
                        name: 'New Farm ${1 + _farms.length}',
                        country: 'South Africa',
                        biome: 'Savanna',
                        totalAreaHa: calculatedHa,
                        boundaryPoints: points,
                      ),
                    );
                  });
                },
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add Farm Boundary'),
      ),
    );
  }
}

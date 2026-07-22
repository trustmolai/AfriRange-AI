import 'package:flutter/material.dart';
import '../models/grazing_zone_model.dart';
import 'polygon_drawing_screen.dart';

class GrazingZoneListScreen extends StatefulWidget {
  final String farmId;
  final String farmName;

  const GrazingZoneListScreen({
    super.key,
    required this.farmId,
    required this.farmName,
  });

  @override
  State<GrazingZoneListScreen> createState() => _GrazingZoneListScreenState();
}

class _GrazingZoneListScreenState extends State<GrazingZoneListScreen> {
  final List<GrazingZoneModel> _zones = [
    const GrazingZoneModel(
      id: 'gz1',
      farmId: 'f1',
      name: 'Klipspringer Camp 1',
      areaHa: 120.40,
      targetRestDays: 45,
      currentStatus: 'rested',
      boundaryPoints: [],
    ),
    const GrazingZoneModel(
      id: 'gz2',
      farmId: 'f1',
      name: 'Donga Grazing Camp 2',
      areaHa: 95.80,
      targetRestDays: 60,
      currentStatus: 'grazing',
      boundaryPoints: [],
    ),
    const GrazingZoneModel(
      id: 'gz3',
      farmId: 'f1',
      name: 'Rooigras Camp 3',
      areaHa: 180.00,
      targetRestDays: 45,
      currentStatus: 'overgrazed',
      boundaryPoints: [],
    ),
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'rested':
        return Colors.green;
      case 'grazing':
        return Colors.orange;
      case 'overgrazed':
        return Colors.red;
      case 'recovering':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paddocks — ${widget.farmName}'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _zones.length,
        itemBuilder: (context, index) {
          final zone = _zones[index];
          final color = _getStatusColor(zone.currentStatus);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(Icons.crop_square, color: color),
              ),
              title: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${zone.areaHa.toStringAsFixed(2)} Ha • Rest Target: ${zone.targetRestDays} Days'),
                ],
              ),
              trailing: Chip(
                label: Text(zone.currentStatus.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: color,
              ),
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
                title: 'Draw Paddock Boundary',
                onPolygonCompleted: (points, calculatedHa) {
                  setState(() {
                    _zones.add(
                      GrazingZoneModel(
                        id: 'gz_${DateTime.now().millisecondsSinceEpoch}',
                        farmId: widget.farmId,
                        name: 'Paddock ${1 + _zones.length}',
                        areaHa: calculatedHa,
                        boundaryPoints: points,
                      ),
                    );
                  });
                },
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_task),
        label: const Text('Add Paddock Boundary'),
      ),
    );
  }
}

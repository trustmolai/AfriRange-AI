import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'screens/farm_list_screen.dart';
import 'screens/grazing_zone_list_screen.dart';
import 'screens/polygon_drawing_screen.dart';

class PaddockMapScreen extends StatefulWidget {
  const PaddockMapScreen({super.key});

  @override
  State<PaddockMapScreen> createState() => _PaddockMapScreenState();
}

class _PaddockMapScreenState extends State<PaddockMapScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(-29.8587, 26.0461); // Free State default

  // Sample paddocks for map display
  final List<List<LatLng>> _samplePaddocks = [
    [
      const LatLng(-29.855, 26.042),
      const LatLng(-29.855, 26.048),
      const LatLng(-29.860, 26.048),
      const LatLng(-29.860, 26.042),
    ],
    [
      const LatLng(-29.861, 26.042),
      const LatLng(-29.861, 26.048),
      const LatLng(-29.866, 26.048),
      const LatLng(-29.866, 26.042),
    ],
  ];

  // Sample Water Points
  final List<LatLng> _waterPoints = [
    const LatLng(-29.8575, 26.045),
    const LatLng(-29.8635, 26.045),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Paddock Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Farm List',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const FarmListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: 'Paddocks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const GrazingZoneListScreen(farmId: 'f1', farmName: 'Klipfontein Ranch'),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ai.afrirange.app',
              ),
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _samplePaddocks[0],
                    color: Colors.green.withOpacity(0.3),
                    borderColor: Colors.green,
                    borderStrokeWidth: 2,
                    isFilled: true,
                  ),
                  Polygon(
                    points: _samplePaddocks[1],
                    color: Colors.orange.withOpacity(0.3),
                    borderColor: Colors.orange,
                    borderStrokeWidth: 2,
                    isFilled: true,
                  ),
                ],
              ),
              MarkerLayer(
                markers: _waterPoints.map((p) {
                  return Marker(
                    point: p,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop, color: Colors.white, size: 18),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Map Control Legend Panel
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(Colors.green, 'Rested'),
                    _buildLegendItem(Colors.orange, 'Grazing'),
                    _buildLegendItem(Colors.red, 'Overgrazed'),
                    _buildLegendItem(Colors.blue, 'Water Point'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

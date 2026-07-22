import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/geospatial/area_calculator.dart';
import '../../../shared/widgets/afri_button.dart';

class PolygonDrawingScreen extends StatefulWidget {
  final String title;
  final Function(List<LatLng> points, double calculatedHa) onPolygonCompleted;

  const PolygonDrawingScreen({
    super.key,
    required this.title,
    required this.onPolygonCompleted,
  });

  @override
  State<PolygonDrawingScreen> createState() => _PolygonDrawingScreenState();
}

class _PolygonDrawingScreenState extends State<PolygonDrawingScreen> {
  final List<LatLng> _points = [];
  double _calculatedHa = 0.0;
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(-29.8587, 26.0461); // Free State Rangeland default

  void _addPoint(LatLng point) {
    setState(() {
      _points.add(point);
      _calculatedHa = AreaCalculator.calculateHectares(_points);
    });
  }

  void _undoLastPoint() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
        _calculatedHa = AreaCalculator.calculateHectares(_points);
      });
    }
  }

  void _clearPoints() {
    setState(() {
      _points.clear();
      _calculatedHa = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_points.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo Last Point',
              onPressed: _undoLastPoint,
            ),
          if (_points.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All Points',
              onPressed: _clearPoints,
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 14.0,
              onTap: (tapPosition, point) => _addPoint(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ai.afrirange.app',
              ),
              if (_points.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _points,
                      color: const Color(0xFF2E7D32).withOpacity(0.35),
                      borderColor: const Color(0xFF2E7D32),
                      borderStrokeWidth: 3,
                      isFilled: true,
                    ),
                  ],
                ),
              if (_points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _points,
                      color: const Color(0xFFF57C00),
                      strokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _points.map((p) {
                  return Marker(
                    point: p,
                    width: 16,
                    height: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Floating Area Display Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white.withOpacity(0.92),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CALCULATED SURFACE AREA',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(
                          '${_calculatedHa.toStringAsFixed(2)} Ha',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                    Chip(
                      label: Text('${_points.length} Vertices'),
                      backgroundColor: Colors.lightGreenAccent,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Panel
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              children: [
                if (_points.length < 3)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tap on the map to place at least 3 boundary points',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                AfriButton(
                  label: 'SAVE BOUNDARY (${_calculatedHa.toStringAsFixed(2)} Ha)',
                  onPressed: _points.length >= 3
                      ? () {
                          widget.onPolygonCompleted(_points, _calculatedHa);
                          Navigator.pop(context);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

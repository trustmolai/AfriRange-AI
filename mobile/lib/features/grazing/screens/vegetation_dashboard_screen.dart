import 'dart:math';
import 'package:flutter/material.dart';
import 'package:afrirange_ai/features/grazing/services/grazing_api_service.dart';
import 'package:afrirange_ai/core/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/vegetation_health_model.dart';

class VegetationDashboardScreen extends StatefulWidget {
  const VegetationDashboardScreen({super.key});

  @override
  State<VegetationDashboardScreen> createState() => _VegetationDashboardScreenState();
}

class _VegetationDashboardScreenState extends State<VegetationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final GrazingApiService _apiService;
  late TabController _tabController;
  String? _selectedPaddockId;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<VegetationHealthModel> _observations = [];
  List<Map<String, dynamic>> _zones = [];
  List<List<VegetationHealthModel>> _zoneObservations = [];

  @override
  void initState() {
    super.initState();
    _apiService = GrazingApiService(authToken: 'dummy_token_for_now');
    _selectedPaddockId = 'paddock_1'; // In real app, this would come from user selection
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load satellite data for selected paddock
      if (_selectedPaddockId != null) {
        final observations = await _apiService.getSatelliteData(_selectedPaddockId!);
        setState(() {
          _observations = observations;
        });
      }
      
      // Load zone comparison data
      _zones = [
        {'id': 'zone1', 'name': 'North Camp', 'areaHa': 150.0},
        {'id': 'zone2', 'name': 'South Camp', 'areaHa': 200.0},
        {'id': 'zone3', 'name': 'East Camp', 'areaHa': 120.0},
        {'id': 'zone4', 'name': 'West Camp', 'areaHa': 180.0},
      ];
      
      // Load observations for each zone
      for (final zone in _zones) {
        final observations = await _apiService.getSatelliteData(zone['id']);
        _zoneObservations.add(observations);
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedPaddockId != null) {
        await _apiService.refreshSatelliteData(_selectedPaddockId!);
        final observations = await _apiService.getSatelliteData(_selectedPaddockId!);
        setState(() {
          _observations = observations;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vegetation Health Monitor'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Zone Comparison'),
            Tab(text: 'Maps & Trends'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _isLoading ? null : _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading vegetation data',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Unknown error occurred',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Overview Tab
                    _buildOverviewTab(),
                    
                    // Zone Comparison Tab
                    _buildZoneComparisonTab(),
                    
                    // Maps & Trends Tab
                    _buildMapsAndTrendsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    if (_observations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No satellite data available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh or check your connection',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current NDVI Summary Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Color(_observations.first.healthColorValue).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _observations.first.ndviValue.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(_observations.first.healthColorValue),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current NDVI',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            _observations.first.healthLabel,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(_observations.first.healthColorValue),
                            ),
                          ),
                          Text(
                            '${_observations.first.biomassKgPerHa.toStringAsFixed(0)} kg DM/ha estimated forage',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat('NDVI', _observations.first.ndviValue.toStringAsFixed(3)),
                    _buildMiniStat('EVI', _observations.first.eviValue?.toStringAsFixed(3) ?? 'N/A'),
                    _buildMiniStat('Source', _observations.first.dataSource),
                    _buildMiniStat('Date', _observations.first.observationDate.substring(5)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // NDVI Trend Visual Bar Chart
        const Text(
          '6-Month NDVI Trend',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _observations.reversed.map((obs) {
                final barWidth = obs.ndviValue.clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          obs.observationDate.substring(5),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: barWidth,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Color(obs.healthColorValue),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 36,
                        child: Text(
                          obs.ndviValue.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Biomass Comparison Table
        const Text(
          'Biomass Estimates per Observation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: DataTable(
            columnSpacing: 16,
            columns: const [
              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('NDVI', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('kg DM/ha', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Health', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _observations.map((obs) {
              return DataRow(cells: [
                DataCell(Text(obs.observationDate.substring(5), style: const TextStyle(fontSize: 12))),
                DataCell(Text(obs.ndviValue.toStringAsFixed(3), style: const TextStyle(fontSize: 12))),
                DataCell(Text(obs.biomassKgPerHa.toStringAsFixed(0), style: const TextStyle(fontSize: 12))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(obs.healthColorValue).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      obs.healthLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(obs.healthColorValue),
                      ),
                    ),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneComparisonTab() {
    if (_zones.isEmpty) {
      return const Center(child: Text('No zone data available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Zone comparison header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VEGETATION COMPARISON',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Zone', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: const Divider(),
                      ),
                    ),
                    const Text('NDVI', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: const Divider(),
                      ),
                    ),
                    const Text('Biomass (kg/ha)', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: const Divider(),
                      ),
                    ),
                    const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Zone rows
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _zones.length,
          itemBuilder: (context, index) {
            final zone = _zones[index];
            final observations = _zoneObservations.length > index ? _zoneObservations[index] : [];
            final latest = observations.isNotEmpty ? observations.first : null;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        zone['name'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: latest != null
                          ? Text(
                              latest.ndviValue.toStringAsFixed(3),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(latest.healthColorValue),
                              ),
                            )
                          : const Text('-'),
                    ),
                    Expanded(
                      flex: 1,
                      child: latest != null
                          ? Text(
                              latest.biomassKgPerHa.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            )
                          : const Text('-'),
                    ),
                    Expanded(
                      flex: 1,
                      child: latest != null
                          ? Text(
                              latest.healthLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(latest.healthColorValue),
                              ),
                            )
                          : const Text('-'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        
        // Best zone recommendation
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECOMMENDATION',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                _buildBestZoneRecommendation(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBestZoneRecommendation() {
    if (_zoneObservations.isEmpty) {
      return const Text('No data available');
    }

    // Find zone with highest NDVI
    int bestIndex = 0;
    double bestNdvi = 0.0;
    
    for (int i = 0; i < _zoneObservations.length; i++) {
      if (_zoneObservations[i].isNotEmpty && 
          _zoneObservations[i].first.ndviValue > bestNdvi) {
        bestNdvi = _zoneObservations[i].first.ndviValue;
        bestIndex = i;
      }
    }

    final bestZone = _zones[bestIndex];
    final bestObs = _zoneObservations[bestIndex].isNotEmpty 
        ? _zoneObservations[bestIndex].first 
        : null;

    if (bestObs == null) {
      return const Text('Insufficient data for recommendation');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Best grazing zone: ${bestZone['name']}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 4),
        Text(
          'NDVI: ${bestObs.ndviValue.toStringAsFixed(3)} (${bestObs.healthLabel})',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 4),
        Text(
          'Biomass: ${bestObs.biomassKgPerHa.toStringAsFixed(0)} kg DM/ha',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Text(
          'Reason: This zone currently has the highest vegetation health and forage availability.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildMapsAndTrendsTab() {
    // This would integrate with maps and show detailed trends
    // For now, showing a placeholder with some charts/info
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'VEGETATION MAPS & TRENDS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NDVI Heatmap View',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'NDVI Heatmap View\n(Integrate with Google Maps/Mapbox)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Vegetation Health Indicators',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildIndicatorCard('EVI Trend', '▲ 0.05', Colors.green),
                    _buildIndicatorCard('Moisture Index', '▲ 0.02', Colors.blue),
                    _buildIndicatorCard('Leaf Area Index', '▲ 0.3', Colors.orange),
                    _buildIndicatorCard('Chlorophyll Content', '▲ 0.1', Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seasonal Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSeasonalChart('Growth Season', 75, Colors.green),
                    _buildSeasonalChart('Peak Biomass', 90, Colors.blue),
                    _buildSeasonalChart('Dormant Period', 45, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildIndicatorCard(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonalChart(String label, int percentage, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Stack(
            children: [
              // Background circle
              Positioned.fill(
                child: CustomPaint(
                  painter: _SimpleArcPainter(
                    progress: percentage / 100.0,
                    color: color,
                  ),
                ),
              ),
              // Center text
              Center(
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Simple arc painter for circular progress indicator
class _SimpleArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SimpleArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final offset = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, backgroundPaint);
    
    // Draw progress arc
    if (progress > 0) {
      canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
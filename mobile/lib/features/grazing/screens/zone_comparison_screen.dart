import 'package:flutter/material.dart';
import 'package:afrirange_ai/features/grazing/services/grazing_api_service.dart';
import 'package:afrirange_ai/core/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/vegetation_health_model.dart';

class ZoneComparisonScreen extends StatefulWidget {
  const ZoneComparisonScreen({super.key});

  @override
  State<ZoneComparisonScreen> createState() => _ZoneComparisonScreenState();
}

class _ZoneComparisonScreenState extends State<ZoneComparisonScreen> {
  late final GrazingApiService _apiService;
  String? _selectedFarmId;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _zones = [];
  List<List<VegetationHealthModel>> _zoneObservations = [];

  @override
  void initState() {
    super.initState();
    _selectedFarmId = 'farm_1';
    _apiService = GrazingApiService(authToken: 'dummy_token_for_now');
    _loadFarmZones();
  }

  Future<void> _loadFarmZones() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Get paddocks for farm
      final paddocksResult = await _apiService.getRotationalPlans(_selectedFarmId!);
      // For now, we'll use a simplified approach - in reality we'd get paddocks directly
      // Let's simulate with some zone data
      setState(() {
        _zones = [
          {'id': 'zone1', 'name': 'North Camp', 'areaHa': 150.0},
          {'id': 'zone2', 'name': 'South Camp', 'areaHa': 200.0},
          {'id': 'zone3', 'name': 'East Camp', 'areaHa': 120.0},
          {'id': 'zone4', 'name': 'West Camp', 'areaHa': 180.0},
        ];
        _isLoading = false;
      });
      
      // Load satellite data for each zone
      for (final zone in _zones) {
        final observations = await _apiService.getSatelliteData(zone['id']);
        _zoneObservations.add(observations);
      }
      
      setState(() {});
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
        title: const Text('Grazing Zone Comparison'),
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
                        'Error loading zone data',
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
                        onPressed: _loadFarmZones,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _zones.isEmpty
                  ? const Center(
                      child: Text('No grazing zones found for this farm'),
                    )
                  : ListView(
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
                    ),
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
}
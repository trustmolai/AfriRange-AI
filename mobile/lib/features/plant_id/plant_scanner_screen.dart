import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import 'screens/camera_preview_screen.dart';
import 'screens/plant_detail_screen.dart';
import 'screens/observation_history_screen.dart';
import 'models/plant_observation_model.dart';

class PlantScannerScreen extends StatefulWidget {
  const PlantScannerScreen({super.key});

  @override
  State<PlantScannerScreen> createState() => _PlantScannerScreenState();
}

class _PlantScannerScreenState extends State<PlantScannerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  PlantObservationModel? _selectedPlant;

  @override
  void initState() {
    super.initState();
    _loadSampleCatalog();
  }

  void _loadSampleCatalog() {
    setState(() {
      _searchResults = [
        {
          'scientific_name': 'Themeda triandra',
          'common_names': 'Red Grass / Rooigras',
          'plant_type': 'grass',
          'ecological_status': 'Decreaser',
          'palatability': 'High',
          'is_poisonous': 0,
          'management_advice': 'Prime climax forage grass. High palatability; maintain 45-60 day rest period.'
        },
        {
          'scientific_name': 'Dichapetalum cymosum',
          'common_names': 'Gifblaar / Poison Leaf',
          'plant_type': 'forb',
          'ecological_status': 'Invader',
          'palatability': 'Unpalatable',
          'is_poisonous': 1,
          'toxicity_level': 'Lethal',
          'management_advice': 'LETHAL TO LIVESTOCK! Emerges early spring. Immediately fence off or spot herbicide.'
        },
      ];
    });
  }

  void _openCameraScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CameraPreviewScreen(
          onPhotoCaptured: (xfile) {
            // Trigger simulated scan result representing high-contrast card testing
            _showAnalysisBottomSheet();
          },
        ),
      ),
    );
  }

  void _showAnalysisBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.center_focus_strong, size: 64, color: Color(0xFF2E7D32)),
                  SizedBox(height: 12),
                  Text(
                    'AI Vision processing completed',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F), // Destructive Red
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _openDetailScreen(
                  const PlantObservationModel(
                    id: 'o_gif',
                    scientificName: 'Dichapetalum cymosum',
                    commonName: 'Gifblaar',
                    plantType: 'shrub',
                    confidenceScore: 95.8,
                    toxicityLevel: 'highly_poisonous',
                    toxicityDescription: 'Contains monofluoroacetate. Causes sudden cardiac failure. Extremely lethal to cattle.',
                    palatability: 'unpalatable',
                    grazingValue: 'none',
                    managementAdvice: 'Fence off paddock immediately. Mechanically pull or chemical spot spray.',
                    alternativeMatches: [],
                    observationDate: '2026-07-21',
                  ),
                );
              },
              icon: const Icon(Icons.warning),
              label: const Text('Simulate Toxic Identification (Gifblaar)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _openDetailScreen(
                  const PlantObservationModel(
                    id: 'o_themeda',
                    scientificName: 'Themeda triandra',
                    commonName: 'Red Grass',
                    plantType: 'grass',
                    confidenceScore: 92.5,
                    toxicityLevel: 'safe',
                    palatability: 'high',
                    grazingValue: 'high',
                    managementAdvice: 'Excellent decreaser forage grass. Rotate grazing camps.',
                    alternativeMatches: [],
                    observationDate: '2026-07-21',
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Simulate Safe Identification (Red Grass)'),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetailScreen(PlantObservationModel obs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PlantDetailScreen(
          observation: obs,
          onConfirmed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('AI identification confirmed.')),
            );
          },
          onCorrected: (correction) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Correction submitted: $correction')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Botany & Vegetation AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History Logs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ObservationHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI plant identification is an advisory tool. Always verify suspected toxic plants with agricultural officers.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _openCameraScanner,
            icon: const Icon(Icons.camera_alt, size: 28),
            label: const Text(
              'SCAN VEGETATION PHOTO (AI VISION)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Offline African Botanical Catalog',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search grasses, shrubs, toxic weeds...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            itemBuilder: (ctx, idx) {
              final item = _searchResults[idx];
              final isToxic = item['is_poisonous'] == 1;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isToxic ? Colors.red.shade100 : Colors.green.shade100,
                    child: Icon(
                      isToxic ? Icons.warning : Icons.eco,
                      color: isToxic ? Colors.red : Colors.green.shade800,
                    ),
                  ),
                  title: Text(
                    item['scientific_name'],
                    style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(item['common_names']),
                  onTap: () {
                    _openDetailScreen(
                      PlantObservationModel(
                        id: 'o_cat_${DateTime.now().millisecondsSinceEpoch}',
                        scientificName: item['scientific_name'],
                        commonName: item['common_names'].toString().split(' / ')[0],
                        plantType: item['plant_type'],
                        confidenceScore: 100.0,
                        toxicityLevel: isToxic ? 'highly_poisonous' : 'safe',
                        toxicityDescription: isToxic ? item['management_advice'] : null,
                        palatability: item['palatability'].toString().toLowerCase(),
                        grazingValue: isToxic ? 'none' : 'high',
                        managementAdvice: item['management_advice'],
                        alternativeMatches: [],
                        observationDate: 'Offline Catalog',
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

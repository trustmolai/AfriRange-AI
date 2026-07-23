import 'package:flutter/material.dart';

class CarryingCapacityCalculator {
  static double calculateVcs({
    required double decreaserPct,
    required double increaserIIPct,
    required double toxicInvaderPct,
  }) {
    final increaserIPct = (100.0 - decreaserPct - increaserIIPct - toxicInvaderPct).clamp(0.0, 100.0);
    final rawVcs = (decreaserPct * 1.0) + (increaserIPct * 0.7) + (increaserIIPct * 0.4) - (toxicInvaderPct * 1.5);
    return rawVcs.clamp(0.0, 100.0);
  }

  static double calculateLsuPerHa({
    required double vcs,
    required double ndvi,
  }) {
    final ndviMultiplier = ndvi >= 0.55 ? 1.25 : (ndvi >= 0.35 ? 1.00 : 0.60);
    final vcsMultiplier = vcs / 50.0;
    return (0.20 * vcsMultiplier * ndviMultiplier).clamp(0.05, 0.60);
  }

  static int calculateRestDays(double vcs) {
    if (vcs < 40.0) return 75;
    if (vcs < 65.0) return 45;
    return 30;
  }
}


class VeldIntelligenceScreen extends StatefulWidget {
  const VeldIntelligenceScreen({super.key});

  @override
  State<VeldIntelligenceScreen> createState() => _VeldIntelligenceScreenState();
}

class _VeldIntelligenceScreenState extends State<VeldIntelligenceScreen> {
  double _paddockAreaHa = 150.0;
  double _baselineNdvi = 0.52; // Moderate greenness
  double _decreaserPct = 40.0; // High forage quality grasses
  double _increaserIIPct = 35.0; // Overgrazed indicator grasses
  double _toxicInvaderPct = 5.0; // Toxic/Invasive species

  // Outputs
  double _calculatedVcs = 0.0;
  double _recommendedLsuPerHa = 0.0;
  int _recommendedHerdSizeLsu = 0;
  int _recommendedRestDays = 45;

  @override
  void initState() {
    super.initState();
    _recalculateVeldMetrics();
  }

  void _recalculateVeldMetrics() {
    setState(() {
      _calculatedVcs = CarryingCapacityCalculator.calculateVcs(
        decreaserPct: _decreaserPct,
        increaserIIPct: _increaserIIPct,
        toxicInvaderPct: _toxicInvaderPct,
      );

      _recommendedLsuPerHa = CarryingCapacityCalculator.calculateLsuPerHa(
        vcs: _calculatedVcs,
        ndvi: _baselineNdvi,
      );

      _recommendedHerdSizeLsu = (_recommendedLsuPerHa * _paddockAreaHa).round();
      _recommendedRestDays = CarryingCapacityCalculator.calculateRestDays(_calculatedVcs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veld Condition & Stocking Engine'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF2E7D32),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'CALCULATED CARRYING CAPACITY',
                    style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_recommendedLsuPerHa.toStringAsFixed(3)} LSU / ha',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.lightGreenAccent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target Herd: $_recommendedHerdSizeLsu Large Stock Units (for ${_paddockAreaHa.toInt()} ha paddock)',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Divider(height: 24, color: Colors.white30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Veld Score (VCS)', style: TextStyle(fontSize: 12)),
                          Text(
                            '${_calculatedVcs.toStringAsFixed(1)} / 100',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Satellite NDVI', style: TextStyle(fontSize: 12)),
                          Text(
                            _baselineNdvi.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Required Rest', style: TextStyle(fontSize: 12)),
                          Text(
                            '$_recommendedRestDays Days',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ecological Inputs & Botanical Surveys',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            label: 'Paddock Area',
            valueText: '${_paddockAreaHa.toInt()} ha',
            value: _paddockAreaHa,
            min: 10,
            max: 1000,
            onChanged: (v) {
              _paddockAreaHa = v;
              _recalculateVeldMetrics();
            },
          ),
          _buildSliderRow(
            label: 'Decreaser Grasses (Prime Forage)',
            valueText: '${_decreaserPct.toInt()}%',
            value: _decreaserPct,
            min: 0,
            max: 100,
            onChanged: (v) {
              _decreaserPct = v;
              _recalculateVeldMetrics();
            },
          ),
          _buildSliderRow(
            label: 'Increaser II Grasses (Overgrazed)',
            valueText: '${_increaserIIPct.toInt()}%',
            value: _increaserIIPct,
            min: 0,
            max: 100,
            onChanged: (v) {
              _increaserIIPct = v;
              _recalculateVeldMetrics();
            },
          ),
          _buildSliderRow(
            label: 'Toxic / Invasive Plants',
            valueText: '${_toxicInvaderPct.toInt()}%',
            value: _toxicInvaderPct,
            min: 0,
            max: 40,
            onChanged: (v) {
              _toxicInvaderPct = v;
              _recalculateVeldMetrics();
            },
          ),
          _buildSliderRow(
            label: 'Satellite Greenness (NDVI)',
            valueText: _baselineNdvi.toStringAsFixed(2),
            value: _baselineNdvi,
            min: 0.1,
            max: 0.9,
            onChanged: (v) {
              _baselineNdvi = v;
              _recalculateVeldMetrics();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(valueText, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: const Color(0xFF2E7D32),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

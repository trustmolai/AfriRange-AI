class LsuCalculator {
  static const Map<String, Map<String, double>> factors = {
    'cattle_mature': {'lsu': 1.000, 'tlu': 1.400},
    'cattle_heifer': {'lsu': 0.600, 'tlu': 0.840},
    'sheep': {'lsu': 0.150, 'tlu': 0.210},
    'goat': {'lsu': 0.150, 'tlu': 0.210},
    'camel': {'lsu': 1.250, 'tlu': 1.750},
    'donkey': {'lsu': 0.500, 'tlu': 0.700},
    'horse': {'lsu': 0.800, 'tlu': 1.120},
  };

  /// Compute LSU & TLU offline values from animal count and species key
  static Map<String, double> calculateLsuTlu(String speciesKey, int count) {
    final factor = factors[speciesKey] ?? factors['cattle_mature']!;
    final lsu = count * factor['lsu']!;
    final tlu = count * factor['tlu']!;
    
    return {
      'lsu': double.parse(lsu.toStringAsFixed(2)),
      'tlu': double.parse(tlu.toStringAsFixed(2)),
    };
  }
}

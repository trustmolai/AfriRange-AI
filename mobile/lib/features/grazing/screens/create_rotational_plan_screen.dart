import 'package:flutter/material.dart';
import 'package:afrirange_ai/features/grazing/services/grazing_api_service.dart';
import 'package:afrirange_ai/features/paddock_mapping/models/grazing_zone_model.dart';
import 'package:intl/intl.dart';

class CreateRotationalPlanScreen extends StatefulWidget {
  const CreateRotationalPlanScreen({super.key});

  @override
  State<CreateRotationalPlanScreen> createState() => _CreateRotationalPlanScreenState();
}

class _CreateRotationalPlanScreenState extends State<CreateRotationalPlanScreen> {
  late final GrazingApiService _apiService;
  final _formKey = GlobalKey<FormState>();
  String? _selectedFarmId;
  String _planName = '';
  DateTime? _startDate;
  DateTime? _endDate;
  List<GrazingZoneModel> _availablePaddocks = [];
  List<dynamic> _selectedPaddocks = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = GrazingApiService(authToken: 'dummy_token_for_now');
    _selectedFarmId = 'farm_1';
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Load available paddocks for farm
      // In a real app, we'd call an API to get paddocks
      _availablePaddocks = [
        GrazingZoneModel(
          id: 'paddock_1',
          farmId: 'farm_1',
          name: 'North Camp',
          areaHa: 150.0,
          boundaryPoints: [],
          targetRestDays: 45,
          baselineLsuPerHa: 0.20,
          currentStatus: 'rested',
        ),
        GrazingZoneModel(
          id: 'paddock_2',
          farmId: 'farm_1',
          name: 'South Camp',
          areaHa: 200.0,
          boundaryPoints: [],
          targetRestDays: 45,
          baselineLsuPerHa: 0.20,
          currentStatus: 'rested',
        ),
        GrazingZoneModel(
          id: 'paddock_3',
          farmId: 'farm_1',
          name: 'East Camp',
          areaHa: 120.0,
          boundaryPoints: [],
          targetRestDays: 45,
          baselineLsuPerHa: 0.20,
          currentStatus: 'rested',
        ),
        GrazingZoneModel(
          id: 'paddock_4',
          farmId: 'farm_1',
          name: 'West Camp',
          areaHa: 180.0,
          boundaryPoints: [],
          targetRestDays: 45,
          baselineLsuPerHa: 0.20,
          currentStatus: 'rested',
        ),
      ];
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _addPaddockToPlan(GrazingZoneModel paddock) {
    setState(() {
      // Check if already added
      final exists = _selectedPaddocks.any((p) => p['id'] == paddock.id);
      if (!exists) {
        _selectedPaddocks.add({
          'id': paddock.id,
          'name': paddock.name,
          'areaHa': paddock.areaHa,
          'grazingStartDate': null,
          'grazingEndDate': null,
          'restDays': 45,
        });
      }
    });
  }

  void _removePaddockFromPlan(String paddockId) {
    setState(() {
      _selectedPaddocks.removeWhere((p) => p['id'] == paddockId);
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPaddocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one paddock')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      // Prepare paddocks data
      final paddocksData = _selectedPaddocks.map((paddock) {
        return {
          'paddockId': paddock['id'],
          'grazingStartDate': paddock['grazingStartDate']?.toIso8601String().split('T')[0],
          'grazingEndDate': paddock['grazingEndDate']?.toIso8601String().split('T')[0],
          'restDays': paddock['restDays'] ?? 45,
        };
      }).toList();

      // Save plan via API
      final result = await _apiService.createRotationalPlan(
        _selectedFarmId!,
        {
          'planName': _planName,
          'startDate': _startDate!.toIso8601String().split('T')[0],
          'endDate': _endDate!.toIso8601String().split('T')[0],
          'paddocks': paddocksData,
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rotational plan created successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create plan: $e')),
        );
      }
    }
  }

  Future<DateTime?> _pickDate(BuildContext context, {DateTime? initialDate, DateTime? firstDate, DateTime? lastDate}) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime.now(),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 730)),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Rotational Plan'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availablePaddocks.isEmpty
              ? const Center(
                  child: Text('No paddocks available for this farm'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Plan name
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Plan Name',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., Summer Rotation 2026',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a plan name';
                            }
                            return null;
                          },
                          onSaved: (value) => _planName = value!,
                        ),
                        const SizedBox(height: 16),
                        
                        // Date range
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await _pickDate(
                                    context,
                                    initialDate: _startDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setState(() => _startDate = date);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Start Date',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(_formatDate(_startDate)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await _pickDate(
                                    context,
                                    initialDate: _endDate ?? DateTime.now().add(const Duration(days: 90)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 730)),
                                  );
                                  if (date != null) {
                                    setState(() => _endDate = date);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'End Date',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(_formatDate(_endDate)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Available paddocks
                        const Text(
                          'Available Paddocks',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availablePaddocks.map((paddock) => ChoiceChip(
                            label: Text('${paddock.name} (${paddock.areaHa.toStringAsFixed(0)} ha)'),
                            selected: _selectedPaddocks.any((p) => p['id'] == paddock.id),
                            onSelected: (selected) {
                              if (selected) {
                                _addPaddockToPlan(paddock);
                              } else {
                                _removePaddockFromPlan(paddock.id);
                              }
                            },
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                        
                        // Selected paddocks details
                        if (_selectedPaddocks.isNotEmpty) ...[
                          const Text(
                            'Selected Paddocks Schedule',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedPaddocks.length,
                            itemBuilder: (context, index) {
                              final paddock = _selectedPaddocks[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(paddock['name'] as String),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Area: ${paddock['areaHa']} ha',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 16),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () async {
                                                final date = await _pickDate(
                                                  context,
                                                  initialDate: paddock['grazingStartDate'] as DateTime? ?? _startDate,
                                                  firstDate: _startDate,
                                                  lastDate: _endDate,
                                                );
                                                if (date != null) {
                                                  setState(() {
                                                    paddock['grazingStartDate'] = date;
                                                  });
                                                }
                                              },
                                              child: InputDecorator(
                                                decoration: const InputDecoration(
                                                  labelText: 'Start',
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.all(8),
                                                ),
                                                child: Text(_formatDate(paddock['grazingStartDate'] as DateTime?)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 16),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () async {
                                                final date = await _pickDate(
                                                  context,
                                                  initialDate: paddock['grazingEndDate'] as DateTime? ?? _endDate,
                                                  firstDate: _startDate,
                                                  lastDate: _endDate,
                                                );
                                                if (date != null) {
                                                  setState(() {
                                                    paddock['grazingEndDate'] = date;
                                                  });
                                                }
                                              },
                                              child: InputDecorator(
                                                decoration: const InputDecoration(
                                                  labelText: 'End',
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.all(8),
                                                ),
                                                child: Text(_formatDate(paddock['grazingEndDate'] as DateTime?)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.timelapse, size: 16),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: paddock['restDays']?.toString(),
                                              decoration: const InputDecoration(
                                                labelText: 'Rest Days',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                              onChanged: (value) {
                                                setState(() {
                                                  paddock['restDays'] = int.tryParse(value) ?? 45;
                                                });
                                              },
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter rest days';
                                                }
                                                final num = int.tryParse(value);
                                                if (num == null || num < 1) {
                                                  return 'Please enter a valid number';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removePaddockFromPlan(paddock['id']),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        
                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _savePlan,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'CREATE PLAN',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
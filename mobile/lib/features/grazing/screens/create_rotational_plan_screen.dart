import 'package:flutter/material.dart';
import 'package:afrirange_ai/features/grazing/services/grazing_api_service.dart';
import 'package:afrirange_ai/features/paddock_mapping/models/paddock_model.dart';
import 'package:date_field/date_field.dart';

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
  List<PaddockModel> _availablePaddocks = [];
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
        PaddockModel(
          id: 'paddock_1',
          farmId: 'farm_1',
          name: 'North Camp',
          areaHa: 150.0,
          boundaryGeojson: '',
          targetRestDays: 45,
          baselineLsuPerHa: 0.20,
          currentStatus: 'rested',
        ),
        PaddockModel(
          id: 'paddock_2',
          farmId: 'farm_1',
          name: 'South Camp',
          areaHa: 200.0,
          boundaryGeojson: '',
          targetRestDays: 45,
          baselineLsuPerHa: 0.20,
          currentStatus: 'rested',
        ),
        PaddockModel(
          id: 'paddock_3',
          farmId: 'farm_1',
          name: 'East Camp',
          areaHa: 120.0,
          boundaryGeojson: '',
          targetRestDays: 45,
          baselineLsuPerHa: 0.20,
          currentStatus: 'rested',
        ),
        PaddockModel(
          id: 'paddock_4',
          farmId: 'farm_1',
          name: 'West Camp',
          areaHa: 180.0,
          boundaryGeojson: '',
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

  void _addPaddockToPlan(PaddockModel paddock) {
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
                              child: DateFormField(
                                initialValue: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(),
                                ),
                                mode: DateFieldPickerMode.date,
                                onDateSelected: (date) => setState(() => _startDate = date),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a start date';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DateFormField(
                                initialValue: DateTime.now().add(const Duration(days: 90)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 730)),
                                decoration: const InputDecoration(
                                  labelText: 'End Date',
                                  border: OutlineInputBorder(),
                                ),
                                mode: DateFieldPickerMode.date,
                                onDateSelected: (date) => setState(() => _endDate = date),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select an end date';
                                  }
                                  if (_startDate != null && value!.isBefore(_startDate!)) {
                                    return 'End date must be after start date';
                                  }
                                  return null;
                                },
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
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 16),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: DateFormField(
                                              initialValue: paddock['grazingStartDate'],
                                              firstDate: _startDate,
                                              lastDate: _endDate,
                                              decoration: const InputDecoration(
                                                labelText: 'Start',
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.all(8),
                                              ),
                                              mode: DateFieldPickerMode.date,
                                              onDateSelected: (date) {
                                                setState(() {
                                                  paddock['grazingStartDate'] = date;
                                                });
                                              },
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
                                            child: DateFormField(
                                              initialValue: paddock['grazingEndDate'],
                                              firstDate: _startDate,
                                              lastDate: _endDate,
                                              decoration: const InputDecoration(
                                                labelText: 'End',
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.all(8),
                                              ),
                                              mode: DateFieldPickerMode.date,
                                              onDateSelected: (date) {
                                                setState(() {
                                                  paddock['grazingEndDate'] = date;
                                                });
                                              },
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
      );
    }
  }
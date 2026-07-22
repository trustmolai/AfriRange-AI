import 'package:flutter/material.dart';
import '../../../shared/widgets/afri_button.dart';
import '../../../shared/widgets/afri_text_field.dart';
import '../../../core/livestock/lsu_calculator.dart';
import '../models/livestock_group_model.dart';

class AddLivestockGroupScreen extends StatefulWidget {
  final Function(LivestockGroupModel) onGroupAdded;

  const AddLivestockGroupScreen({super.key, required this.onGroupAdded});

  @override
  State<AddLivestockGroupScreen> createState() => _AddLivestockGroupScreenState();
}

class _AddLivestockGroupScreenState extends State<AddLivestockGroupScreen> {
  final _nameController = TextEditingController();
  final _countController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedSpecies = 'cattle_mature';
  double _calculatedLsu = 0.0;
  double _calculatedTlu = 0.0;

  void _updateLsuTlu() {
    final count = int.tryParse(_countController.text) ?? 0;
    final results = LsuCalculator.calculateLsuTlu(_selectedSpecies, count);
    setState(() {
      _calculatedLsu = results['lsu']!;
      _calculatedTlu = results['tlu']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Herd/Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AfriTextField(
                label: 'Herd/Group Name',
                controller: _nameController,
                hint: 'e.g. Breeding Cows, Weaner Steers',
                validator: (val) => val == null || val.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),
              const Text('Livestock Species Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedSpecies,
                decoration: const InputDecoration(),
                items: LsuCalculator.factors.keys.map((key) {
                  return DropdownMenuItem(
                    value: key,
                    child: Text(key.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedSpecies = val;
                      _updateLsuTlu();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              AfriTextField(
                label: 'Animal Count',
                controller: _countController,
                keyboardType: TextInputType.number,
                validator: (val) => val == null || int.tryParse(val) == null ? 'Enter number' : null,
                prefixIcon: const Icon(Icons.tag),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate),
                  onPressed: _updateLsuTlu,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF2E7D32).withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('CALCULATED LSU', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(_calculatedLsu.toStringAsFixed(1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('CALCULATED TLU', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(_calculatedTlu.toStringAsFixed(1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFF57C00))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AfriButton(
                label: 'SAVE LIVESTOCK GROUP',
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _updateLsuTlu();
                    widget.onGroupAdded(
                      LivestockGroupModel(
                        id: 'lg_${DateTime.now().millisecondsSinceEpoch}',
                        farmId: 'f1',
                        name: _nameController.text.trim(),
                        species: _selectedSpecies,
                        numberOfAnimals: int.parse(_countController.text),
                        averageWeightKg: double.tryParse(_weightController.text),
                        lsuValue: _calculatedLsu,
                        tluValue: _calculatedTlu,
                        notes: _notesController.text.trim(),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:afrirange_ai/features/grazing/services/grazing_api_service.dart';
import 'package:afrirange_ai/core/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'create_rotational_plan_screen.dart';
import 'plan_calendar_screen.dart';

class RotationalPlansScreen extends StatefulWidget {
  const RotationalPlansScreen({super.key});

  @override
  State<RotationalPlansScreen> createState() => _RotationalPlansScreenState();
}

class _RotationalPlansScreenState extends State<RotationalPlansScreen> {
  late final GrazingApiService _apiService;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _plans = [];
  String? _selectedFarmId;

  @override
  void initState() {
    super.initState();
    _apiService = GrazingApiService(authToken: 'dummy_token_for_now');
    _selectedFarmId = 'farm_1'; // In real app, this would come from auth state
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      if (_selectedFarmId != null) {
        final plans = await _apiService.getRotationalPlans(_selectedFarmId!);
        setState(() {
          _plans = plans;
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

  Future<void> _refreshPlans() async {
    await _loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotational Grazing Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create New Plan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateRotationalPlanScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _refreshPlans,
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
                        'Error loading plans',
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
                        onPressed: _loadPlans,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _plans.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available, color: Colors.grey, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'No rotational plans created yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first plan to start optimizing grazing rotations',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _plans.length,
                      itemBuilder: (context, index) {
                        final plan = _plans[index];
                        return _buildPlanCard(plan);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateRotationalPlanScreen(),
            ),
          );
        },
        tooltip: 'Create New Plan',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlanCalendarScreen(planId: plan['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan['planName'] ?? 'Unnamed Plan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${plan['startDate']} to ${plan['endDate']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${plan['paddocks']?.length ?? 0} Paddocks',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPlanStat('Duration', '${_calculateDuration(plan)} days'),
                  _buildPlanStat('Paddocks', '${plan['paddocks']?.length ?? 0}'),
                  _buildPlanStat('Avg Rest', '${_calculateAvgRest(plan)} days'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateDuration(Map<String, dynamic> plan) {
    try {
      final start = DateTime.parse(plan['startDate']);
      final end = DateTime.parse(plan['endDate']);
      return end.difference(start).inDays + 1;
    } catch (e) {
      return 0;
    }
  }

  int _calculateAvgRest(Map<String, dynamic> plan) {
    try {
      final paddocks = plan['paddocks'] as List<dynamic>? ?? [];
      if (paddocks.isEmpty) return 0;
      
      final totalRest = paddocks.fold<int>(
        0, 
        (sum, p) => sum + (p['restDays'] as int? ?? 45)
      );
      return (totalRest / paddocks.length).round();
    } catch (e) {
      return 45;
    }
  }

  Widget _buildPlanStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
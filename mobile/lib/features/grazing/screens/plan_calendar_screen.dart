import 'package:flutter/material.dart';
import 'package:afrirange_ai/features/grazing/services/grazing_api_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class PlanCalendarScreen extends StatefulWidget {
  final String? planId;
  const PlanCalendarScreen({super.key, this.planId});

  @override
  State<PlanCalendarScreen> createState() => _PlanCalendarScreenState();
}

class _PlanCalendarScreenState extends State<PlanCalendarScreen> {
  late final GrazingApiService _apiService;
  String? _selectedFarmId;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<dynamic> _plans = [];

  @override
  void initState() {
    super.initState();
    _apiService = GrazingApiService(authToken: 'dummy_token_for_now');
    _selectedFarmId = 'farm_1';
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final plans = await _apiService.getRotationalPlans(_selectedFarmId!);
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
      
      // Populate events for calendar
      _populateEventsFromPlans();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _populateEventsFromPlans() {
    _events.clear();
    
    for (final plan in _plans) {
      final startDate = DateTime.parse(plan['start_date']);
      final endDate = DateTime.parse(plan['end_date']);
      final planName = plan['plan_name'];
      
      // Add event for start date
      final startKey = DateTime(startDate.year, startDate.month, startDate.day);
      if (_events[startKey] == null) {
        _events[startKey] = [];
      }
      _events[startKey]!.add({
        'type': 'start',
        'planId': plan['id'],
        'planName': planName,
        'color': Colors.green,
        'title': 'Plan Start: $planName',
      });
      
      // Add event for end date
      final endKey = DateTime(endDate.year, endDate.month, endDate.day);
      if (_events[endKey] == null) {
        _events[endKey] = [];
      }
      _events[endKey]!.add({
        'type': 'end',
        'planId': plan['id'],
        'planName': planName,
        'color': Colors.red,
        'title': 'Plan End: $planName',
      });
    }
    
    setState(() {});
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotational Planning Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlans,
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
              : Column(
                  children: [
                    // Calendar header with stats
                    _buildCalendarHeader(),
                    
                    const SizedBox(height: 8),
                    
                    // Calendar
                    Expanded(
                      child: TableCalendar(
                        firstDay: DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        eventLoader: _getEventsForDay,
                        calendarStyle: const CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          weekendDecoration: BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarBuilders: CalendarBuilders(
                          marker: (context, day, events) {
                            if (events.isEmpty) return null;
                            return Positioned(
                              right: 1,
                              bottom: 1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: events.first['color'] ?? Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Events for selected day
                    if (_selectedDay != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Events for ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _getEventsForDay(_selectedDay!).isEmpty
                                ? const Text(
                                    'No events scheduled for this day',
                                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _getEventsForDay(_selectedDay!).length,
                                    itemBuilder: (context, index) {
                                      final event = _getEventsForDay(_selectedDay!)[index];
                                      return ListTile(
                                        leading: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: event['color'],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        title: Text(event['title'] as String),
                                        subtitle: event['type'] == 'start'
                                            ? const Text('Grazing period begins')
                                            : const Text('Grazing period ends'),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'UPCOMING PLANS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              TextButton.icon(
                onPressed: () {
                  // Navigate to create plan screen
                  // Navigator.of(context).push(MaterialPageRoute(
                  //   builder: (context) => const CreateRotationalPlanScreen(),
                  // ));
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('New Plan'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Active Plans', _plans.where((p) => 
                DateTime.parse(p['end_date']).isAfter(DateTime.now())
              ).length.toString()),
              _buildStatCard(
                'Avg Duration',
                _plans.isNotEmpty
                    ? '${(_plans.fold<int>(0, (sum, p) => sum + DateTime.parse(p['end_date']).difference(DateTime.parse(p['start_date'])).inDays) / _plans.length).toStringAsFixed(0)} days'
                    : '0 days',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
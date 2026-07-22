import 'package:flutter/material.dart';
import 'package:afrirange_ai/features/grazing/services/grazing_api_service.dart';
import 'package:afrirange_ai/core/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/grazing_recommendation_model.dart';

class RecommendationDetailScreen extends StatefulWidget {
  final String recommendationId;

  const RecommendationDetailScreen({
    super.key,
    required this.recommendationId,
  });

  @override
  State<RecommendationDetailScreen> createState() => _RecommendationDetailScreenState();
}

class _RecommendationDetailScreenState extends State<RecommendationDetailScreen> {
  late final GrazingApiService _apiService;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  GrazingRecommendationModel? _recommendation;

  @override
  void initState() {
    super.initState();
    _apiService = GrazingApiService(authToken: 'dummy_token_for_now');
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final recommendation = await _apiService.getGrazingRecommendation(widget.recommendationId);
      setState(() {
        _recommendation = recommendation;
        _isLoading = false;
      });
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
        title: const Text('Recommendation Details'),
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
                        'Error loading recommendation',
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
                        onPressed: _loadRecommendation,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _recommendation == null
                  ? const Center(child: Text('Recommendation not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recommendation header
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _recommendation!.riskDisplayLabel,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(_recommendation!.riskColorValue),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _recommendation!.recommendedAction,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildMetricCard(
                                        'Days Left',
                                        '${_recommendation!.grazingDaysRemaining}d',
                                      ),
                                      _buildMetricCard(
                                        'Target LSU/ha',
                                        _recommendation!.recommendedStockingRate != null
                                            ? '${_recommendation!.recommendedStockingRate!.toStringAsFixed(2)}'
                                            : 'N/A',
                                      ),
                                      _buildMetricCard(
                                        'Rest Period',
                                        '${_recommendation!.restPeriodDays} days',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // AI Explanation
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.psychology, size: 20, color: Color(0xFF2E7D32)),
                          SizedBox(width: 8),
                          Text(
                            'AI Explanation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _recommendation!.aiExplanation,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Metadata
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recommendation Details',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildMetadataItem('Generated', _recommendation!.recommendationDate),
                                      _buildMetadataItem('Risk Level', _recommendation!.riskLevel.toUpperCase()),
                                      _buildMetadataItem('Days Remaining', '${_recommendation!.grazingDaysRemaining}d'),
                                      _buildMetadataItem(
                                        'Stocking Rate',
                                        _recommendation!.recommendedStockingRate != null
                                            ? '${_recommendation!.recommendedStockingRate!.toStringAsFixed(2)} LSU/ha'
                                            : 'N/A',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Action buttons
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // In a real app, this would trigger action planning
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Action plan created! Check your Rotational Plans.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('CREATE ACTION PLAN'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
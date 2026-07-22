import 'package:flutter/material.dart';
import 'package:afrirange_ai/features/grazing/services/grazing_api_service.dart';
import 'package:afrirange_ai/core/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/grazing_recommendation_model.dart';
import 'recommendation_detail_screen.dart';

class RecommendationDashboardScreen extends StatefulWidget {
  const RecommendationDashboardScreen({super.key});

  @override
  State<RecommendationDashboardScreen> createState() => _RecommendationDashboardScreenState();
}

class _RecommendationDashboardScreenState extends State<RecommendationDashboardScreen> {
  late final GrazingApiService _apiService;
 bool _isLoading = true;
 bool _hasError = false;
 String? _errorMessage;
 List<GrazingRecommendationModel> _recommendations = [];
 String? _selectedFarmId;

 @override
 void initState() {
   super.initState();
   _apiService = GrazingApiService(authToken: 'dummy_token_for_now');
   _selectedFarmId = 'farm_1';
   _loadRecommendations();
 }

 Future<void> _loadRecommendations() async {
   setState(() {
     _isLoading = true;
     _hasError = false;
   });

   try {
     if (_selectedFarmId != null) {
       final recommendations = await _apiService.getGrazingRecommendations(_selectedFarmId!);
       setState(() {
         _recommendations = recommendations;
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

 Future<void> _refreshRecommendations() async {
   setState(() => _isLoading = true);
   try {
     if (_selectedFarmId != null) {
       await _apiService.refreshGrazingRecommendations(_selectedFarmId!);
       final recommendations = await _apiService.getGrazingRecommendations(_selectedFarmId!);
       setState(() {
         _recommendations = recommendations;
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

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: const Text('AI Grazing Recommendations'),
       actions: [
         IconButton(
           icon: const Icon(Icons.refresh),
           tooltip: 'Refresh Recommendations',
           onPressed: _isLoading ? null : _refreshRecommendations,
         ),
         IconButton(
           icon: const Icon(Icons.add),
           tooltip: 'Generate New Recommendation',
           onPressed: _isLoading ? null : _generateNewRecommendation,
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
                       'Error loading recommendations',
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
                       onPressed: _loadRecommendations,
                       child: const Text('Retry'),
                     ),
                   ],
                 ),
               )
             : _recommendations.isEmpty
                 ? Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.psychology, color: Colors.grey, size: 48),
                         const SizedBox(height: 16),
                         const Text(
                           'No recommendations available yet',
                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           'Generate your first recommendation to get AI-powered grazing advice',
                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                           textAlign: TextAlign.center,
                         ),
                       ],
                     ),
                   )
                 : ListView.builder(
                     itemCount: _recommendations.length,
                     itemBuilder: (context, index) {
                       return _buildRecommendationCard(_recommendations[index]);
                     },
                   ),
     floatingActionButton: FloatingActionButton(
       onPressed: _isLoading ? null : _generateNewRecommendation,
       tooltip: 'Generate New Recommendation',
       child: const Icon(Icons.psychology),
     ),
   );
 }

 void _generateNewRecommendation() {
   // Navigate to a screen where user can generate a new recommendation
   // For now, we'll show a snackbar indicating this feature
   ScaffoldMessenger.of(context).showSnackBar(
     const SnackBar(
       content: Text('Recommendation generation initiated. Check back in a few moments.'),
       backgroundColor: Colors.green,
     ),
   );
   // In a real app, we would navigate to a generation screen or trigger the API call
   // For demo purposes, we'll refresh after a delay
   Future.delayed(const Duration(seconds: 3), () {
     if (mounted) {
       _refreshRecommendations();
     }
   });
 }

 Widget _buildRecommendationCard(GrazingRecommendationModel rec) {
   return Card(
     elevation: 3,
     margin: const EdgeInsets.only(bottom: 16),
     shape: RoundedRectangleBorder(
       side: BorderSide(color: Color(rec.riskColorValue), width: 2),
       borderRadius: BorderRadius.circular(12),
     ),
     child: InkWell(
       onTap: () {
         Navigator.push(
           context,
           MaterialPageRoute(
             builder: (_) => RecommendationDetailScreen(
               recommendationId: rec.id,
             ),
           ),
         );
       },
       child: Padding(
         padding: const EdgeInsets.all(16),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             // Header with risk level and action
             Row(
               children: [
                 Container(
                   width: 48,
                   height: 48,
                   decoration: BoxDecoration(
                     color: Color(rec.riskColorValue).withOpacity(0.12),
                     shape: BoxShape.circle,
                   ),
                   child: Center(
                     child: Text(
                       '${rec.grazingDaysRemaining}d',
                       style: TextStyle(
                         fontSize: 14,
                         fontWeight: FontWeight.bold,
                         color: Color(rec.riskColorValue),
                       ),
                     ),
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         rec.riskDisplayLabel,
                         style: TextStyle(
                           fontWeight: FontWeight.bold,
                           color: Color(rec.riskColorValue),
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         rec.recommendedAction,
                         maxLines: 2,
                         overflow: TextOverflow.ellipsis,
                         style: const TextStyle(fontSize: 14),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 12),
             
             // Metrics row
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 _buildMetric('Days Left', '${rec.grazingDaysRemaining}'),
                 _buildMetric(
                   'Target LSU/ha',
                   rec.recommendedStockingRate != null
                       ? '${rec.recommendedStockingRate!.toStringAsFixed(2)}'
                       : 'N/A',
                 ),
                 _buildMetric('Rest Period', '${rec.restPeriodDays} days'),
               ],
             ),
             const SizedBox(height: 16),
             
             // AI Explanation preview
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: const Color(0xFF2E7D32).withOpacity(0.05),
                 border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Row(
                     children: [
                       Icon(Icons.psychology, size: 16, color: Color(0xFF2E7D32)),
                       SizedBox(width: 6),
                       Text(
                         'AI Insight',
                         style: TextStyle(
                           fontWeight: FontWeight.bold,
                           color: Color(0xFF2E7D32),
                           fontSize: 12,
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 6),
                   Text(
                     rec.aiExplanation.length > 100
                         ? '${rec.aiExplanation.substring(0, 100)}...'
                         : rec.aiExplanation,
                     style: const TextStyle(fontSize: 12, height: 1.4),
                     maxLines: 3,
                     overflow: TextOverflow.ellipsis,
                   ),
                 ],
               ),
             ),
             const SizedBox(height: 8),
             
             // Footer with date and action indicator
             Align(
               alignment: Alignment.centerRight,
               child: Text(
                 'Generated: ${rec.recommendationDate}',
                 style: const TextStyle(fontSize: 10, color: Colors.grey),
               ),
             ),
           ],
         ),
       ),
     ),
   );
 }

 Widget _buildMetric(String label, String value) {
   return Column(
     children: [
       Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
       const SizedBox(height: 2),
       Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
     ],
   );
 }
}
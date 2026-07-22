import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vegetation_health_model.dart';
import '../models/grazing_recommendation_model.dart';
import '../../../config/env.dart';

class GrazingApiService {
  final String baseUrl = Env.apiUrl;
  final String authToken;

  GrazingApiService({required this.authToken});

  // Headers with authentication
  Map<String, String> _getHeaders() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  // SATELLITE DATA ENDPOINTS
  Future<List<VegetationHealthModel>> getSatelliteData(String paddockId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/grazing-zones/$paddockId/satellite-data'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['satelliteObservations'] as List)
          .map((item) => VegetationHealthModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load satellite data: ${response.statusCode}');
    }
  }

  Future<List<VegetationHealthModel>> getVegetationTrends(String paddockId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/grazing-zones/$paddockId/vegetation-trends'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['trends'] as List)
          .map((item) => VegetationHealthModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load vegetation trends: ${response.statusCode}');
    }
  }

  // REFRESH SATELLITE DATA
  Future<void> refreshSatelliteData(String paddockId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/grazing-zones/$paddockId/refresh-satellite-data'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to refresh satellite data: ${response.statusCode}');
    }
  }

  // BIOMASS ENDPOINTS
  Future<Map<String, dynamic>?> getBiomass(String paddockId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/grazing-zones/$paddockId/biomass'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['latestEstimate'];
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load biomass: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> calculateBiomass(String paddockId, double areaHa) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/grazing-zones/$paddockId/biomass'),
      headers: _getHeaders(),
      body: json.encode({'areaHa': areaHa}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['biomassEstimate'];
    } else {
      throw Exception('Failed to calculate biomass: ${response.statusCode}');
    }
  }

  // GRAZING RECOMMENDATIONS
  Future<List<GrazingRecommendationModel>> getGrazingRecommendations(String farmId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/farms/$farmId/grazing-recommendations'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['recommendations'] as List)
          .map((item) => GrazingRecommendationModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load grazing recommendations: ${response.statusCode}');
    }
  }

  Future<GrazingRecommendationModel> generateGrazingRecommendation(
      String farmId, double actualLsu, double recommendedLsu) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/farms/$farmId/generate-grazing-recommendation'),
      headers: _getHeaders(),
      body: json.encode({
        'actualLsu': actualLsu,
        'recommendedLsu': recommendedLsu,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return GrazingRecommendationModel.fromJson(data['recommendation']);
    } else {
      throw Exception('Failed to generate grazing recommendation: ${response.statusCode}');
    }
  }

  Future<GrazingRecommendationModel> getGrazingRecommendation(String recId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/grazing-recommendations/$recId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return GrazingRecommendationModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load grazing recommendation: ${response.statusCode}');
    }
  }

  Future<void> refreshGrazingRecommendations(String farmId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/farms/$farmId/refresh-grazing-recommendations'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to refresh grazing recommendations: ${response.statusCode}');
    }
  }

  // ROTATIONAL PLANS
  Future<List<Map<String, dynamic>>> getRotationalPlans(String farmId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/farms/$farmId/rotational-plans'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body)['rotationalPlans']);
    } else {
      throw Exception('Failed to load rotational plans: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createRotationalPlan(
      String farmId, Map<String, dynamic> planData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/farms/$farmId/rotational-plans'),
      headers: _getHeaders(),
      body: json.encode(planData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body)['rotationalPlan'];
    } else {
      throw Exception('Failed to create rotational plan: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateRotationalPlan(
      String planId, Map<String, dynamic> planData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/rotational-plans/$planId'),
      headers: _getHeaders(),
      body: json.encode(planData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update rotational plan: ${response.statusCode}');
    }
  }

  Future<void> deleteRotationalPlan(String planId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/rotational-plans/$planId'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete rotational plan: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getRotationalPlan(String planId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rotational-plans/$planId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['rotationalPlan'];
    } else {
      throw Exception('Failed to load rotational plan: ${response.statusCode}');
    }
  }
}
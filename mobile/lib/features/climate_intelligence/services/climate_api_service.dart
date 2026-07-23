import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/climate_models.dart';
import '../../../config/env.dart';

import '../../../core/database/app_database.dart';

class ClimateApiService {
  final String baseUrl = Env.apiUrl;
  final String authToken;
  final AppDatabase _db = AppDatabase.instance;

  ClimateApiService({required this.authToken});

  Map<String, String> _getHeaders() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  // CLIMATE DATA ENDPOINTS
  Future<ClimateModel> getCurrentClimate(String farmId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/farms/$farmId/climate/current'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final model = ClimateModel.fromJson(data);

        // Cache locally in SQLite
        await _db.insertClimateObservation({
          'id': model.id,
          'farm_id': farmId,
          'observation_date': model.observationDate.toIso8601String().substring(0, 10),
          'rainfall_mm': model.rainfallMm,
          'temperature_c': model.temperatureC,
          'humidity_percentage': model.humidityPercentage,
          'evapotranspiration_mm': model.evapotranspirationMm,
          'data_source': model.dataSource,
          'created_at': DateTime.now().toIso8601String(),
          'sync_status': 'synced',
        });

        return model;
      }
    } catch (_) {
      // Fallback to local SQLite cache if offline
    }

    final localRows = await _db.getClimateObservations(farmId);
    if (localRows.isNotEmpty) {
      final row = localRows.first;
      return ClimateModel(
        id: row['id'] as String,
        observationDate: DateTime.parse(row['observation_date'] as String),
        rainfallMm: (row['rainfall_mm'] as num).toDouble(),
        temperatureC: (row['temperature_c'] as num?)?.toDouble() ?? 25.0,
        humidityPercentage: (row['humidity_percentage'] as num?)?.toDouble() ?? 50.0,
        evapotranspirationMm: (row['evapotranspiration_mm'] as num?)?.toDouble() ?? 4.5,
        dataSource: row['data_source'] as String? ?? 'CHIRPS (Cached)',
      );
    }

    throw Exception('No climate data available online or offline.');
  }

  Future<List<ClimateModel>> getClimateHistory(String farmId, {int limit = 12}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/farms/$farmId/climate/history?limit=$limit'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['history'] as List)
            .map((item) => ClimateModel.fromJson(item))
            .toList();

        // Cache in SQLite
        for (final model in list) {
          await _db.insertClimateObservation({
            'id': model.id,
            'farm_id': farmId,
            'observation_date': model.observationDate.toIso8601String().substring(0, 10),
            'rainfall_mm': model.rainfallMm,
            'temperature_c': model.temperatureC,
            'humidity_percentage': model.humidityPercentage,
            'evapotranspiration_mm': model.evapotranspirationMm,
            'data_source': model.dataSource,
            'created_at': DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          });
        }
        return list;
      }
    } catch (_) {
      // Offline fallback
    }

    final localRows = await _db.getClimateObservations(farmId);
    if (localRows.isNotEmpty) {
      return localRows.take(limit).map((row) {
        return ClimateModel(
          id: row['id'] as String,
          observationDate: DateTime.parse(row['observation_date'] as String),
          rainfallMm: (row['rainfall_mm'] as num).toDouble(),
          temperatureC: (row['temperature_c'] as num?)?.toDouble() ?? 25.0,
          humidityPercentage: (row['humidity_percentage'] as num?)?.toDouble() ?? 50.0,
          evapotranspirationMm: (row['evapotranspiration_mm'] as num?)?.toDouble() ?? 4.5,
          dataSource: row['data_source'] as String? ?? 'CHIRPS (Cached)',
        );
      }).toList();
    }

    return [];
  }

  Future<void> refreshClimateData(String farmId, {int months = 1}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/farms/$farmId/climate/refresh'),
      headers: _getHeaders(),
      body: json.encode({'months': months}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to refresh climate data: ${response.statusCode}');
    }
  }

  // DROUGHT FORECAST ENDPOINTS
  Future<List<DroughtForecastModel>> getDroughtForecasts(
      String farmId, {int? period}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/farms/$farmId/drought-forecast');
      final queryParams = {
        if (period != null) 'period': period.toString(),
      };
      final uriWithParams = uri.replace(queryParameters: queryParams);

      final response = await http.get(uriWithParams, headers: _getHeaders()).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['forecasts'] as List)
            .map((item) => DroughtForecastModel.fromJson(item))
            .toList();

        // Cache forecasts locally
        for (final fc in list) {
          await _db.insertDroughtForecast({
            'id': fc.id,
            'farm_id': farmId,
            'forecast_date': fc.forecastDate.toIso8601String().substring(0, 10),
            'forecast_period_days': fc.forecastPeriodDays,
            'drought_risk_level': fc.droughtRiskLevel,
            'drought_risk_score': fc.droughtRiskScore,
            'rainfall_probability': fc.rainfallProbability,
            'forage_shortage_probability': fc.forageShortageProbability,
            'water_stress_probability': fc.waterStressProbability,
            'heat_stress_probability': fc.heatStressProbability,
            'forage_days_remaining': fc.forageDaysRemaining,
            'ai_explanation': fc.aiExplanation,
            'created_at': DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          });
        }
        return list;
      }
    } catch (_) {
      // Offline fallback
    }

    final localRows = await _db.getDroughtForecasts(farmId);
    if (localRows.isNotEmpty) {
      return localRows.map((row) {
        return DroughtForecastModel(
          id: row['id'] as String,
          forecastDate: DateTime.parse(row['forecast_date'] as String),
          forecastPeriodDays: row['forecast_period_days'] as int,
          droughtRiskLevel: row['drought_risk_level'] as String,
          droughtRiskScore: (row['drought_risk_score'] as num?)?.toDouble() ?? 0.0,
          rainfallProbability: (row['rainfall_probability'] as num?)?.toDouble() ?? 50.0,
          forageShortageProbability: (row['forage_shortage_probability'] as num?)?.toDouble() ?? 30.0,
          waterStressProbability: (row['water_stress_probability'] as num?)?.toDouble() ?? 25.0,
          heatStressProbability: (row['heat_stress_probability'] as num?)?.toDouble() ?? 20.0,
          forageDaysRemaining: row['forage_days_remaining'] as int? ?? 60,
          aiExplanation: row['ai_explanation'] as String? ?? 'Offline cached forecast',
        );
      }).toList();
    }

    return [];
  }

  Future<DroughtForecastModel> generateDroughtForecast(
      String farmId, List<int> periods) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/farms/$farmId/generate-drought-forecast'),
      headers: _getHeaders(),
      body: json.encode({'periods': periods}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DroughtForecastModel.fromJson(data['forecasts'][0]);
    } else {
      throw Exception('Failed to generate drought forecast: ${response.statusCode}');
    }
  }

  // ALERT ENDPOINTS
  Future<List<ClimateAlertModel>> getAlerts(
      String farmId, {bool unacknowledgedOnly = false, int limit = 50}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/farms/$farmId/alerts');
      final queryParams = {
        if (unacknowledgedOnly) 'unacknowledged': 'true',
        'limit': limit.toString(),
      };
      final uriWithParams = uri.replace(queryParameters: queryParams);

      final response = await http.get(uriWithParams, headers: _getHeaders()).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['alerts'] as List)
            .map((item) => ClimateAlertModel.fromJson(item))
            .toList();

        // Cache alerts locally
        for (final alert in list) {
          await _db.insertClimateAlert({
            'id': alert.id,
            'farm_id': farmId,
            'alert_type': alert.alertType,
            'risk_level': alert.riskLevel,
            'title': alert.title,
            'message': alert.message,
            'recommended_action': alert.recommendedAction,
            'created_at': alert.createdAt.toIso8601String(),
            'acknowledged_at': alert.acknowledgedAt?.toIso8601String(),
            'sync_status': 'synced',
          });
        }
        return list;
      }
    } catch (_) {
      // Offline fallback
    }

    final localRows = await _db.getClimateAlerts(farmId);
    if (localRows.isNotEmpty) {
      final list = localRows.map((row) {
        return ClimateAlertModel(
          id: row['id'] as String,
          alertType: row['alert_type'] as String,
          riskLevel: row['risk_level'] as String,
          title: row['title'] as String,
          message: row['message'] as String,
          recommendedAction: row['recommended_action'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          acknowledgedAt: row['acknowledged_at'] != null ? DateTime.parse(row['acknowledged_at'] as String) : null,
        );
      }).toList();

      if (unacknowledgedOnly) {
        return list.where((a) => a.acknowledgedAt == null).toList();
      }
      return list;
    }

    return [];
  }

  Future<void> acknowledgeAlert(String alertId) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/alerts/$alertId/acknowledge'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        await _db.acknowledgeClimateAlert(alertId);
        return;
      }
    } catch (_) {
      // Save locally & queue sync
      await _db.acknowledgeClimateAlert(alertId);
    }
  }
}
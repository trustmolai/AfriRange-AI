import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/**
 * Offline SQLite Database Engine for AfriRange AI
 * Manages local spatial paddocks, plant species catalog, survey logs, 
 * grazing intelligence data, and sync mutation queues.
 */
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'afrirange_offline.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    // 1. Local Paddocks table
    await db.execute('''
      CREATE TABLE paddocks (
        id TEXT PRIMARY KEY,
        farm_id TEXT,
        name TEXT NOT NULL,
        boundary_geojson TEXT NOT NULL,
        area_ha REAL NOT NULL,
        target_rest_days INTEGER DEFAULT 45,
        baseline_lsu_per_ha REAL DEFAULT 0.20,
        current_status TEXT DEFAULT 'rested',
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // 2. Bundled Plant Species Catalog (Offline botanical catalog)
    await db.execute('''
      CREATE TABLE plant_species (
        id TEXT PRIMARY KEY,
        scientific_name TEXT UNIQUE NOT NULL,
        common_names_json TEXT NOT NULL,
        family TEXT,
        growth_form TEXT,
        ecological_status TEXT,
        palatability TEXT,
        grazing_value TEXT,
        drought_tolerance TEXT,
        typical_biomass_yield REAL
      )
    ''');

    // 3. Local Botanical Observations Log
    await db.execute('''
      CREATE TABLE plant_observations (
        id TEXT PRIMARY KEY,
        paddock_id TEXT,
        species_id TEXT,
        abundance_pct REAL,
        condition TEXT,
        recorded_at TEXT,
        notes TEXT,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    // 4. OFFLINE SATELLITE OBSERVATIONS (NDVI/EVI/Biomass)
    await db.execute('''
      CREATE TABLE satellite_observations (
        id TEXT PRIMARY KEY,
        paddock_id TEXT,
        observation_date TEXT NOT NULL,
        ndvi_value REAL NOT NULL,
        evi_value REAL,
        biomass_kg_per_ha REAL NOT NULL,
        data_source TEXT DEFAULT 'Sentinel-2',
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    // 5. OFFLINE BIOMASS ESTIMATES
    await db.execute('''
      CREATE TABLE biomass_estimates (
        id TEXT PRIMARY KEY,
        paddock_id TEXT,
        estimate_date TEXT NOT NULL,
        biomass_kg_per_ha REAL NOT NULL,
        total_available_forage_kg REAL NOT NULL,
        confidence_level TEXT DEFAULT 'high',
        method TEXT,
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    // 6. OFFLINE GRAZING RECOMMENDATIONS
    await db.execute('''
      CREATE TABLE grazing_recommendations (
        id TEXT PRIMARY KEY,
        farm_id TEXT,
        paddock_id TEXT,
        recommendation_date TEXT NOT NULL,
        recommended_action TEXT NOT NULL,
        grazing_days_remaining INTEGER,
        recommended_stocking_rate REAL,
        rest_period_days INTEGER,
        risk_level TEXT DEFAULT 'low',
        ai_explanation TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    // 7. OFFLINE ROTATIONAL GRAZING PLANS
    await db.execute('''
      CREATE TABLE rotational_grazing_plans (
        id TEXT PRIMARY KEY,
        farm_id TEXT,
        plan_name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    // 8. OFFLINE ROTATIONAL PLAN PADDOCKS (Junction)
    await db.execute('''
      CREATE TABLE rotational_plan_paddocks (
        id TEXT PRIMARY KEY,
        plan_id TEXT,
        paddock_id TEXT,
        grazing_start_date TEXT NOT NULL,
        grazing_end_date TEXT,
        rest_days INTEGER DEFAULT 45,
        sequence_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');

    // 9. Climate Observations
    await db.execute('''
      CREATE TABLE climate_observations (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        observation_date TEXT NOT NULL,
        rainfall_mm REAL DEFAULT 0.0,
        temperature_c REAL,
        humidity_percentage REAL,
        evapotranspiration_mm REAL,
        data_source TEXT DEFAULT 'CHIRPS',
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // 10. Drought Forecasts
    await db.execute('''
      CREATE TABLE drought_forecasts (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        forecast_date TEXT NOT NULL,
        forecast_period_days INTEGER NOT NULL,
        drought_risk_level TEXT NOT NULL,
        drought_risk_score REAL DEFAULT 0.0,
        rainfall_probability REAL,
        forage_shortage_probability REAL,
        water_stress_probability REAL,
        heat_stress_probability REAL,
        forage_days_remaining INTEGER,
        ai_explanation TEXT,
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // 11. Climate Alerts
    await db.execute('''
      CREATE TABLE climate_alerts (
        id TEXT PRIMARY KEY,
        farm_id TEXT NOT NULL,
        alert_type TEXT NOT NULL,
        risk_level TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        recommended_action TEXT NOT NULL,
        created_at TEXT NOT NULL,
        acknowledged_at TEXT,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // 12. Pending Mutations Sync Queue
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) {
    Batch batch = db.batch();

    if (oldVersion < 2) {
      batch.execute('''
        CREATE TABLE IF NOT EXISTS satellite_observations (
          id TEXT PRIMARY KEY,
          paddock_id TEXT,
          observation_date TEXT NOT NULL,
          ndvi_value REAL NOT NULL,
          evi_value REAL,
          biomass_kg_per_ha REAL NOT NULL,
          data_source TEXT DEFAULT 'Sentinel-2',
          created_at TEXT NOT NULL,
          sync_status TEXT DEFAULT 'pending'
        )
      ''');
      
      batch.execute('''
        CREATE TABLE IF NOT EXISTS biomass_estimates (
          id TEXT PRIMARY KEY,
          paddock_id TEXT,
          estimate_date TEXT NOT NULL,
          biomass_kg_per_ha REAL NOT NULL,
          total_available_forage_kg REAL NOT NULL,
          confidence_level TEXT DEFAULT 'high',
          method TEXT,
          created_at TEXT NOT NULL,
          sync_status TEXT DEFAULT 'pending'
        )
      ''');
      
      batch.execute('''
        CREATE TABLE IF NOT EXISTS grazing_recommendations (
          id TEXT PRIMARY KEY,
          farm_id TEXT,
          paddock_id TEXT,
          recommendation_date TEXT NOT NULL,
          recommended_action TEXT NOT NULL,
          grazing_days_remaining INTEGER,
          recommended_stocking_rate REAL,
          rest_period_days INTEGER,
          risk_level TEXT DEFAULT 'low',
          ai_explanation TEXT NOT NULL,
          created_at TEXT NOT NULL,
          sync_status TEXT DEFAULT 'pending'
        )
      ''');
      
      batch.execute('''
        CREATE TABLE IF NOT EXISTS rotational_grazing_plans (
          id TEXT PRIMARY KEY,
          farm_id TEXT,
          plan_name TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          sync_status TEXT DEFAULT 'pending'
        )
      ''');
      
      batch.execute('''
        CREATE TABLE IF NOT EXISTS rotational_plan_paddocks (
          id TEXT PRIMARY KEY,
          plan_id TEXT,
          paddock_id TEXT,
          grazing_start_date TEXT NOT NULL,
          grazing_end_date TEXT,
          rest_days INTEGER DEFAULT 45,
          sequence_order INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          sync_status TEXT DEFAULT 'pending'
        )
      ''');
    }

    if (oldVersion < 3) {
      batch.execute('''
        CREATE TABLE IF NOT EXISTS climate_observations (
          id TEXT PRIMARY KEY,
          farm_id TEXT NOT NULL,
          observation_date TEXT NOT NULL,
          rainfall_mm REAL DEFAULT 0.0,
          temperature_c REAL,
          humidity_percentage REAL,
          evapotranspiration_mm REAL,
          data_source TEXT DEFAULT 'CHIRPS',
          created_at TEXT NOT NULL,
          sync_status TEXT DEFAULT 'synced'
        )
      ''');

      batch.execute('''
        CREATE TABLE IF NOT EXISTS drought_forecasts (
          id TEXT PRIMARY KEY,
          farm_id TEXT NOT NULL,
          forecast_date TEXT NOT NULL,
          forecast_period_days INTEGER NOT NULL,
          drought_risk_level TEXT NOT NULL,
          drought_risk_score REAL DEFAULT 0.0,
          rainfall_probability REAL,
          forage_shortage_probability REAL,
          water_stress_probability REAL,
          heat_stress_probability REAL,
          forage_days_remaining INTEGER,
          ai_explanation TEXT,
          created_at TEXT NOT NULL,
          sync_status TEXT DEFAULT 'synced'
        )
      ''');

      batch.execute('''
        CREATE TABLE IF NOT EXISTS climate_alerts (
          id TEXT PRIMARY KEY,
          farm_id TEXT NOT NULL,
          alert_type TEXT NOT NULL,
          risk_level TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          recommended_action TEXT NOT NULL,
          created_at TEXT NOT NULL,
          acknowledged_at TEXT,
          sync_status TEXT DEFAULT 'synced'
        )
      ''');
    }
      
    batch.commit();
  }

  // Paddocks CRUD
  Future<int> insertPaddock(Map<String, dynamic> paddock) async {
    final db = await database;
    return await db.insert('paddocks', paddock, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPaddocks() async {
    final db = await database;
    return await db.query('paddocks');
  }

  // Satellite Observations CRUD
  Future<int> insertSatelliteObservation(Map<String, dynamic> obs) async {
    final db = await database;
    return await db.insert('satellite_observations', obs, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getSatelliteObservations(String paddockId) async {
    final db = await database;
    return await db.query(
      'satellite_observations',
      where: 'paddock_id = ?',
      whereArgs: [paddockId],
      orderBy: 'observation_date DESC'
    );
  }

  // Biomass Estimates CRUD
  Future<int> insertBiomassEstimate(Map<String, dynamic> estimate) async {
    final db = await database;
    return await db.insert('biomass_estimates', estimate, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getBiomassEstimates(String paddockId) async {
    final db = await database;
    return await db.query(
      'biomass_estimates',
      where: 'paddock_id = ?',
      whereArgs: [paddockId],
      orderBy: 'estimate_date DESC'
    );
  }

  Future<Map<String, dynamic>?> getLatestBiomassEstimate(String paddockId) async {
    final db = await database;
    final result = await db.query(
      'biomass_estimates',
      where: 'paddock_id = ?',
      whereArgs: [paddockId],
      orderBy: 'estimate_date DESC',
      limit: 1
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Grazing Recommendations CRUD
  Future<int> insertGrazingRecommendation(Map<String, dynamic> recommendation) async {
    final db = await database;
    return await db.insert('grazing_recommendations', recommendation, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getGrazingRecommendations(String farmId) async {
    final db = await database;
    return await db.query(
      'grazing_recommendations',
      where: 'farm_id = ?',
      whereArgs: [farmId],
      orderBy: 'recommendation_date DESC'
    );
  }

  // Rotational Plans CRUD
  Future<int> insertRotationalPlan(Map<String, dynamic> plan) async {
    final db = await database;
    return await db.insert('rotational_grazing_plans', plan, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getRotationalPlans(String farmId) async {
    final db = await database;
    return await db.query(
      'rotational_grazing_plans',
      where: 'farm_id = ?',
      whereArgs: [farmId],
      orderBy: 'start_date DESC'
    );
  }

  Future<Map<String, dynamic>?> getRotationalPlan(String planId) async {
    final db = await database;
    final result = await db.query(
      'rotational_grazing_plans',
      where: 'id = ?',
      whereArgs: [planId],
      limit: 1
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateRotationalPlan(String planId, Map<String, dynamic> updates) async {
    final db = await database;
    return await db.update(
      'rotational_grazing_plans',
      updates,
      where: 'id = ?',
      whereArgs: [planId]
    );
  }

  Future<int> deleteRotationalPlan(String planId) async {
    final db = await database;
    return await db.delete(
      'rotational_grazing_plans',
      where: 'id = ?',
      whereArgs: [planId]
    );
  }

  // Rotational Plan Paddocks CRUD
  Future<int> insertRotationalPlanPaddock(Map<String, dynamic> paddock) async {
    final db = await database;
    return await db.insert('rotational_plan_paddocks', paddock, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getRotationalPlanPaddocks(String planId) async {
    final db = await database;
    return await db.query(
      'rotational_plan_paddocks',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'sequence_order'
    );
  }

  // Climate Observations CRUD
  Future<int> insertClimateObservation(Map<String, dynamic> obs) async {
    final db = await database;
    return await db.insert('climate_observations', obs, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getClimateObservations(String farmId) async {
    final db = await database;
    return await db.query(
      'climate_observations',
      where: 'farm_id = ?',
      whereArgs: [farmId],
      orderBy: 'observation_date DESC'
    );
  }

  // Drought Forecasts CRUD
  Future<int> insertDroughtForecast(Map<String, dynamic> forecast) async {
    final db = await database;
    return await db.insert('drought_forecasts', forecast, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getDroughtForecasts(String farmId) async {
    final db = await database;
    return await db.query(
      'drought_forecasts',
      where: 'farm_id = ?',
      whereArgs: [farmId],
      orderBy: 'forecast_date DESC'
    );
  }

  // Climate Alerts CRUD
  Future<int> insertClimateAlert(Map<String, dynamic> alert) async {
    final db = await database;
    return await db.insert('climate_alerts', alert, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getClimateAlerts(String farmId) async {
    final db = await database;
    return await db.query(
      'climate_alerts',
      where: 'farm_id = ?',
      whereArgs: [farmId],
      orderBy: 'created_at DESC'
    );
  }

  Future<int> acknowledgeClimateAlert(String alertId, {String? ackTime}) async {
    final db = await database;
    final now = ackTime ?? DateTime.now().toIso8601String();
    
    // Add to sync queue for backend reconciliation
    await addToSyncQueue({
      'action': 'ACKNOWLEDGE_ALERT',
      'payload_json': '{"alert_id": "$alertId", "acknowledged_at": "$now"}',
      'created_at': now,
    });

    return await db.update(
      'climate_alerts',
      {'acknowledged_at': now, 'sync_status': 'pending'},
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  // Plant Observations CRUD
  Future<int> insertPlantObservation(Map<String, dynamic> obs) async {
    final db = await database;
    await db.insert('sync_queue', {
      'action': 'ADD_OBSERVATION',
      'payload_json': obs.toString(),
      'created_at': DateTime.now().toIso8601String(),
    });
    return await db.insert('plant_observations', obs, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPlantObservations() async {
    final db = await database;
    return await db.query('plant_observations', orderBy: 'recorded_at DESC');
  }

  // Plant Species (existing)
  Future<List<Map<String, dynamic>>> searchPlantSpecies(String query) async {
    final db = await database;
    return await db.query(
      'plant_species',
      where: 'scientific_name LIKE ? OR common_names_json LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
  }

  // Sync Queue (existing)
  Future<int> addToSyncQueue(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('sync_queue', item, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query('sync_queue');
  }

  Future<int> markSynced(int id) async {
    final db = await database;
    return await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
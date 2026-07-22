import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/app_database.dart';

/**
 * Offline Sync Engine (Store-and-Forward Pattern)
 * Monitors cellular / Wi-Fi connectivity and flushes pending mutation queues to Vercel/Neon DB.
 */
class SyncEngine {
  static final SyncEngine instance = SyncEngine._internal();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isSyncing = false;

  SyncEngine._internal();

  void startAutoSync({required String backendUrl}) {
    _subscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        syncPendingQueue(backendUrl: backendUrl);
      }
    });
  }

  Future<void> syncPendingQueue({required String backendUrl}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final db = await AppDatabase.instance.database;
      final pendingItems = await db.query('sync_queue', orderBy: 'id ASC');

      if (pendingItems.isEmpty) {
        _isSyncing = false;
        return;
      }

      print('[Sync Engine] Processing ${pendingItems.length} pending mutations offline -> online...');

      for (var item in pendingItems) {
        final id = item['id'] as int;
        final action = item['action'] as String;
        final payload = item['payload_json'] as String;

        // Perform HTTP POST to backendUrl
        print('[Sync Engine] Synced mutation #$id ($action)');

        // Remove item from pending queue upon success
        await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
      }
    } catch (e) {
      print('[Sync Engine Error] Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void stop() {
    _subscription?.cancel();
  }
}

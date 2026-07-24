import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sync_item.dart';

class SyncQueueService extends ChangeNotifier {
  static const String _queueKey = 'offline_sync_queue';
  final SharedPreferences _prefs;
  
  List<SyncItem> _queue = [];

  SyncQueueService(this._prefs) {
    _loadQueue();
  }

  List<SyncItem> get queue => List.unmodifiable(_queue);

  void _loadQueue() {
    final String? data = _prefs.getString(_queueKey);
    if (data != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data);
        _queue = jsonList.map((e) => SyncItem.fromMap(e as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Error loading sync queue: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _saveQueue() async {
    final String data = jsonEncode(_queue.map((e) => e.toMap()).toList());
    await _prefs.setString(_queueKey, data);
    notifyListeners();
  }

  Future<void> enqueue(SyncItem item) async {
    // If there's already an item for this entityId, replace it (if update) or keep create
    final existingIndex = _queue.indexWhere((e) => e.entityId == item.entityId && e.collection == item.collection);
    
    if (existingIndex != -1) {
      final existing = _queue[existingIndex];
      // If we are updating an item that was queued to be created, keep it as 'create'
      if (existing.action == SyncAction.create && item.action == SyncAction.update) {
        _queue[existingIndex] = SyncItem(
          id: existing.id,
          entityId: item.entityId,
          collection: item.collection,
          action: SyncAction.create, // remain create
          payload: item.payload, // new payload
          createdAt: existing.createdAt,
        );
      } else {
        _queue[existingIndex] = item;
      }
    } else {
      _queue.add(item);
    }
    await _saveQueue();
  }

  Future<void> removeItem(String id) async {
    _queue.removeWhere((e) => e.id == id);
    await _saveQueue();
  }

  Future<void> markAsError(String id, String errorMessage) async {
    final index = _queue.indexWhere((e) => e.id == id);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: SyncStatus.error,
        errorMessage: errorMessage,
      );
      await _saveQueue();
    }
  }

  Future<void> resetToPending(String id) async {
    final index = _queue.indexWhere((e) => e.id == id);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: SyncStatus.pending,
        errorMessage: null,
      );
      await _saveQueue();
    }
  }
}

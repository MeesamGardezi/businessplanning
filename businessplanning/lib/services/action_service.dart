import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/action_model.dart';
import 'auth_service.dart';

class ActionPlanService {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);
  
  final FirebaseFirestore _firestore;
  final AuthService _authService;
  final Map<String, List<ActionItem>> _cache = {};
  final StreamController<Map<String, List<ActionItem>>> _cacheController = 
    StreamController<Map<String, List<ActionItem>>>.broadcast();

  ActionPlanService({
    FirebaseFirestore? firestore,
    AuthService? authService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService ?? AuthService();

  void dispose() {
    _cacheController.close();
  }

  CollectionReference _getActionItemsCollection(String userId, String projectId) =>
    _firestore
      .collection('users')
      .doc(userId)
      .collection('projects')
      .doc(projectId)
      .collection('action_items');

  Future<String> _getNextId(String projectId) async {
    String? userId = await _authService.getCurrentUserId();
    if (userId == null) throw const ActionPlanException('User not authenticated');

    final collection = _getActionItemsCollection(userId, projectId);
    final querySnapshot = await collection
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return '1';

    final lastDoc = querySnapshot.docs.first.data() as Map<String, dynamic>;
    final lastId = int.parse(lastDoc['id'].toString());
    return (lastId + 1).toString();
  }

  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    Exception? lastError;
    
    for (int i = 0; i < _maxRetries; i++) {
      try {
        return await operation();
      } on Exception catch (e) {
        lastError = e;
        if (i < _maxRetries - 1) {
          await Future.delayed(_retryDelay * (i + 1));
        }
      }
    }
    
    throw lastError ?? const ActionPlanException('Operation failed after retries');
  }

  Stream<List<ActionItem>> getActionItems(String projectId) async* {
    String? userId = await _authService.getCurrentUserId();
    if (userId == null) {
      yield [];
      return;
    }

    // Check cache first
    if (_cache.containsKey(projectId)) {
      yield _cache[projectId]!;
    }

    yield* _getActionItemsCollection(userId, projectId)
      .orderBy('id')
      .snapshots()
      .map((snapshot) {
        final items = snapshot.docs
          .map((doc) => ActionItem.fromFirestore(doc))
          .toList()
          ..sort();
        
        // Update cache
        _cache[projectId] = items;
        _cacheController.add(_cache);
        
        return items;
      });
  }

  Future<List<ActionItem>> batchCreateItems(
    String projectId, 
    List<ActionItem> items
  ) async {
    String? userId = await _authService.getCurrentUserId();
    if (userId == null) throw const ActionPlanException('User not authenticated');

    final batch = _firestore.batch();
    final collection = _getActionItemsCollection(userId, projectId);
    final createdItems = <ActionItem>[];

    try {
      for (final item in items) {
        final nextId = await _getNextId(projectId);
        final newItem = item.copyWith(
          task: item.task,
          responsible: item.responsible,
          update: item.update,
          updatedAt: DateTime.now(),
        );

        final doc = collection.doc(nextId);
        batch.set(doc, newItem.toFirestore());
        createdItems.add(newItem);
      }

      await batch.commit();
      return createdItems;
    } catch (e) {
      throw ActionPlanException('Failed to batch create items: $e');
    }
  }

  Future<ActionItem> createActionItem(String projectId, ActionItem item) async {
    return _withRetry(() async {
      String? userId = await _authService.getCurrentUserId();
      if (userId == null) throw const ActionPlanException('User not authenticated');

      final collection = _getActionItemsCollection(userId, projectId);
      final nextId = await _getNextId(projectId);
      
      final newItem = ActionItem(
        id: nextId,
        task: item.task,
        responsible: item.responsible,
        update: item.update,
        createdAt: DateTime.now(),
        status: TaskStatus.incomplete,
      );

      await collection.doc(nextId).set(newItem.toFirestore());
      return newItem;
    });
  }

  Future<void> batchUpdateItems(
    String projectId, 
    List<ActionItem> items
  ) async {
    String? userId = await _authService.getCurrentUserId();
    if (userId == null) throw const ActionPlanException('User not authenticated');

    final batch = _firestore.batch();
    final collection = _getActionItemsCollection(userId, projectId);

    try {
      for (final item in items) {
        final doc = collection.doc(item.id);
        batch.update(doc, {
          ...item.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw ActionPlanException('Failed to batch update items: $e');
    }
  }

  Future<void> updateActionItem(String projectId, ActionItem item) async {
    return _withRetry(() async {
      String? userId = await _authService.getCurrentUserId();
      if (userId == null) throw const ActionPlanException('User not authenticated');

      await _getActionItemsCollection(userId, projectId)
        .doc(item.id)
        .update({
          ...item.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
    });
  }

  Future<void> batchDeleteItems(String projectId, List<String> itemIds) async {
    String? userId = await _authService.getCurrentUserId();
    if (userId == null) throw const ActionPlanException('User not authenticated');

    final batch = _firestore.batch();
    final collection = _getActionItemsCollection(userId, projectId);

    try {
      for (final id in itemIds) {
        final doc = collection.doc(id);
        batch.delete(doc);
      }

      await batch.commit();
    } catch (e) {
      throw ActionPlanException('Failed to batch delete items: $e');
    }
  }

  Future<void> deleteActionItem(String projectId, String itemId) async {
    return _withRetry(() async {
      String? userId = await _authService.getCurrentUserId();
      if (userId == null) throw const ActionPlanException('User not authenticated');

      await _getActionItemsCollection(userId, projectId)
        .doc(itemId)
        .delete();
    });
  }

  Future<Map<String, dynamic>> getActionItemStats(String projectId) async {
    String? userId = await _authService.getCurrentUserId();
    if (userId == null) throw const ActionPlanException('User not authenticated');

    try {
      final items = _cache[projectId] ?? 
        (await _getActionItemsCollection(userId, projectId).get())
          .docs
          .map((doc) => ActionItem.fromFirestore(doc))
          .toList();

      final stats = <TaskStatus, int>{
        for (final status in TaskStatus.values)
          status: items.where((item) => item.status == status).length
      };

      final total = items.length;
      return {
        'total': total,
        'statusCounts': stats,
        'completionRate': total > 0 
          ? (stats[TaskStatus.complete]! / total * 100).round() 
          : 0,
      };
    } catch (e) {
      throw ActionPlanException('Failed to get action item stats: $e');
    }
  }
}

class ActionPlanException implements Exception {
  final String message;
  const ActionPlanException(this.message);
  
  @override
  String toString() => 'ActionPlanException: $message';
}
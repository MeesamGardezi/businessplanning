// lib/services/action_service.dart
import 'dart:async';
import '../config/api_config.dart';
import '../models/action_model.dart';
import 'api_client.dart';

class ActionPlanService {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
  final Map<String, List<ActionItem>> _cache = {};
  final StreamController<Map<String, List<ActionItem>>> _cacheController = 
    StreamController<Map<String, List<ActionItem>>>.broadcast();

  ActionPlanService();

  void dispose() {
    _cacheController.close();
  }

  Future<List<ActionItem>> _fetchActionItems(String projectId) async {
    try {
      final response = await _apiClient.get('/projects/$projectId/actions');
      
      if (response['success'] && response['data']['items'] != null) {
        final items = (response['data']['items'] as List)
            .map((itemData) => ActionItem(
                id: itemData['id'],
                task: itemData['task'] ?? '',
                responsible: itemData['responsible'] ?? '',
                completionDate: itemData['completionDate'] != null 
                    ? DateTime.parse(itemData['completionDate']) 
                    : null,
                update: itemData['update'] ?? '',
                createdAt: DateTime.parse(itemData['createdAt']),
                updatedAt: itemData['updatedAt'] != null 
                    ? DateTime.parse(itemData['updatedAt']) 
                    : null,
                status: _parseStatus(itemData['status'])
            ))
            .toList()
            ..sort();
            
        // Update cache
        _cache[projectId] = items;
        _cacheController.add(_cache);
        
        return items;
      }
      
      return [];
    } catch (e) {
      print('Error fetching action items: $e');
      throw e;
    }
  }
  
  TaskStatus _parseStatus(dynamic status) {
    if (status == 'inProgress') return TaskStatus.inProgress;
    if (status == 'complete') return TaskStatus.complete;
    return TaskStatus.incomplete;
  }
  
  String _serializeStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress: return 'inProgress';
      case TaskStatus.complete: return 'complete';
      default: return 'incomplete';
    }
  }

  Stream<List<ActionItem>> getActionItems(String projectId) async* {
    StreamController<List<ActionItem>> controller = StreamController<List<ActionItem>>();
    
    try {
      // Check cache first
      if (_cache.containsKey(projectId)) {
        controller.add(_cache[projectId]!);
      }
      
      // Setup periodic refresh of data
      Timer.periodic(Duration(seconds: 30), (timer) async {
        if (controller.isClosed) {
          timer.cancel();
          return;
        }
        
        try {
          final items = await _fetchActionItems(projectId);
          controller.add(items);
        } catch (e) {
          print('Error refreshing action items: $e');
          // Only add error if controller is still open
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      });
      
      // Initial fetch
      final initialItems = await _fetchActionItems(projectId);
      controller.add(initialItems);
      
      // Handle cleanup when the stream is cancelled
      yield* controller.stream;
    } finally {
      await controller.close();
    }
  }

  Future<List<ActionItem>> batchCreateItems(
    String projectId, 
    List<ActionItem> items
  ) async {
    try {
      final response = await _apiClient.post(
        '/projects/$projectId/actions/batch',
        {
          'items': items.map((item) => {
            'task': item.task,
            'responsible': item.responsible,
            'completionDate': item.completionDate?.toIso8601String(),
            'update': item.update,
            'status': _serializeStatus(item.status)
          }).toList()
        }
      );
      
      if (response['success'] && response['data'] != null) {
        final createdItems = (response['data'] as List)
            .map((itemData) => ActionItem(
                id: itemData['id'],
                task: itemData['task'] ?? '',
                responsible: itemData['responsible'] ?? '',
                completionDate: itemData['completionDate'] != null 
                    ? DateTime.parse(itemData['completionDate']) 
                    : null,
                update: itemData['update'] ?? '',
                createdAt: DateTime.parse(itemData['createdAt']),
                updatedAt: itemData['updatedAt'] != null 
                    ? DateTime.parse(itemData['updatedAt']) 
                    : null,
                status: _parseStatus(itemData['status'])
            ))
            .toList();
            
        return createdItems;
      }
      
      throw Exception('Failed to batch create items');
    } catch (e) {
      print('Error batch creating items: $e');
      throw Exception('Failed to batch create items: $e');
    }
  }

  Future<ActionItem> createActionItem(String projectId, ActionItem item) async {
    try {
      final response = await _apiClient.post(
        '/projects/$projectId/actions',
        {
          'task': item.task,
          'responsible': item.responsible,
          'completionDate': item.completionDate?.toIso8601String(),
          'update': item.update,
          'status': _serializeStatus(item.status)
        }
      );
      
      if (response['success'] && response['data'] != null) {
        final itemData = response['data'];
        
        return ActionItem(
          id: itemData['id'],
          task: itemData['task'] ?? '',
          responsible: itemData['responsible'] ?? '',
          completionDate: itemData['completionDate'] != null 
              ? DateTime.parse(itemData['completionDate']) 
              : null,
          update: itemData['update'] ?? '',
          createdAt: DateTime.parse(itemData['createdAt']),
          updatedAt: itemData['updatedAt'] != null 
              ? DateTime.parse(itemData['updatedAt']) 
              : null,
          status: _parseStatus(itemData['status'])
        );
      }
      
      throw Exception('Failed to create action item');
    } catch (e) {
      print('Error creating action item: $e');
      throw Exception('Failed to create action item: $e');
    }
  }

  Future<void> batchUpdateItems(
    String projectId, 
    List<ActionItem> items
  ) async {
    try {
      final response = await _apiClient.put(
        '/projects/$projectId/actions/batch',
        {
          'items': items.map((item) => {
            'id': item.id,
            'task': item.task,
            'responsible': item.responsible,
            'completionDate': item.completionDate?.toIso8601String(),
            'update': item.update,
            'status': _serializeStatus(item.status)
          }).toList()
        }
      );
      
      if (!response['success']) {
        throw Exception('Failed to batch update items');
      }
    } catch (e) {
      print('Error batch updating items: $e');
      throw Exception('Failed to batch update items: $e');
    }
  }

  Future<void> updateActionItem(String projectId, ActionItem item) async {
    try {
      final response = await _apiClient.put(
        '/projects/$projectId/actions/${item.id}',
        {
          'task': item.task,
          'responsible': item.responsible,
          'completionDate': item.completionDate?.toIso8601String(),
          'update': item.update,
          'status': _serializeStatus(item.status)
        }
      );
      
      if (!response['success']) {
        throw Exception('Failed to update action item');
      }
    } catch (e) {
      print('Error updating action item: $e');
      throw Exception('Failed to update action item: $e');
    }
  }

  Future<void> batchDeleteItems(String projectId, List<String> itemIds) async {
    try {
      final response = await _apiClient.post(
        '/projects/$projectId/actions/batch',
        {'ids': itemIds}
      );
      
      if (!response['success']) {
        throw Exception('Failed to batch delete items');
      }
    } catch (e) {
      print('Error batch deleting items: $e');
      throw Exception('Failed to batch delete items: $e');
    }
  }

  Future<void> deleteActionItem(String projectId, String itemId) async {
    try {
      final response = await _apiClient.delete('/projects/$projectId/actions/$itemId');
      
      if (!response['success']) {
        throw Exception('Failed to delete action item');
      }
    } catch (e) {
      print('Error deleting action item: $e');
      throw Exception('Failed to delete action item: $e');
    }
  }

  Future<Map<String, dynamic>> getActionItemStats(String projectId) async {
    try {
      final response = await _apiClient.get('/projects/$projectId/actions/stats');
      
      if (response['success'] && response['data'] != null) {
        return response['data'];
      }
      
      throw Exception('Failed to get action item stats');
    } catch (e) {
      print('Error getting action item stats: $e');
      throw Exception('Failed to get action item stats: $e');
    }
  }
}
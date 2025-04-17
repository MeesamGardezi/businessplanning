// lib/services/swot_service.dart
import 'dart:async';
import '../config/api_config.dart';
import '../models/swot_models.dart';
import 'api_client.dart';

class SwotService {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);

  // Create a new SWOT item
  Future<SwotItem> createSwotItem(String projectId, SwotItem item) async {
    try {
      final response = await _apiClient.post(
        '/projects/$projectId/swot',
        {
          'text': item.text,
          'type': item.type.toShortString()
        }
      );
      
      if (response['success'] && response['data'] != null) {
        final itemData = response['data'];
        
        return SwotItem(
          id: itemData['id'],
          text: itemData['text'],
          type: SwotType.fromString(itemData['type']),
          createdAt: DateTime.parse(itemData['createdAt']),
          updatedAt: itemData['updatedAt'] != null 
              ? DateTime.parse(itemData['updatedAt']) 
              : null
        );
      }
      
      throw Exception('Failed to create SWOT item');
    } catch (e) {
      print('Error creating SWOT item: $e');
      throw Exception('Failed to create SWOT item: $e');
    }
  }

  // Get all SWOT items for a project as a stream
  Stream<SwotAnalysis> getSwotAnalysis(String projectId) async* {
    StreamController<SwotAnalysis> controller = StreamController<SwotAnalysis>();
    
    try {
      // Setup periodic refresh of data
      Timer.periodic(Duration(seconds: 30), (timer) async {
        if (controller.isClosed) {
          timer.cancel();
          return;
        }
        
        try {
          final items = await _fetchSwotItems(projectId);
          controller.add(SwotAnalysis.fromItems(items));
        } catch (e) {
          print('Error refreshing SWOT items: $e');
          // Only add error if controller is still open
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      });
      
      // Initial fetch
      final initialItems = await _fetchSwotItems(projectId);
      controller.add(SwotAnalysis.fromItems(initialItems));
      
      // Handle cleanup when the stream is cancelled
      yield* controller.stream;
    } finally {
      await controller.close();
    }
  }
  
  Future<List<SwotItem>> _fetchSwotItems(String projectId) async {
    try {
      final response = await _apiClient.get('/projects/$projectId/swot');
      
      if (response['success'] && response['data']['items'] != null) {
        return (response['data']['items'] as List)
            .map((itemData) => SwotItem(
                id: itemData['id'],
                text: itemData['text'] ?? '',
                type: SwotType.fromString(itemData['type']),
                createdAt: DateTime.parse(itemData['createdAt']),
                updatedAt: itemData['updatedAt'] != null 
                    ? DateTime.parse(itemData['updatedAt']) 
                    : null
            ))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching SWOT items: $e');
      throw e;
    }
  }

  // Get SWOT items by type
  Stream<List<SwotItem>> getSwotItemsByType(
      String projectId, SwotType type) async* {
    StreamController<List<SwotItem>> controller = StreamController<List<SwotItem>>();
    
    try {
      // Setup periodic refresh of data
      Timer.periodic(Duration(seconds: 30), (timer) async {
        if (controller.isClosed) {
          timer.cancel();
          return;
        }
        
        try {
          final response = await _apiClient.get(
            '/projects/$projectId/swot?type=${type.toShortString()}'
          );
          
          if (response['success'] && response['data']['items'] != null) {
            final items = (response['data']['items'] as List)
                .map((itemData) => SwotItem(
                    id: itemData['id'],
                    text: itemData['text'] ?? '',
                    type: SwotType.fromString(itemData['type']),
                    createdAt: DateTime.parse(itemData['createdAt']),
                    updatedAt: itemData['updatedAt'] != null 
                        ? DateTime.parse(itemData['updatedAt']) 
                        : null
                ))
                .toList();
                
            controller.add(items);
          } else {
            controller.add([]);
          }
        } catch (e) {
          print('Error refreshing SWOT items by type: $e');
          // Only add error if controller is still open
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      });
      
      // Initial fetch
      final response = await _apiClient.get(
        '/projects/$projectId/swot?type=${type.toShortString()}'
      );
      
      if (response['success'] && response['data']['items'] != null) {
        final items = (response['data']['items'] as List)
            .map((itemData) => SwotItem(
                id: itemData['id'],
                text: itemData['text'] ?? '',
                type: SwotType.fromString(itemData['type']),
                createdAt: DateTime.parse(itemData['createdAt']),
                updatedAt: itemData['updatedAt'] != null 
                    ? DateTime.parse(itemData['updatedAt']) 
                    : null
            ))
            .toList();
            
        controller.add(items);
      } else {
        controller.add([]);
      }
      
      // Handle cleanup when the stream is cancelled
      yield* controller.stream;
    } finally {
      await controller.close();
    }
  }

  // Get a single SWOT item
  Future<SwotItem?> getSwotItem(String projectId, String itemId) async {
    try {
      final response = await _apiClient.get('/projects/$projectId/swot/$itemId');
      
      if (response['success'] && response['data'] != null) {
        final itemData = response['data'];
        
        return SwotItem(
          id: itemData['id'],
          text: itemData['text'] ?? '',
          type: SwotType.fromString(itemData['type']),
          createdAt: DateTime.parse(itemData['createdAt']),
          updatedAt: itemData['updatedAt'] != null 
              ? DateTime.parse(itemData['updatedAt']) 
              : null
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting SWOT item: $e');
      throw Exception('Failed to get SWOT item: $e');
    }
  }

  // Update a SWOT item
  Future<SwotItem> updateSwotItem(
    String projectId,
    String itemId,
    SwotItem item,
  ) async {
    try {
      final response = await _apiClient.put(
        '/projects/$projectId/swot/$itemId',
        {
          'text': item.text,
          'type': item.type.toShortString()
        }
      );
      
      if (response['success']) {
        return item.copyWith(
          updatedAt: DateTime.now()
        );
      }
      
      throw Exception('Failed to update SWOT item');
    } catch (e) {
      print('Error updating SWOT item: $e');
      throw Exception('Failed to update SWOT item: $e');
    }
  }

  // Delete a SWOT item
  Future<void> deleteSwotItem(String projectId, String itemId) async {
    try {
      final response = await _apiClient.delete('/projects/$projectId/swot/$itemId');
      
      if (!response['success']) {
        throw Exception('Failed to delete SWOT item');
      }
    } catch (e) {
      print('Error deleting SWOT item: $e');
      throw Exception('Failed to delete SWOT item: $e');
    }
  }

  // Move a SWOT item to a different type
  Future<SwotItem> moveSwotItem(
    String projectId,
    String itemId,
    SwotType newType,
  ) async {
    try {
      final response = await _apiClient.put(
        '/projects/$projectId/swot/$itemId/move',
        {
          'newType': newType.toShortString()
        }
      );
      
      if (response['success']) {
        final item = await getSwotItem(projectId, itemId);
        return item!;
      }
      
      throw Exception('Failed to move SWOT item');
    } catch (e) {
      print('Error moving SWOT item: $e');
      throw Exception('Failed to move SWOT item: $e');
    }
  }
}
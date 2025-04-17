// lib/services/pest_service.dart
import 'dart:async';
import '../config/api_config.dart';
import '../models/pest_models.dart';
import 'api_client.dart';

class PestService {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);

  // Get the PEST collection reference for a project
  Future<List<PestFactor>> _fetchPestFactors(String projectId) async {
    try {
      final response = await _apiClient.get('/projects/$projectId/pest');
      
      if (response['success'] && response['data']['factors'] != null) {
        return (response['data']['factors'] as List)
            .map((factorData) => PestFactor(
                id: factorData['id'],
                text: factorData['text'] ?? '',
                type: PestFactorType.fromString(factorData['type']),
                impact: factorData['impact'] ?? 3,
                timeframe: factorData['timeframe'],
                createdAt: DateTime.parse(factorData['createdAt']),
                updatedAt: factorData['updatedAt'] != null 
                    ? DateTime.parse(factorData['updatedAt']) 
                    : null
            ))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching PEST factors: $e');
      throw e;
    }
  }

  // Create a new PEST factor
  Future<PestFactor> createPestFactor(String projectId, PestFactor factor) async {
    try {
      final response = await _apiClient.post(
        '/projects/$projectId/pest',
        {
          'text': factor.text,
          'type': factor.type.toShortString(),
          'impact': factor.impact,
          'timeframe': factor.timeframe
        }
      );
      
      if (response['success'] && response['data'] != null) {
        final factorData = response['data'];
        
        return PestFactor(
          id: factorData['id'],
          text: factorData['text'],
          type: PestFactorType.fromString(factorData['type']),
          impact: factorData['impact'],
          timeframe: factorData['timeframe'],
          createdAt: DateTime.now(),
          updatedAt: null
        );
      }
      
      throw Exception('Failed to create PEST factor');
    } catch (e) {
      print('Error creating PEST factor: $e');
      throw Exception('Failed to create PEST factor: $e');
    }
  }

  // Get all PEST factors for a project as a stream
  Stream<PestAnalysis> getPestAnalysis(String projectId) async* {
    StreamController<PestAnalysis> controller = StreamController<PestAnalysis>();
    
    try {
      // Setup periodic refresh of data
      Timer.periodic(Duration(seconds: 30), (timer) async {
        if (controller.isClosed) {
          timer.cancel();
          return;
        }
        
        try {
          final factors = await _fetchPestFactors(projectId);
          controller.add(PestAnalysis.fromFactors(factors));
        } catch (e) {
          print('Error refreshing PEST factors: $e');
          // Only add error if controller is still open
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      });
      
      // Initial fetch
      final initialFactors = await _fetchPestFactors(projectId);
      controller.add(PestAnalysis.fromFactors(initialFactors));
      
      // Handle cleanup when the stream is cancelled
      yield* controller.stream;
    } finally {
      await controller.close();
    }
  }

  // Get factors by type
  Stream<List<PestFactor>> getFactorsByType(
      String projectId, PestFactorType type) async* {
    StreamController<List<PestFactor>> controller = StreamController<List<PestFactor>>();
    
    try {
      // Setup periodic refresh of data
      Timer.periodic(Duration(seconds: 30), (timer) async {
        if (controller.isClosed) {
          timer.cancel();
          return;
        }
        
        try {
          final response = await _apiClient.get(
            '/projects/$projectId/pest?type=${type.toShortString()}'
          );
          
          if (response['success'] && response['data']['factors'] != null) {
            final factors = (response['data']['factors'] as List)
                .map((factorData) => PestFactor(
                    id: factorData['id'],
                    text: factorData['text'] ?? '',
                    type: PestFactorType.fromString(factorData['type']),
                    impact: factorData['impact'] ?? 3,
                    timeframe: factorData['timeframe'],
                    createdAt: DateTime.parse(factorData['createdAt']),
                    updatedAt: factorData['updatedAt'] != null 
                        ? DateTime.parse(factorData['updatedAt']) 
                        : null
                ))
                .toList();
                
            controller.add(factors);
          } else {
            controller.add([]);
          }
        } catch (e) {
          print('Error refreshing PEST factors by type: $e');
          // Only add error if controller is still open
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      });
      
      // Initial fetch
      final response = await _apiClient.get(
        '/projects/$projectId/pest?type=${type.toShortString()}'
      );
      
      if (response['success'] && response['data']['factors'] != null) {
        final factors = (response['data']['factors'] as List)
            .map((factorData) => PestFactor(
                id: factorData['id'],
                text: factorData['text'] ?? '',
                type: PestFactorType.fromString(factorData['type']),
                impact: factorData['impact'] ?? 3,
                timeframe: factorData['timeframe'],
                createdAt: DateTime.parse(factorData['createdAt']),
                updatedAt: factorData['updatedAt'] != null 
                    ? DateTime.parse(factorData['updatedAt']) 
                    : null
            ))
            .toList();
            
        controller.add(factors);
      } else {
        controller.add([]);
      }
      
      // Handle cleanup when the stream is cancelled
      yield* controller.stream;
    } finally {
      await controller.close();
    }
  }

  // Get a single factor
  Future<PestFactor?> getPestFactor(String projectId, String factorId) async {
    try {
      final response = await _apiClient.get('/projects/$projectId/pest/$factorId');
      
      if (response['success'] && response['data'] != null) {
        final factorData = response['data'];
        
        return PestFactor(
          id: factorData['id'],
          text: factorData['text'] ?? '',
          type: PestFactorType.fromString(factorData['type']),
          impact: factorData['impact'] ?? 3,
          timeframe: factorData['timeframe'],
          createdAt: DateTime.parse(factorData['createdAt']),
          updatedAt: factorData['updatedAt'] != null 
              ? DateTime.parse(factorData['updatedAt']) 
              : null
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting PEST factor: $e');
      throw Exception('Failed to get PEST factor: $e');
    }
  }

  // Update a factor
  Future<PestFactor> updatePestFactor(
    String projectId,
    String factorId,
    PestFactor factor,
  ) async {
    try {
      final response = await _apiClient.put(
        '/projects/$projectId/pest/$factorId',
        {
          'text': factor.text,
          'type': factor.type.toShortString(),
          'impact': factor.impact,
          'timeframe': factor.timeframe
        }
      );
      
      if (response['success']) {
        return factor.copyWith(
          updatedAt: DateTime.now()
        );
      }
      
      throw Exception('Failed to update PEST factor');
    } catch (e) {
      print('Error updating PEST factor: $e');
      throw Exception('Failed to update PEST factor: $e');
    }
  }

  // Delete a factor
  Future<void> deletePestFactor(String projectId, String factorId) async {
    try {
      final response = await _apiClient.delete('/projects/$projectId/pest/$factorId');
      
      if (!response['success']) {
        throw Exception('Failed to delete PEST factor');
      }
    } catch (e) {
      print('Error deleting PEST factor: $e');
      throw Exception('Failed to delete PEST factor: $e');
    }
  }

  // Update impact rating
  Future<PestFactor> updateFactorImpact(
    String projectId,
    String factorId,
    int newImpact,
  ) async {
    try {
      final response = await _apiClient.put(
        '/projects/$projectId/pest/$factorId/impact',
        {'impact': newImpact}
      );
      
      if (response['success']) {
        final factor = await getPestFactor(projectId, factorId);
        if (factor == null) throw Exception('Failed to retrieve updated factor');
        return factor;
      }
      
      throw Exception('Failed to update factor impact');
    } catch (e) {
      print('Error updating PEST factor impact: $e');
      throw Exception('Failed to update PEST factor impact: $e');
    }
  }

  // Update timeframe
  Future<PestFactor> updateFactorTimeframe(
    String projectId,
    String factorId,
    String newTimeframe,
  ) async {
    try {
      final response = await _apiClient.put(
        '/projects/$projectId/pest/$factorId/timeframe',
        {'timeframe': newTimeframe}
      );
      
      if (response['success']) {
        final factor = await getPestFactor(projectId, factorId);
        if (factor == null) throw Exception('Failed to retrieve updated factor');
        return factor;
      }
      
      throw Exception('Failed to update factor timeframe');
    } catch (e) {
      print('Error updating PEST factor timeframe: $e');
      throw Exception('Failed to update PEST factor timeframe: $e');
    }
  }
}
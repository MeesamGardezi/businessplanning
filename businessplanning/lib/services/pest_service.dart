import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pest_models.dart';
import 'auth_service.dart';

class PestService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  PestService({
    FirebaseFirestore? firestore,
    AuthService? authService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService ?? AuthService();

  // Get the PEST collection reference for a project
  Future<CollectionReference> _getPestCollection(String projectId) async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('pest_factors');
  }

  // Create a new PEST factor
  Future<PestFactor> createPestFactor(String projectId, PestFactor factor) async {
    try {
      final collection = await _getPestCollection(projectId);

      // Create the document with server timestamp
      final docRef = await collection.add({
        ...factor.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Return the factor with the new ID
      return factor.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating PEST factor: $e');
      throw Exception('Failed to create PEST factor: $e');
    }
  }

  // Get all PEST factors for a project as a stream
  Stream<PestAnalysis> getPestAnalysis(String projectId) async* {
    try {
      final collection = await _getPestCollection(projectId);

      yield* collection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final factors = snapshot.docs
            .map((doc) => PestFactor.fromFirestore(doc))
            .toList();
        return PestAnalysis.fromFactors(factors);
      });
    } catch (e) {
      print('Error getting PEST analysis: $e');
      yield PestAnalysis(); // Return empty analysis on error
    }
  }

  // Get factors by type
  Stream<List<PestFactor>> getFactorsByType(
      String projectId, PestFactorType type) async* {
    try {
      final collection = await _getPestCollection(projectId);

      yield* collection
          .where('type', isEqualTo: type.toShortString())
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => PestFactor.fromFirestore(doc)).toList());
    } catch (e) {
      print('Error getting PEST factors by type: $e');
      yield [];
    }
  }

  // Get a single factor
  Future<PestFactor?> getPestFactor(String projectId, String factorId) async {
    try {
      final collection = await _getPestCollection(projectId);
      final doc = await collection.doc(factorId).get();

      if (!doc.exists) return null;
      return PestFactor.fromFirestore(doc);
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
      final collection = await _getPestCollection(projectId);
      final updateData = factor.toFirestore();

      // Add update timestamp
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await collection.doc(factorId).update(updateData);

      // Fetch and return the updated document
      final updatedDoc = await collection.doc(factorId).get();
      return PestFactor.fromFirestore(updatedDoc);
    } catch (e) {
      print('Error updating PEST factor: $e');
      throw Exception('Failed to update PEST factor: $e');
    }
  }

  // Delete a factor
  Future<void> deletePestFactor(String projectId, String factorId) async {
    try {
      final collection = await _getPestCollection(projectId);
      await collection.doc(factorId).delete();
    } catch (e) {
      print('Error deleting PEST factor: $e');
      throw Exception('Failed to delete PEST factor: $e');
    }
  }

  // Delete all factors for a project
  Future<void> deleteAllPestFactors(String projectId) async {
    try {
      final collection = await _getPestCollection(projectId);
      final batch = _firestore.batch();

      final snapshots = await collection.get();
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all PEST factors: $e');
      throw Exception('Failed to delete all PEST factors: $e');
    }
  }

  // Batch create multiple factors
  Future<List<PestFactor>> batchCreatePestFactors(
    String projectId,
    List<PestFactor> factors,
  ) async {
    try {
      final collection = await _getPestCollection(projectId);
      final batch = _firestore.batch();
      final List<DocumentReference> refs = [];

      // Create references and add to batch
      for (var factor in factors) {
        final ref = collection.doc();
        refs.add(ref);
        batch.set(ref, {
          ...factor.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Fetch all created documents
      final createdDocs = await Future.wait(refs.map((ref) => ref.get()));
      return createdDocs.map((doc) => PestFactor.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error batch creating PEST factors: $e');
      throw Exception('Failed to batch create PEST factors: $e');
    }
  }

  // Update impact rating
  Future<PestFactor> updateFactorImpact(
    String projectId,
    String factorId,
    int newImpact,
  ) async {
    try {
      final factor = await getPestFactor(projectId, factorId);
      if (factor == null) throw Exception('PEST factor not found');

      final updatedFactor = factor.copyWith(
        impact: newImpact,
        updatedAt: DateTime.now(),
      );

      return await updatePestFactor(projectId, factorId, updatedFactor);
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
      final factor = await getPestFactor(projectId, factorId);
      if (factor == null) throw Exception('PEST factor not found');

      final updatedFactor = factor.copyWith(
        timeframe: newTimeframe,
        updatedAt: DateTime.now(),
      );

      return await updatePestFactor(projectId, factorId, updatedFactor);
    } catch (e) {
      print('Error updating PEST factor timeframe: $e');
      throw Exception('Failed to update PEST factor timeframe: $e');
    }
  }

  // Get analysis summary
  Future<Map<String, dynamic>> getAnalysisSummary(String projectId) async {
    try {
      final collection = await _getPestCollection(projectId);
      final snapshot = await collection.get();
      final factors = snapshot.docs.map((doc) => PestFactor.fromFirestore(doc)).toList();
      final analysis = PestAnalysis.fromFactors(factors);

      return {
        'totalFactors': factors.length,
        'factorsByType': {
          for (var type in PestFactorType.values)
            type.toShortString(): analysis.getFactorsByType(type).length
        },
        'averageImpacts': {
          for (var type in PestFactorType.values)
            type.toShortString(): analysis.getAverageImpact(type)
        },
        'timeframeDistribution': _calculateTimeframeDistribution(factors),
      };
    } catch (e) {
      print('Error getting PEST analysis summary: $e');
      throw Exception('Failed to get PEST analysis summary: $e');
    }
  }

  Map<String, int> _calculateTimeframeDistribution(List<PestFactor> factors) {
    final distribution = <String, int>{
      'short-term': 0,
      'medium-term': 0,
      'long-term': 0,
      'unspecified': 0,
    };

    for (var factor in factors) {
      final timeframe = factor.timeframe?.toLowerCase() ?? 'unspecified';
      distribution[timeframe] = (distribution[timeframe] ?? 0) + 1;
    }

    return distribution;
  }
}
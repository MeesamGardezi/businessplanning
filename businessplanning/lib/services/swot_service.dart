import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/swot_models.dart';
import 'auth_service.dart';

class SwotService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  SwotService({
    FirebaseFirestore? firestore,
    AuthService? authService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService ?? AuthService();

  // Helper method to get the swot collection reference
  Future<CollectionReference> _getSwotCollection(String projectId) async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('swot_items');
  }

  // Create a new SWOT item
  Future<SwotItem> createSwotItem(String projectId, SwotItem item) async {
    try {
      final collection = await _getSwotCollection(projectId);

      // Create the document with an initial state
      final docRef = await collection.add({
        ...item.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Return a temporary item while waiting for the server
      return item.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating SWOT item: $e');
      throw Exception('Failed to create SWOT item: $e');
    }
  }

  // Get all SWOT items for a project as a stream
  Stream<SwotAnalysis> getSwotAnalysis(String projectId) async* {
    try {
      final collection = await _getSwotCollection(projectId);

      yield* collection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final items =
            snapshot.docs.map((doc) => SwotItem.fromFirestore(doc)).toList();
        return SwotAnalysis.fromItems(items);
      });
    } catch (e) {
      print('Error getting SWOT analysis: $e');
      yield SwotAnalysis(); // Return empty analysis on error
    }
  }

  // Get SWOT items by type
  Stream<List<SwotItem>> getSwotItemsByType(
      String projectId, SwotType type) async* {
    try {
      final collection = await _getSwotCollection(projectId);

      yield* collection
          .where('type', isEqualTo: type.toShortString())
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => SwotItem.fromFirestore(doc)).toList());
    } catch (e) {
      print('Error getting SWOT items by type: $e');
      yield []; // Return empty list on error
    }
  }

  // Get a single SWOT item
  Future<SwotItem?> getSwotItem(String projectId, String itemId) async {
    try {
      final collection = await _getSwotCollection(projectId);
      final doc = await collection.doc(itemId).get();

      if (!doc.exists) return null;
      return SwotItem.fromFirestore(doc);
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
      final collection = await _getSwotCollection(projectId);
      final updateData = item.toFirestore();

      // Add updatedAt timestamp
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await collection.doc(itemId).update(updateData);

      // Fetch and return the updated document
      final updatedDoc = await collection.doc(itemId).get();
      return SwotItem.fromFirestore(updatedDoc);
    } catch (e) {
      print('Error updating SWOT item: $e');
      throw Exception('Failed to update SWOT item: $e');
    }
  }

  // Delete a SWOT item
  Future<void> deleteSwotItem(String projectId, String itemId) async {
    try {
      final collection = await _getSwotCollection(projectId);
      await collection.doc(itemId).delete();
    } catch (e) {
      print('Error deleting SWOT item: $e');
      throw Exception('Failed to delete SWOT item: $e');
    }
  }

  // Delete all SWOT items for a project
  Future<void> deleteAllSwotItems(String projectId) async {
    try {
      final collection = await _getSwotCollection(projectId);
      final batch = _firestore.batch();

      final snapshots = await collection.get();
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all SWOT items: $e');
      throw Exception('Failed to delete all SWOT items: $e');
    }
  }

  // Batch create multiple SWOT items
  Future<List<SwotItem>> batchCreateSwotItems(
    String projectId,
    List<SwotItem> items,
  ) async {
    try {
      final collection = await _getSwotCollection(projectId);
      final batch = _firestore.batch();
      final List<DocumentReference> refs = [];

      // Create references and add to batch
      for (var item in items) {
        final ref = collection.doc();
        refs.add(ref);
        batch.set(ref, item.toFirestore());
      }

      await batch.commit();

      // Fetch all created documents
      final createdDocs = await Future.wait(refs.map((ref) => ref.get()));

      return createdDocs.map((doc) => SwotItem.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error batch creating SWOT items: $e');
      throw Exception('Failed to batch create SWOT items: $e');
    }
  }

  // Move a SWOT item to a different type
  Future<SwotItem> moveSwotItem(
    String projectId,
    String itemId,
    SwotType newType,
  ) async {
    try {
      final item = await getSwotItem(projectId, itemId);
      if (item == null) throw Exception('SWOT item not found');

      final updatedItem = item.copyWith(
        type: newType,
        updatedAt: DateTime.now(),
      );

      return await updateSwotItem(projectId, itemId, updatedItem);
    } catch (e) {
      print('Error moving SWOT item: $e');
      throw Exception('Failed to move SWOT item: $e');
    }
  }
}

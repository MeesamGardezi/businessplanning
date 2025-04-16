import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import 'auth_service.dart';

class ProjectService {
  final FirebaseFirestore _firestore;
  late final CollectionReference _usersCollection;

  ProjectService() : _firestore = FirebaseFirestore.instance {
    _usersCollection = _firestore.collection('users');
    print('ProjectService initialized with Firestore instance.');
  }

  // Create a new project for the current user
  Future<Project?> createProject(Project project) async {
    try {
      print('Attempting to create a project: ${project.toString()}');
      String? userId = await AuthService().getCurrentUserId();
      print('Current user ID: $userId');

      if (userId == null) {
        print('User ID is null, user might not be logged in.');
        return null;
      }

      CollectionReference projectsCollection = _usersCollection.doc(userId).collection('projects');
      
      DocumentReference docRef = await projectsCollection.add(project.toFirestore());
      print('Project created with ID: ${docRef.id}');
      return project.copyWith(documentId: docRef.id);
    } catch (e) {
      print('Error creating project: $e');
      return null;
    }
  }

  // Get all projects for the current user
  Stream<List<Project>> getProjects() async* {
    String? userId = await AuthService().getCurrentUserId();
    print('Fetching projects for user ID: $userId');

    if (userId == null) {
      print('User ID is null, cannot fetch projects.');
      yield [];
      return;
    }

    CollectionReference projectsCollection = _usersCollection.doc(userId).collection('projects');

    yield* projectsCollection.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      print('Projects snapshot received: ${snapshot.docs.length} documents found.');
      return snapshot.docs.map((doc) {
        print('Project document ID: ${doc.id}');
        return Project.fromFirestore(doc);
      }).toList();
    });
  }

  // Get a stream of a single project by ID
  Stream<Project?> getProjectStream(String projectId) async* {
    String? userId = await AuthService().getCurrentUserId();
    print('Setting up stream for project ID: $projectId, user ID: $userId');

    if (userId == null) {
      print('User ID is null, cannot fetch project stream.');
      yield null;
      return;
    }

    yield* _usersCollection
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        print('Project document does not exist: $projectId');
        return null;
      }
      print('Project document updated: ${doc.data()}');
      return Project.fromFirestore(doc);
    });
  }

  // Get a single project by ID
  Future<Project?> getProjectById(String projectId) async {
    String? userId = await AuthService().getCurrentUserId();
    print('Fetching project with ID: $projectId for user ID: $userId');

    if (userId == null) {
      print('User ID is null, cannot fetch project.');
      return null;
    }

    try {
      DocumentSnapshot doc = await _usersCollection
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .get();
          
      if (doc.exists) {
        print('Project found: ${doc.data()}');
        return Project.fromFirestore(doc);
      } else {
        print('Project not found for ID: $projectId');
        return null;
      }
    } catch (e) {
      print('Error getting project: $e');
      return null;
    }
  }

  // Update an existing project
  Future<bool> updateProject(Project project) async {
    String? userId = await AuthService().getCurrentUserId();
    print('Updating project with ID: ${project.documentId} for user ID: $userId');

    if (userId == null) {
      print('User ID is null, cannot update project.');
      return false;
    }

    try {
      await _usersCollection
          .doc(userId)
          .collection('projects')
          .doc(project.documentId)
          .update(project.toFirestore());
      print('Project updated successfully: ${project.documentId}');
      return true;
    } catch (e) {
      print('Error updating project: $e');
      return false;
    }
  }

  // Delete a project
  Future<bool> deleteProject(String projectId) async {
    String? userId = await AuthService().getCurrentUserId();
    print('Deleting project with ID: $projectId for user ID: $userId');

    if (userId == null) {
      print('User ID is null, cannot delete project.');
      return false;
    }

    try {
      await _usersCollection
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .delete();
      print('Project deleted successfully: $projectId');
      return true;
    } catch (e) {
      print('Error deleting project: $e');
      return false;
    }
  }
}
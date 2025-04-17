// lib/services/project_service.dart
import 'dart:async';
import '../config/api_config.dart';
import '../models/project_model.dart';
import 'api_client.dart';

class ProjectService {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);

  // Create a new project for the current user
  Future<Project?> createProject(Project project) async {
    try {
      print('Attempting to create a project: ${project.toString()}');
      
      final response = await _apiClient.post(
        '/projects',
        {
          'title': project.title,
          'description': project.description
        }
      );
      
      if (response['success']) {
        final projectData = response['data'];
        print('Project created with ID: ${projectData['id']}');
        
        return Project(
          documentId: projectData['id'],
          title: projectData['title'],
          description: projectData['description'],
          createdAt: DateTime.parse(projectData['createdAt'])
        );
      }
      
      return null;
    } catch (e) {
      print('Error creating project: $e');
      return null;
    }
  }

  // Get all projects for the current user
  Stream<List<Project>> getProjects() async* {
    StreamController<List<Project>> controller = StreamController<List<Project>>();
    
    try {
      // Setup periodic refresh of data
      Timer.periodic(Duration(seconds: 30), (timer) async {
        if (controller.isClosed) {
          timer.cancel();
          return;
        }
        
        try {
          final projects = await _fetchProjects();
          controller.add(projects);
        } catch (e) {
          print('Error refreshing projects: $e');
          // Only add error if controller is still open
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      });
      
      // Initial fetch
      final initialProjects = await _fetchProjects();
      controller.add(initialProjects);
      
      // Handle cleanup when the stream is cancelled
      yield* controller.stream;
    } finally {
      await controller.close();
    }
  }
  
  Future<List<Project>> _fetchProjects() async {
    try {
      final response = await _apiClient.get('/projects');
      
      if (response['success'] && response['data']['projects'] != null) {
        return (response['data']['projects'] as List)
            .map((projectData) => Project(
                documentId: projectData['id'],
                title: projectData['title'] ?? '',
                description: projectData['description'] ?? '',
                createdAt: DateTime.parse(projectData['createdAt'])
            ))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching projects: $e');
      throw e;
    }
  }

  // Get a stream of a single project by ID
  Stream<Project?> getProjectStream(String projectId) async* {
    StreamController<Project?> controller = StreamController<Project?>();
    
    try {
      // Setup periodic refresh of data
      Timer.periodic(Duration(seconds: 30), (timer) async {
        if (controller.isClosed) {
          timer.cancel();
          return;
        }
        
        try {
          final project = await getProjectById(projectId);
          controller.add(project);
        } catch (e) {
          print('Error refreshing project: $e');
          // Only add error if controller is still open
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      });
      
      // Initial fetch
      final initialProject = await getProjectById(projectId);
      controller.add(initialProject);
      
      // Handle cleanup when the stream is cancelled
      yield* controller.stream;
    } finally {
      await controller.close();
    }
  }

  // Get a single project by ID
  Future<Project?> getProjectById(String projectId) async {
    try {
      final response = await _apiClient.get('/projects/$projectId');
      
      if (response['success'] && response['data'] != null) {
        final projectData = response['data'];
        
        return Project(
          documentId: projectData['id'],
          title: projectData['title'] ?? '',
          description: projectData['description'] ?? '',
          createdAt: DateTime.parse(projectData['createdAt'])
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting project: $e');
      return null;
    }
  }

  // Update an existing project
  Future<bool> updateProject(Project project) async {
    try {
      final response = await _apiClient.put(
        '/projects/${project.documentId}',
        {
          'title': project.title,
          'description': project.description
        }
      );
      
      return response['success'] ?? false;
    } catch (e) {
      print('Error updating project: $e');
      return false;
    }
  }

  // Delete a project
  Future<bool> deleteProject(String projectId) async {
    try {
      final response = await _apiClient.delete('/projects/$projectId');
      return response['success'] ?? false;
    } catch (e) {
      print('Error deleting project: $e');
      return false;
    }
  }
}
// lib/state/app_state.dart
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../models/swot_models.dart';
import '../models/pest_models.dart';
import '../models/action_model.dart';
import '../services/auth_service.dart';
import '../theme.dart';

/// Centralized state management for the entire application using ValueNotifier pattern.
/// This class holds all the application state and provides methods to update it.
class AppState {
  // Singleton instance
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal() {
    // Initialize auth state
    _initAuthState();
  }

  // Services
  final AuthService _authService = AuthService();

  // ===== AUTHENTICATION STATE =====
  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isAuthLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> authError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> currentUserId = ValueNotifier<String?>(null);
  final ValueNotifier<String?> userEmail = ValueNotifier<String?>(null);
  final ValueNotifier<String?> userStatus = ValueNotifier<String?>(null);

  // ===== THEME STATE =====
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);
  
  // ===== PROJECT STATE =====
  final ValueNotifier<List<Project>> projects = ValueNotifier<List<Project>>([]);
  final ValueNotifier<bool> isProjectsLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> projectError = ValueNotifier<String?>(null);
  final ValueNotifier<Project?> selectedProject = ValueNotifier<Project?>(null);
  final ValueNotifier<String> currentTab = ValueNotifier<String>('Info');
  
  // ===== SWOT ANALYSIS STATE =====
  final ValueNotifier<SwotAnalysis> swotAnalysis = ValueNotifier<SwotAnalysis>(SwotAnalysis());
  final ValueNotifier<bool> isSwotLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> swotError = ValueNotifier<String?>(null);
  
  // ===== PEST ANALYSIS STATE =====
  final ValueNotifier<PestAnalysis> pestAnalysis = ValueNotifier<PestAnalysis>(PestAnalysis());
  final ValueNotifier<bool> isPestLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> pestError = ValueNotifier<String?>(null);
  
  // ===== ACTION ITEMS STATE =====
  final ValueNotifier<List<ActionItem>> actionItems = ValueNotifier<List<ActionItem>>([]);
  final ValueNotifier<bool> isActionItemsLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> actionItemsError = ValueNotifier<String?>(null);
  
  // ===== UI STATE =====
  final ValueNotifier<bool> isProjectListExpanded = ValueNotifier<bool>(true);
  final ValueNotifier<String> searchQuery = ValueNotifier<String>('');
  final ValueNotifier<TaskStatus?> statusFilter = ValueNotifier<TaskStatus?>(null);

  // ===== AUTH METHODS =====
  
  /// Initialize the authentication state from stored tokens
  Future<void> _initAuthState() async {
    isAuthLoading.value = true;
    try {
      isLoggedIn.value = await _authService.isLoggedIn();
      if (isLoggedIn.value) {
        userStatus.value = await _authService.getUserStatus();
        currentUserId.value = await _authService.getCurrentUserId();
        
        // Try to get user information if logged in
        final user = await _authService.getCurrentUser();
        if (user != null && user['email'] != null) {
          userEmail.value = user['email'];
        }
      }
    } catch (e) {
      authError.value = e.toString();
    } finally {
      isAuthLoading.value = false;
    }
  }
  
  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    isAuthLoading.value = true;
    authError.value = null;
    
    try {
      final result = await _authService.signInWithEmailAndPassword(email, password);
      isLoggedIn.value = result['success'] ?? false;
      
      if (isLoggedIn.value) {
        userEmail.value = email;
        await _initAuthState(); // Refresh auth state to get user data
        return true;
      } else {
        authError.value = result['message'] ?? 'Failed to sign in';
        return false;
      }
    } catch (e) {
      authError.value = e.toString();
      return false;
    } finally {
      isAuthLoading.value = false;
    }
  }
  
  /// Register with email and password
  Future<Map<String, dynamic>> register(String email, String password) async {
    isAuthLoading.value = true;
    authError.value = null;
    
    try {
      final result = await _authService.registerWithEmailAndPassword(email, password);
      isLoggedIn.value = result['success'] ?? false;
      
      if (isLoggedIn.value) {
        userEmail.value = email;
        currentUserId.value = result['userId'];
        await _initAuthState(); // Refresh auth state to get user data
      } else {
        authError.value = result['message'] ?? 'Failed to register';
      }
      
      return result;
    } catch (e) {
      authError.value = e.toString();
      return {
        'success': false,
        'message': e.toString()
      };
    } finally {
      isAuthLoading.value = false;
    }
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    isAuthLoading.value = true;
    
    try {
      await _authService.signOut();
      isLoggedIn.value = false;
      userEmail.value = null;
      currentUserId.value = null;
      userStatus.value = null;
      
      // Clear other state that depends on authentication
      projects.value = [];
      selectedProject.value = null;
      swotAnalysis.value = SwotAnalysis();
      pestAnalysis.value = PestAnalysis();
      actionItems.value = [];
    } catch (e) {
      authError.value = e.toString();
    } finally {
      isAuthLoading.value = false;
    }
  }
  
  /// Check if email exists
  Future<bool> checkEmailExists(String email) async {
    isAuthLoading.value = true;
    
    try {
      return await _authService.checkEmailExists(email);
    } catch (e) {
      authError.value = e.toString();
      return false;
    } finally {
      isAuthLoading.value = false;
    }
  }
  
  /// Set up password for employee account
  Future<bool> setEmployeePassword(String email, String password) async {
    isAuthLoading.value = true;
    
    try {
      return await _authService.setEmployeePassword(email, password);
    } catch (e) {
      authError.value = e.toString();
      return false;
    } finally {
      isAuthLoading.value = false;
    }
  }
  
  // ===== THEME METHODS =====
  
  /// Update theme mode
  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    updateDarkModeSetting();
  }
  
  /// Toggle between light and dark mode
  void toggleThemeMode() {
    if (themeMode.value == ThemeMode.light) {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }
    updateDarkModeSetting();
  }
  
  /// Update dark mode value based on theme mode and system setting
  void updateDarkModeSetting() {
    final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    
    switch (themeMode.value) {
      case ThemeMode.system:
        isDarkMode.value = isPlatformDark;
        break;
      case ThemeMode.light:
        isDarkMode.value = false;
        break;
      case ThemeMode.dark:
        isDarkMode.value = true;
        break;
    }
  }
  
  // ===== PROJECT METHODS =====
  
  /// Set selected project by ID
  void setSelectedProject(String? projectId) {
    if (projectId == null) {
      selectedProject.value = null;
      return;
    }
    
    final matchingProject = projects.value.firstWhere(
      (project) => project.documentId == projectId,
      orElse: () => selectedProject.value ?? Project(
        documentId: '',
        title: '',
        description: '',
        createdAt: DateTime.now(),
      ),
    );
    
    selectedProject.value = matchingProject.documentId.isNotEmpty ? matchingProject : null;
  }
  
  /// Update current tab
  void setCurrentTab(String tab) {
    currentTab.value = tab;
  }
  
  /// Toggle project list expansion
  void toggleProjectListExpanded() {
    isProjectListExpanded.value = !isProjectListExpanded.value;
  }
  
  /// Set search query for filtering
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }
  
  /// Set status filter for action items
  void setStatusFilter(TaskStatus? status) {
    statusFilter.value = status;
  }
  
  // ===== DISPOSE =====
  
  /// Clean up all ValueNotifiers when the app is closed
  void dispose() {
    // Auth state
    isLoggedIn.dispose();
    isAuthLoading.dispose();
    authError.dispose();
    currentUserId.dispose();
    userEmail.dispose();
    userStatus.dispose();
    
    // Theme state
    themeMode.dispose();
    isDarkMode.dispose();
    
    // Project state
    projects.dispose();
    isProjectsLoading.dispose();
    projectError.dispose();
    selectedProject.dispose();
    currentTab.dispose();
    
    // SWOT state
    swotAnalysis.dispose();
    isSwotLoading.dispose();
    swotError.dispose();
    
    // PEST state
    pestAnalysis.dispose();
    isPestLoading.dispose();
    pestError.dispose();
    
    // Action items state
    actionItems.dispose();
    isActionItemsLoading.dispose();
    actionItemsError.dispose();
    
    // UI state
    isProjectListExpanded.dispose();
    searchQuery.dispose();
    statusFilter.dispose();
  }
}
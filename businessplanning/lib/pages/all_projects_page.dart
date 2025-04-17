import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';

import '../models/project_model.dart';
import '../services/project_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/new_job_dialog.dart';
import '../widgets/url_updater/url_updater.dart';
import 'project_details_page.dart';

class AllProjectsPage extends StatefulWidget {
  final String? selectedProjectId;
  final String tab;

  const AllProjectsPage({
    Key? key,
    this.selectedProjectId,
    this.tab = 'Info',
  }) : super(key: key);

  @override
  State<AllProjectsPage> createState() => _AllProjectsPageState();
}

class _AllProjectsPageState extends State<AllProjectsPage> {
  // Services
  final ProjectService _projectService = ProjectService();
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // App state access
  final AppState _appState = AppState();
  
  // Local state
  bool _initialized = false;
  bool _isRefreshing = false;
  Stream<List<Project>>? _projectsStream;

  @override
  void initState() {
    super.initState();
    
    // Initialize state using AppState
    _appState.selectedProject.value = _appState.projects.value.firstWhere(
      (project) => project.documentId == widget.selectedProjectId,
      orElse: () => Project(
        documentId: '',
        title: '',
        description: '',
        createdAt: DateTime.now(),
      ),
    );
    
    if (widget.selectedProjectId != null) {
      _appState.setSelectedProject(widget.selectedProjectId);
    }
    
    _appState.setCurrentTab(widget.tab);
    
    // Setup the projects stream
    _setupProjectsStream();
    
    // Listen for URL changes
    listenToUrlChanges((url) {
      if (!mounted) return;
      final uri = Uri.parse(url);
      if (uri.queryParameters['params'] != null) {
        final params = json.decode(uri.queryParameters['params']!) as Map<String, dynamic>;
        
        // Update app state
        if (params['projectId'] != null) {
          _appState.setSelectedProject(params['projectId']);
        }
        
        if (params['tab'] != null) {
          _appState.setCurrentTab(params['tab']);
        }
      }
    });
  }

  void _setupProjectsStream() {
    if (_projectsStream == null) {
      _projectsStream = _projectService.getProjects();
    }
  }

  Future<void> _refreshProjects() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _searchController.clear();
      _appState.searchQuery.value = '';
    });

    try {
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: AppTheme.durationFast,
          curve: Curves.easeOut,
        );
      }

      setState(() {
        _projectsStream = _projectService.getProjects();
      });

      _showSnackBar('Projects refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing projects: $e');
      _showSnackBar('Error refreshing projects: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeFromUrl();
      _initialized = true;
    }
  }

  void _initializeFromUrl() {
    try {
      final uri = Uri.parse(GoRouterState.of(context).uri.toString());
      if (uri.queryParameters['params'] != null) {
        final params = json.decode(uri.queryParameters['params']!) as Map<String, dynamic>;
        
        // Update app state
        if (params['projectId'] != null) {
          _appState.setSelectedProject(params['projectId']);
        }
        
        if (params['tab'] != null) {
          _appState.setCurrentTab(params['tab']);
        }
      }
    } catch (e) {
      _appState.projectError.value = "Failed to load projects data. Please try again.";
    }
  }

  @override
  void didUpdateWidget(AllProjectsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedProjectId != _appState.selectedProject.value?.documentId ||
        widget.tab != _appState.currentTab.value) {
          
      if (widget.selectedProjectId != null) {
        _appState.setSelectedProject(widget.selectedProjectId);
      }
      
      _appState.setCurrentTab(widget.tab);
    }
  }

  List<Project> _filterProjects(List<Project> projects) {
    final searchTerm = _appState.searchQuery.value.toLowerCase();
    if (searchTerm.isEmpty) return projects;

    return projects.where((project) {
      return project.title.toLowerCase().contains(searchTerm) ||
          project.description.toLowerCase().contains(searchTerm);
    }).toList();
  }

  void _updateSelectedProject(String projectId) {
    if (projectId == _appState.selectedProject.value?.documentId) return;

    _appState.setSelectedProject(projectId);
    _appState.setCurrentTab('Info');
    
    if (!_appState.isProjectListExpanded.value) {
      _appState.isProjectListExpanded.value = true;
    }

    final params = {
      'projectId': projectId,
      'tab': 'Info',
    };

    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    final newUri = uri.replace(queryParameters: {'params': json.encode(params)});
    updateBrowserUrl(newUri.toString());
  }

  Widget _buildCollapsedPanel() {
    final theme = Theme.of(context);
    
    return Container(
      height: double.infinity,
      width: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppTheme.radiusXL)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spaceMD),
            child: _buildHeaderButton(
              icon: Icons.chevron_right,
              onPressed: () => _appState.toggleProjectListExpanded(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceSM),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLG, 
        vertical: AppTheme.spaceMD
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      child: Row(
        children: [
          _buildHeaderButton(
            icon: Icons.chevron_left,
            onPressed: () => _appState.toggleProjectListExpanded(),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          const Text(
            'Projects',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          _buildHeaderButton(
            icon: Icons.refresh,
            onPressed: _refreshProjects,
          ),
          const SizedBox(width: AppTheme.spaceSM),
          _buildHeaderButton(
            icon: Icons.add,
            onPressed: _showNewProjectDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search projects...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.search, color: Colors.teal.shade300),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, 
              vertical: 16
            ),
          ),
          onChanged: (value) => _appState.setSearchQuery(value),
        ),
      ),
    );
  }

  Widget _buildProjectItem(Project project) {
    final isSelected = _appState.selectedProject.value?.documentId == project.documentId;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: AppTheme.durationMedium,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD, 
        vertical: AppTheme.spaceSM
      ),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.teal.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          onTap: () => _updateSelectedProject(project.documentId),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.teal.shade700 : theme.textPrimaryColor,
                        ),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.teal : Colors.transparent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  project.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondaryColor,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppTheme.radiusXL)),
        boxShadow: theme.isDarkMode ? AppTheme.shadowMediumDark : AppTheme.shadowMedium,
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(child: _buildProjectListView()),
        ],
      ),
    );
  }

  Widget _buildProjectListView() {
    if (_projectsStream == null) {
      return _buildLoadingState();
    }

    return StreamBuilder<List<Project>>(
      stream: _projectsStream,
      builder: (context, snapshot) {
        if (_isRefreshing || !snapshot.hasData) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final filteredProjects = _filterProjects(snapshot.data!);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
          itemCount: filteredProjects.length,
          itemBuilder: (context, index) => _buildProjectItem(filteredProjects[index]),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade300),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'Loading projects...',
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: theme.errorColor, size: 64),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            error,
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceLG),
          ElevatedButton.icon(
            onPressed: _refreshProjects,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceLG, 
                vertical: AppTheme.spaceMD
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 80,
            color: theme.hintColor,
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'No Projects Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Create your first project to get started',
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          ElevatedButton.icon(
            onPressed: _showNewProjectDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceLG, 
                vertical: AppTheme.spaceMD
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProjectSelectedState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 80,
            color: theme.hintColor,
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'Select a Project',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'Choose a project from the list to view its details',
            style: TextStyle(
              fontSize: 16,
              color: theme.textSecondaryColor,
            ),
          ),
          if (!_appState.isProjectListExpanded.value) ...[
            const SizedBox(height: AppTheme.spaceLG),
            TextButton.icon(
              onPressed: () => _appState.isProjectListExpanded.value = true,
              icon: const Icon(Icons.visibility),
              label: const Text('Show Project List'),
              style: TextButton.styleFrom(
                foregroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLG, 
                  vertical: AppTheme.spaceMD
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD)
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showNewProjectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              child: NewProjectDialog(),
            ),
          ),
        );
      },
    ).then((_) {
      _refreshProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ValueListenableBuilder<bool>(
        valueListenable: _appState.isProjectListExpanded,
        builder: (context, isListExpanded, _) {
          return Row(
            children: [
              // Project list panel (expanded or collapsed)
              AnimatedContainer(
                duration: AppTheme.durationMedium,
                curve: Curves.easeInOut,
                width: isListExpanded 
                    ? MediaQuery.of(context).size.width * 0.3 
                    : AppTheme.sidebarWidthCollapsed,
                child: isListExpanded
                    ? _buildExpandedPanel()
                    : _buildCollapsedPanel(),
              ),
              
              // Project details area
              Expanded(
                child: ValueListenableBuilder<Project?>(
                  valueListenable: _appState.selectedProject,
                  builder: (context, selectedProject, _) {
                    return ValueListenableBuilder<String>(
                      valueListenable: _appState.currentTab,
                      builder: (context, currentTab, _) {
                        return selectedProject != null && selectedProject.documentId.isNotEmpty
                            ? ProjectDetailsPage(
                                key: ValueKey(selectedProject.documentId),
                                projectId: selectedProject.documentId,
                                tab: currentTab,
                              )
                            : _buildNoProjectSelectedState();
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
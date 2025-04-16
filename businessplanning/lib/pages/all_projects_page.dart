import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import '../widgets/new_job_dialog.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
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
  final ProjectService _projectService = ProjectService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedProjectId;
  String _currentTab = 'Info';
  bool _isLoading = true;
  String? _errorMessage;
  bool _initialized = false;
  bool _isListExpanded = true;
  bool _isRefreshing = false;
  Stream<List<Project>>? _projectsStream;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.selectedProjectId;
    _currentTab = widget.tab;
    _setupProjectsStream();

    listenToUrlChanges((url) {
      if (!mounted) return;
      final uri = Uri.parse(url);
      if (uri.queryParameters['params'] != null) {
        final params =
            json.decode(uri.queryParameters['params']!) as Map<String, dynamic>;
        setState(() {
          _selectedProjectId = params['projectId'];
          _currentTab = params['tab'] ?? 'Info';
        });
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
    });

    try {
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
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
        final params =
            json.decode(uri.queryParameters['params']!) as Map<String, dynamic>;
        setState(() {
          _selectedProjectId = params['projectId'];
          _currentTab = params['tab'] ?? 'Info';
        });
      }
    } catch (e) {
      _errorMessage = "Failed to load projects data. Please try again.";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(AllProjectsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedProjectId != _selectedProjectId ||
        widget.tab != _currentTab) {
      setState(() {
        _selectedProjectId = widget.selectedProjectId;
        _currentTab = widget.tab;
      });
    }
  }

  List<Project> _filterProjects(List<Project> projects) {
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isEmpty) return projects;

    return projects.where((project) {
      return project.title.toLowerCase().contains(searchTerm) ||
          project.description.toLowerCase().contains(searchTerm);
    }).toList();
  }

  void _updateSelectedProject(String projectId) {
    if (projectId == _selectedProjectId) return;

    setState(() {
      _selectedProjectId = projectId;
      _currentTab = 'Info';
      if (!_isListExpanded) {
        _isListExpanded = true;
      }
    });

    final params = {
      'projectId': projectId,
      'tab': 'Info',
    };

    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    final newUri =
        uri.replace(queryParameters: {'params': json.encode(params)});
    updateBrowserUrl(newUri.toString());
  }

  void _toggleListPanel() {
    setState(() {
      _isListExpanded = !_isListExpanded;
    });
  }

  Widget _buildCollapsedPanel() {
    return Container(
      height: double.infinity,
      width: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
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
            padding: const EdgeInsets.only(top: 16),
            child: _buildHeaderButton(
              icon: Icons.chevron_right,
              onPressed: _toggleListPanel,
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          _buildHeaderButton(
            icon: Icons.chevron_left,
            onPressed: _toggleListPanel,
          ),
          const SizedBox(width: 16),
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
          const SizedBox(width: 8),
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
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search projects...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.search, color: Colors.teal.shade300),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          onChanged: (value) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildProjectItem(Project project) {
    final isSelected = _selectedProjectId == project.documentId;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: () => _updateSelectedProject(project.documentId),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.teal.shade700
                              : Colors.black87,
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
                const SizedBox(height: 8),
                Text(
                  project.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
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
          // Changed this line
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.data!.isEmpty) {
          // Separated empty check from hasData
          return _buildEmptyState();
        }

        final filteredProjects = _filterProjects(snapshot.data!);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: filteredProjects.length,
          itemBuilder: (context, index) =>
              _buildProjectItem(filteredProjects[index]),
        );
      },
    );
  }

  Widget _buildLoadingState() {
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
          const SizedBox(height: 16),
          Text(
            'Loading projects...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshProjects,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Projects Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first project to get started',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showNewProjectDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProjectSelectedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Project',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose a project from the list to view its details',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          if (!_isListExpanded) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() => _isListExpanded = true),
              icon: const Icon(Icons.visibility),
              label: const Text('Show Project List'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width:
                _isListExpanded ? MediaQuery.of(context).size.width * 0.3 : 72,
            child: _isListExpanded
                ? _buildExpandedPanel()
                : _buildCollapsedPanel(),
          ),
          Expanded(
            child: _selectedProjectId != null
                ? ProjectDetailsPage(
                    key: ValueKey(_selectedProjectId), // Add this line
                    projectId: _selectedProjectId!,
                    tab: _currentTab,
                  )
                : _buildNoProjectSelectedState(),
          ),
        ],
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

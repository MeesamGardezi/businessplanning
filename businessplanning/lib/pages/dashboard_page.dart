import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

import '../models/project_model.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'all_projects_page.dart';

class DashboardPage extends StatefulWidget {
  final String pageContent;
  final Map<String, dynamic> params;

  const DashboardPage({
    Key? key,
    required this.pageContent,
    this.params = const {},
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Access global state
  final AppState _appState = AppState();
  final AuthService _auth = AuthService();
  
  // Design Constants
  static const double _sidebarWidth = 64.0;
  static const double _spacing = 16.0;
  static const Duration _animationDuration = Duration.zero;

  static const List<({String label, IconData icon, String route})> _navItems = [
    (label: 'Home', icon: Icons.home_outlined, route: 'home'),
    (label: 'Projects', icon: Icons.folder_outlined, route: 'projects'),
  ];

  @override
  void initState() {
    super.initState();
    _updateContent();
  }

  @override
  void didUpdateWidget(DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageContent != widget.pageContent ||
        oldWidget.params != widget.params) {
      _updateContent();
    }
  }

  void _updateContent() {
    // Update the current page content in app state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.params.containsKey('projectId')) {
        _appState.setSelectedProject(widget.params['projectId']);
      }
      
      if (widget.params.containsKey('tab')) {
        _appState.setCurrentTab(widget.params['tab']);
      }
    });
  }

  void _navigateWithParams(String path, Map<String, dynamic> params) {
    // Convert params to a JSON string and encode for URL
    final encodedParams = Uri.encodeComponent(json.encode(params));
    context.go('$path?params=$encodedParams');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Content to display based on current selection
    Widget currentContent = _buildCurrentContent();
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Row(
        children: [
          _buildSimplifiedSidebar(context),
          Expanded(
            child: AnimatedSwitcher(
              duration: _animationDuration,
              child: currentContent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentContent() {
    switch (widget.pageContent) {
      case 'home':
        return Container(); // Placeholder for home content
      case 'projects':
        return ValueListenableBuilder<Project?>(
          valueListenable: _appState.selectedProject,
          builder: (context, selectedProject, _) {
            return ValueListenableBuilder<String>(
              valueListenable: _appState.currentTab,
              builder: (context, currentTab, _) {
                return AllProjectsPage(
                  selectedProjectId: selectedProject?.documentId,
                  tab: currentTab,
                );
              },
            );
          },
        );
      default:
        return Container(); // Default fallback
    }
  }

  Widget _buildSimplifiedSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surfaceVariant;
    final textColor = theme.colorScheme.onSurfaceVariant;
    
    return Container(
      width: _sidebarWidth,
      color: backgroundColor,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildMinimalLogo(context),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _navItems.map((item) => _buildMinimalNavButton(
                context,
                item.icon,
                item.label,
                () => _navigateWithParams('/dashboard/${item.route}', {}),
                item.label.toLowerCase().replaceAll(RegExp(r'\s+'), '') == widget.pageContent.toLowerCase(),
              )).toList(),
            ),
          ),
          IconButton(
            onPressed: () => _showLogoutMenu(context),
            icon: Icon(
              Icons.settings_outlined,
              size: 20,
              color: textColor,
            ),
            tooltip: 'Settings',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMinimalLogo(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'M',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalNavButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
    bool isSelected,
  ) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    
    return Tooltip(
      message: label,
      preferBelow: false,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: isSelected 
                ? Border(
                    left: BorderSide(
                      color: primaryColor,
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? primaryColor : textColor,
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutMenu(BuildContext context) {
    final theme = Theme.of(context);
    final popupColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        _sidebarWidth, 
        MediaQuery.of(context).size.height - 100, 
        0, 
        0
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      elevation: 4,
      items: [
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: textColor,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          onTap: () {
            // Add a small delay to avoid rebuild issues during menu closing
            Future.delayed(const Duration(milliseconds: 100), () async {
              await _appState.signOut();
              if (mounted && context.mounted) {
                context.go('/login');
              }
            });
          },
          child: Row(
            children: [
              Icon(
                Icons.logout_outlined,
                color: textColor,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
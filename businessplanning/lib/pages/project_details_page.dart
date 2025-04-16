import 'dart:convert';
import 'package:businessplanning/pages/action_page.dart';
import 'package:businessplanning/pages/pest_page.dart';
import 'package:businessplanning/pages/swot_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import '../widgets/url_updater/url_updater.dart';

class IncomeSourcesTab extends StatelessWidget {
  final Project project;
  const IncomeSourcesTab({Key? key, required this.project}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container();
}

class MarketingTab extends StatelessWidget {
  final Project project;
  const MarketingTab({Key? key, required this.project}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container();
}

class ProjectDetailsPage extends StatefulWidget {
  final String projectId;
  final String tab;

  const ProjectDetailsPage({
    Key? key,
    required this.projectId,
    required this.tab,
  }) : super(key: key);

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage>
    with SingleTickerProviderStateMixin {
  final ProjectService _projectService = ProjectService();
  Project? _currentProject;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Design Constants
  static const double _borderRadius = 24.0;
  static const double _shadowOpacity = 0.08;
  static const double _spacing = 24.0;
  static const Duration _animationDuration = Duration(milliseconds: 400);

  static const List<({String label, IconData icon})> _tabs = [
    (label: 'Info', icon: Icons.info_outline),
    (label: 'SWOT', icon: Icons.grid_4x4_outlined),
    (label: 'PEST', icon: Icons.analytics_outlined),
    (label: 'Action Plan', icon: Icons.work),
    (label: 'Marketing', icon: Icons.campaign_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _initializeState();
    _setupUrlListener();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeState() {
    _initializeTabIndex();
    _setupProjectStream();
  }

  void _setupUrlListener() {
    listenToUrlChanges((url) {
      if (!mounted) return;

      final uri = Uri.parse(url);
      if (uri.queryParameters['params'] == null) return;

      final params =
          json.decode(uri.queryParameters['params']!) as Map<String, dynamic>;

      if (params['projectId'] != widget.projectId || params['tab'] == null)
        return;

      final tabIndex = _tabs.indexWhere((tab) => tab.label == params['tab']);
      if (tabIndex != -1) {
        setState(() => _currentIndex = tabIndex);
      }
    });
  }

  void _initializeTabIndex() {
    final tabIndex = _tabs.indexWhere((tab) => tab.label == widget.tab);
    if (tabIndex != -1) {
      _currentIndex = tabIndex;
    }
  }

  void _setupProjectStream() {
    _projectService.getProjectStream(widget.projectId).listen(
      (project) {
        if (mounted) {
          setState(() {
            _currentProject = project;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
        }
      },
    );
  }

  void _updateTab(int index) {
    setState(() => _currentIndex = index);
    _updateUrl(index);
  }

  void _updateUrl(int index) {
    final params = {'projectId': widget.projectId, 'tab': _tabs[index].label};

    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    final newUri =
        uri.replace(queryParameters: {'params': json.encode(params)});
    updateBrowserUrl(newUri.toString());
  }

  void _retryLoading() {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    _setupProjectStream();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_currentProject == null) {
      return _buildNotFoundState();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          _buildBackground(),
          Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(child: _buildContent()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade300),
              ),
            ),
            const SizedBox(height: _spacing),
            Text(
              'Loading project details...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.all(_spacing),
            padding: const EdgeInsets.all(_spacing),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_shadowOpacity),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(_borderRadius),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red[400],
                    size: 48,
                  ),
                ),
                const SizedBox(height: _spacing),
                Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: _spacing),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _retryLoading,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_borderRadius / 2),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: _spacing),
            Text(
              'Project not found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: BackgroundPainter(),
      ),
    );
  }

  Widget _buildHeader() {
    final project = _currentProject!;

    return Container(
      padding: const EdgeInsets.fromLTRB(_spacing, 30, _spacing, _spacing),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    color: Colors.teal.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Created ${_formatDate(project.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 20),
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(_borderRadius),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.black.withOpacity(_shadowOpacity),
            //         blurRadius: 15,
            //         offset: const Offset(0, 4),
            //       ),
            //     ],
            //   ),
            //   child: Text(
            //     project.description,
            //     style: TextStyle(
            //       color: Colors.grey[800],
            //       fontSize: 16,
            //       height: 1.5,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: _spacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_shadowOpacity),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          return Expanded(
            child: _buildTabItem(index),
          );
        }),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final tab = _tabs[index];
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _updateTab(index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab.icon,
              size: 20,
              color: isSelected ? Colors.teal.shade700 : Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                color: isSelected ? Colors.teal.shade700 : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected)
              Container(
                width: 16,
                height: 3,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(_spacing),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildInfoTab(),
            SwotAnalysisPage(projectId: _currentProject!.documentId),
            PestAnalysisPage(projectId: _currentProject!.documentId),
            ActionPlanPage(projectId: _currentProject!.documentId),
            MarketingTab(project: _currentProject!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_shadowOpacity),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildInfoHeader(),
          _buildInfoDetails(),
        ],
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(_spacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_borderRadius),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_borderRadius / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.info_outline,
              size: 20,
              color: Colors.teal.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Project Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDetails() {
    return Padding(
      padding: const EdgeInsets.all(_spacing),
      child: Column(
        children: [
          _buildInfoTile(
            'Title',
            _currentProject!.title,
            Icons.title,
          ),
          _buildInfoTile(
            'Description',
            _currentProject!.description,
            Icons.description_outlined,
          ),
          _buildInfoTile(
            'Created',
            _formatDate(_currentProject!.createdAt),
            Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(_borderRadius / 2),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal.shade50.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.7, 0)
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.2,
        size.width,
        size.height * 0.15,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Add a second decorative curve
    final path2 = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.3, size.height)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.8,
        0,
        size.height * 0.85,
      )
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    final paint2 = Paint()
      ..color = Colors.teal.shade100.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

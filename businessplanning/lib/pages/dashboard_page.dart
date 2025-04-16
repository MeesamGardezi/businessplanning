import 'package:businessplanning/pages/all_projects_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import '../routes.dart';
import '../services/auth_service.dart';

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

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  late Widget _currentPage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Design Constants
  static const double _borderRadius = 24.0;
  static const double _shadowOpacity = 0.08;
  static const double _spacing = 24.0;
  static const Duration _animationDuration = Duration(milliseconds: 400);

  static const List<({String label, IconData icon, String route})> _navItems = [
    (label: 'Home', icon: Icons.home_outlined, route: 'home'),
    (label: 'Projects', icon: Icons.folder_outlined, route: 'projects'),
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
    _updateCurrentPage();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageContent != widget.pageContent ||
        oldWidget.params != widget.params) {
      _updateCurrentPage();
    }
  }

  void _updateCurrentPage() {
    setState(() {
      switch (widget.pageContent) {
        case 'home':
          _currentPage = Container();
          break;
        case 'projects':
          _currentPage = AllProjectsPage();
          break;
        default:
          _currentPage = Container();
      }
    });
  }

  void _navigateWithParams(String path, Map<String, dynamic> params) {
    router.go('$path?params=${Uri.encodeComponent(json.encode(params))}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          _buildBackground(),
          Row(
            children: [
              _buildSidePanel(context),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: AnimatedSwitcher(
                    duration: _animationDuration,
                    child: _currentPage,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: DashboardBackgroundPainter(),
      ),
    );
  }

  Widget _buildSidePanel(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_shadowOpacity),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: _spacing * 2),
          _buildLogo(),
          const SizedBox(height: _spacing * 2),
          ..._navItems.map((item) => _buildNavButton(
                context,
                item.icon,
                item.label,
                () => _navigateWithParams('/dashboard/${item.route}', {}),
              )),
          const Spacer(),
          Divider(
            color: Colors.grey[200],
            height: 1,
          ),
          _buildSettingsButton(context),
          const SizedBox(height: _spacing),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'M',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    final bool isSelected = widget.pageContent.toLowerCase() ==
        label.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal.shade50 : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? Colors.teal.shade700 : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.teal.shade700 : Colors.grey[600],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.teal.shade700 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return PopupMenuButton<String>(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Icon(
          Icons.settings_outlined,
          size: 24,
          color: Colors.grey[700],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius / 2),
      ),
      position: PopupMenuPosition.over,
      elevation: 4,
      onSelected: (value) async {
        if (value == 'logout') {
          await _auth.signOut();
          if (mounted) {
            context.go('/login');
          }
        } else if (value == 'settings') {
          _navigateWithParams('/dashboard/settings', {'section': 'general'});
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'settings',
          child: ListTile(
            leading: Icon(
              Icons.settings_outlined,
              color: Colors.grey[700],
              size: 20,
            ),
            title: Text(
              'Settings',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            leading: Icon(
              Icons.logout_outlined,
              color: Colors.grey[700],
              size: 20,
            ),
            title: Text(
              'Logout',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class DashboardBackgroundPainter extends CustomPainter {
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
      ..close();

    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = Colors.teal.shade100.withOpacity(0.2)
      ..style = PaintingStyle.fill;

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

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Let's call it "Stratwise" - combining "Strategy" and "Wise"

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  HomePage({Key? key, this.isDarkMode = false}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<({String title, String subtitle, IconData icon})> sections = [
    (
      title: 'Business Analysis',
      subtitle: 'Strategic SWOT and PEST analysis tools',
      icon: Icons.analytics_outlined,
    ),
    (
      title: 'Financial Planning',
      subtitle: 'Revenue projections and financial modeling',
      icon: Icons.account_balance_outlined,
    ),
    (
      title: 'Market Research',
      subtitle: 'Industry insights and competitor analysis',
      icon: Icons.equalizer_outlined,
    ),
    (
      title: 'Strategy Tools',
      subtitle: 'Framework templates and planning resources',
      icon: Icons.architecture_outlined,
    ),
    (
      title: 'Collaboration',
      subtitle: 'Team workspaces and sharing tools',
      icon: Icons.groups_outlined,
    ),
    (
      title: 'AI Insights',
      subtitle: 'AI-powered business recommendations',
      icon: Icons.tips_and_updates_outlined,
    ),
    (
      title: 'Get Started',
      subtitle: 'Begin your business planning journey',
      icon: Icons.rocket_launch_outlined,
    ),
  ];

  int _currentSection = 0;
  late ScrollController _scrollController;
  bool _showNavBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 600 && !_showNavBar) {
      setState(() => _showNavBar = true);
    } else if (_scrollController.offset <= 600 && _showNavBar) {
      setState(() => _showNavBar = false);
    }

    int newSection = (_scrollController.offset / 600).floor();
    if (newSection != _currentSection && newSection < sections.length) {
      setState(() => _currentSection = newSection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeroSection(),
                  ...List.generate(sections.length, 
                    (index) => _buildSection(sections[index], index)),
                ]),
              ),
            ],
          ),
          if (_showNavBar) _buildFloatingNavBar(),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: sections.length,
          itemBuilder: (context, index) => _buildNavItem(index),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _currentSection == index;
    final section = sections[index];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () {
          _scrollController.animateTo(
            index * 600.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? Colors.teal.shade50 : null,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              section.icon,
              size: 18,
              color: isSelected ? Colors.teal.shade700 : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              section.title,
              style: TextStyle(
                color: isSelected ? Colors.teal.shade700 : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 700,
      decoration: BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: const NetworkImage(
            'https://images.unsplash.com/photo-1553877522-43269d4ea984?ixlib=rb-4.0.3'
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.darken,
          ),
        ),
      ),
      child: Stack(
        children: [
          _buildBackgroundGradient(),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 80, 40, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Stratwise',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Transform your business ideas\ninto strategic success.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Comprehensive business planning tools powered by AI\nto help you make better strategic decisions.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                      ),
                      child: const Text(
                        'Create an account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  icon: const Text(
                    'View Enterprise Solutions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  label: const Icon(Icons.arrow_forward, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
            stops: const [0.4, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(({String title, String subtitle, IconData icon}) section, int index) {
    final isEven = index % 2 == 0;
    return Container(
      height: 600,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: isEven 
          ? Theme.of(context).colorScheme.background
          : Colors.white,
      ),
      child: Stack(
        children: [
          if (!isEven) _buildSectionBackground(index),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    section.icon,
                    size: 32,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.grey[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  section.subtitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBackground(int index) {
    return CustomPaint(
      size: const Size(double.infinity, 600),
      painter: SectionBackgroundPainter(
        color: Colors.teal.shade50.withOpacity(0.3),
        reverse: index % 4 == 3,
      ),
    );
  }
}

class SectionBackgroundPainter extends CustomPainter {
  final Color color;
  final bool reverse;

  SectionBackgroundPainter({
    required this.color,
    this.reverse = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    if (!reverse) {
      path.moveTo(0, 0);
      path.lineTo(size.width * 0.7, 0);
      path.quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.3,
        size.width,
        size.height * 0.2,
      );
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, size.height);
      path.lineTo(size.width * 0.3, size.height);
      path.quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.7,
        0,
        size.height * 0.8,
      );
      path.lineTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
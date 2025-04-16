import 'package:flutter/material.dart';
import '../models/pest_models.dart';
import '../services/pest_service.dart';

class PestAnalysisPage extends StatefulWidget {
  final String projectId;

  const PestAnalysisPage({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  _PestAnalysisPageState createState() => _PestAnalysisPageState();
}

const Map<PestFactorType,
        ({Color color, IconData icon, String title, String description})>
    _pestConfig = {
  PestFactorType.political: (
    color: Color(0xFF9C27B0),
    icon: Icons.account_balance,
    title: 'Political',
    description: 'Government policies, regulations, and political stability'
  ),
  PestFactorType.economic: (
    color: Color(0xFF2196F3),
    icon: Icons.trending_up,
    title: 'Economic',
    description: 'Market trends, economic indicators, and financial factors'
  ),
  PestFactorType.social: (
    color: Color(0xFF4CAF50),
    icon: Icons.people,
    title: 'Social',
    description: 'Demographics, cultural trends, and social attitudes'
  ),
  PestFactorType.technological: (
    color: Color(0xFFFF9800),
    icon: Icons.devices,
    title: 'Technological',
    description: 'Tech innovations, R&D, and digital transformation'
  ),
};

class _PestAnalysisPageState extends State<PestAnalysisPage> {
  final PestService _pestService = PestService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isLoading = false;

  // Design Constants
  static const double _spacing = 24.0;
  static const double _borderRadius = 16.0;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addNewFactor(PestFactorType type) {
    showDialog(
      context: context,
      builder: (context) => _AddPestFactorDialog(
        type: type,
        projectId: widget.projectId,
        pestService: _pestService,
      ),
    );
  }

  void _editFactor(PestFactor factor) {
    showDialog(
      context: context,
      builder: (context) => _EditPestFactorDialog(
        factor: factor,
        projectId: widget.projectId,
        pestService: _pestService,
      ),
    );
  }

  Future<void> _deleteFactor(PestFactor factor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Factor'),
        content: const Text('Are you sure you want to delete this factor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _pestService.deletePestFactor(widget.projectId, factor.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factor deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting factor: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  List<PestFactor> _filterFactors(List<PestFactor> factors) {
    if (_searchQuery.isEmpty) return factors;
    return factors
        .where((factor) =>
            factor.text.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: StreamBuilder<PestAnalysis>(
            stream: _pestService.getPestAnalysis(widget.projectId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final analysis = snapshot.data ?? PestAnalysis();
              return _buildAnalysisContent(analysis);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(_spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search factors...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_borderRadius),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<PestFactorType>(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add new factor',
                onSelected: _addNewFactor,
                itemBuilder: (context) => PestFactorType.values
                    .map((type) => PopupMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                _pestConfig[type]!.icon,
                                color: _pestConfig[type]!.color,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text('Add ${_pestConfig[type]!.title} Factor'),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent(PestAnalysis analysis) {
    return GridView.count(
      controller: _scrollController,
      padding: const EdgeInsets.all(_spacing),
      crossAxisCount: 2,
      crossAxisSpacing: _spacing,
      mainAxisSpacing: _spacing,
      children: PestFactorType.values.map((type) {
        final factors = _filterFactors(analysis.getFactorsByType(type));
        return _buildFactorSection(type, factors);
      }).toList(),
    );
  }

  Widget _buildFactorSection(PestFactorType type, List<PestFactor> factors) {
    final config = _pestConfig[type]!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSectionHeader(config, factors.length),
          Expanded(
            child: factors.isEmpty
                ? _buildEmptyState(config)
                : _buildFactorsList(factors),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    ({Color color, IconData icon, String title, String description}) config,
    int factorCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_borderRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.icon, color: config.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  config.title,
                  style: TextStyle(
                    color: config.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      factorCount.toString(),
                      style: TextStyle(
                        color: config.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _addNewFactor(
                          PestFactorType.values.firstWhere(
                            (t) => _pestConfig[t]!.title == config.title,
                          ),
                        ),
                        child: Icon(
                          Icons.add_circle_outline,
                          size: 16,
                          color: config.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            config.description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    ({Color color, IconData icon, String title, String description}) config,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            config.icon,
            size: 48,
            color: config.color.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${config.title} factors yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _addNewFactor(
              PestFactorType.values.firstWhere(
                (t) => _pestConfig[t]!.title == config.title,
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add factor'),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorsList(List<PestFactor> factors) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: factors.length,
      itemBuilder: (context, index) => _buildFactorItem(factors[index]),
    );
  }

  Widget _buildFactorItem(PestFactor factor) {
    final config = _pestConfig[factor.type]!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(factor.text),
        subtitle: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              factor.timeframe ?? 'No timeframe',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImpactIndicator(factor.impact),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _editFactor(factor);
                } else if (value == 'delete') {
                  _deleteFactor(factor);
                }
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImpactSlider(factor),
                const SizedBox(height: 8),
                _buildTimeframeSelector(factor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactIndicator(int impact) {
    final color = impact > 3
        ? Colors.red
        : impact > 2
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Impact: $impact',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImpactSlider(PestFactor factor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Impact Level',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Slider(
          value: factor.impact.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: factor.impact.toString(),
          onChanged: (value) async {
            try {
              await _pestService.updateFactorImpact(
                widget.projectId,
                factor.id,
                value.round(),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating impact: $e')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector(PestFactor factor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeframe',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'short-term',
              label: Text('Short-term'), // Made labels consistent
              icon: Icon(Icons.speed, size: 18), // Reduced icon size
            ),
            ButtonSegment(
              value: 'medium-term',
              label: Text('Medium-term'),
              icon: Icon(Icons.timeline, size: 18),
            ),
            ButtonSegment(
              value: 'long-term',
              label: Text('Long-term'),
              icon: Icon(Icons.update, size: 18),
            ),
          ],
          selected: {factor.timeframe ?? 'medium-term'},
          onSelectionChanged: (Set<String> selection) async {
            try {
              await _pestService.updateFactorTimeframe(
                widget.projectId,
                factor.id,
                selection.first,
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating timeframe: $e')),
              );
            }
          },
        ),
      ],
    );
  }

  void _showFactorOptions(PestFactor factor) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              _editFactor(factor);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete'),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _deleteFactor(factor);
            },
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
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading PEST analysis',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

// Dialog for adding new PEST factors
class _AddPestFactorDialog extends StatefulWidget {
  final PestFactorType type;
  final String projectId;
  final PestService pestService;

  const _AddPestFactorDialog({
    Key? key,
    required this.type,
    required this.projectId,
    required this.pestService,
  }) : super(key: key);

  @override
  _AddPestFactorDialogState createState() => _AddPestFactorDialogState();
}

class _AddPestFactorDialogState extends State<_AddPestFactorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  String _timeframe = 'medium-term';
  int _impact = 3;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final newFactor = PestFactor(
        id: '',
        text: _textController.text,
        type: widget.type,
        impact: _impact,
        timeframe: _timeframe,
        createdAt:
            DateTime.now(), // This will be overwritten by server timestamp
      );

      await widget.pestService.createPestFactor(widget.projectId, newFactor);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factor added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding factor: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _pestConfig[widget.type]!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(config.icon, color: config.color, size: 24),
          const SizedBox(width: 8),
          Text('Add ${config.title} Factor'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter factor description...',
              ),
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty == true ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 16),
            Text('Impact Level', style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: _impact.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _impact.toString(),
              onChanged: (value) => setState(() => _impact = value.round()),
            ),
            const SizedBox(height: 16),
            Text('Timeframe', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'short-term',
                  label: Text('Short-term'), // Made labels consistent
                  icon: Icon(Icons.speed, size: 18), // Reduced icon size
                ),
                ButtonSegment(
                  value: 'medium-term',
                  label: Text('Medium-term'),
                  icon: Icon(Icons.timeline, size: 18),
                ),
                ButtonSegment(
                  value: 'long-term',
                  label: Text('Long-term'),
                  icon: Icon(Icons.update, size: 18),
                ),
              ],
              style: ButtonStyle(
                visualDensity: VisualDensity.compact, // More compact layout
                // Ensure proper padding
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              selected: {_timeframe},
              onSelectionChanged: (Set<String> selection) =>
                  setState(() => _timeframe = selection.first),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}

// Dialog for editing existing PEST factors
class _EditPestFactorDialog extends StatefulWidget {
  final PestFactor factor;
  final String projectId;
  final PestService pestService;

  const _EditPestFactorDialog({
    Key? key,
    required this.factor,
    required this.projectId,
    required this.pestService,
  }) : super(key: key);

  @override
  _EditPestFactorDialogState createState() => _EditPestFactorDialogState();
}

class _EditPestFactorDialogState extends State<_EditPestFactorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;
  late String _timeframe;
  late int _impact;
  late PestFactorType _type;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.factor.text);
    _timeframe = widget.factor.timeframe ?? 'medium-term';
    _impact = widget.factor.impact;
    _type = widget.factor.type;
    _textController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    setState(() {
      _hasChanges = _textController.text != widget.factor.text ||
          _timeframe != widget.factor.timeframe ||
          _impact != widget.factor.impact ||
          _type != widget.factor.type;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updatedFactor = widget.factor.copyWith(
        text: _textController.text,
        type: _type,
        impact: _impact,
        timeframe: _timeframe,
        updatedAt: DateTime.now(),
      );

      await widget.pestService.updatePestFactor(
        widget.projectId,
        widget.factor.id,
        updatedFactor,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factor updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating factor: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Factor'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter factor description...',
              ),
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty == true ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PestFactorType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: PestFactorType.values.map((type) {
                final config = _pestConfig[type]!;
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(config.icon, color: config.color, size: 20),
                      const SizedBox(width: 8),
                      Text(config.title),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _type = value;
                    _checkChanges();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text('Impact Level', style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: _impact.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _impact.toString(),
              onChanged: (value) {
                setState(() {
                  _impact = value.round();
                  _checkChanges();
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Timeframe', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'short-term',
                  label: Text('Short-term'), // Made labels consistent
                  icon: Icon(Icons.speed, size: 18), // Reduced icon size
                ),
                ButtonSegment(
                  value: 'medium-term',
                  label: Text('Medium-term'),
                  icon: Icon(Icons.timeline, size: 18),
                ),
                ButtonSegment(
                  value: 'long-term',
                  label: Text('Long-term'),
                  icon: Icon(Icons.update, size: 18),
                ),
              ],
              style: ButtonStyle(
                visualDensity: VisualDensity.compact, // More compact layout
                // Ensure proper padding
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              selected: {_timeframe},
              onSelectionChanged: (Set<String> selection) =>
                  setState(() => _timeframe = selection.first),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading || !_hasChanges ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

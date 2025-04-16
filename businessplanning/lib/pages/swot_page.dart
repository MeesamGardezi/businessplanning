import 'package:flutter/material.dart';
import '../models/swot_models.dart';
import '../services/swot_service.dart';
import 'package:flutter/services.dart';

class SwotAnalysisPage extends StatefulWidget {
  final String projectId;

  const SwotAnalysisPage({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  _SwotAnalysisPageState createState() => _SwotAnalysisPageState();
}

const Map<SwotType, ({Color color, IconData icon, String title})> _swotConfig =
    {
  SwotType.strength: (
    color: Color(0xFF4CAF50),
    icon: Icons.trending_up,
    title: 'Strengths'
  ),
  SwotType.weakness: (
    color: Color(0xFFF44336),
    icon: Icons.trending_down,
    title: 'Weaknesses'
  ),
  SwotType.opportunity: (
    color: Color(0xFF2196F3),
    icon: Icons.lightbulb_outline,
    title: 'Opportunities'
  ),
  SwotType.threat: (
    color: Color(0xFFFF9800),
    icon: Icons.warning_outlined,
    title: 'Threats'
  ),
};

class _SwotAnalysisPageState extends State<SwotAnalysisPage> {
  final SwotService _swotService = SwotService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  // Design Constants
  static const double _spacing = 24.0;
  static const double _borderRadius = 16.0;

  void _addNewItem(SwotType type) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent clicking outside while processing
      builder: (context) => WillPopScope(
        // Prevent back button while processing
        onWillPop: () async => !_isLoading,
        child: _AddSwotItemDialog(
          type: type,
          projectId: widget.projectId,
          swotService: _swotService,
        ),
      ),
    );
  }

  void _editItem(SwotItem item) {
    showDialog(
      context: context,
      builder: (context) => _EditSwotItemDialog(
        item: item,
        projectId: widget.projectId,
        swotService: _swotService,
      ),
    );
  }

  Future<void> _deleteItem(SwotItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
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
        await _swotService.deleteSwotItem(widget.projectId, item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _moveItem(SwotItem item, SwotType newType) async {
    setState(() => _isLoading = true);
    try {
      await _swotService.moveSwotItem(widget.projectId, item.id, newType);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving item: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<SwotItem> _filterItems(List<SwotItem> items) {
    if (_searchQuery.isEmpty) return items;
    return items
        .where((item) =>
            item.text.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: StreamBuilder<SwotAnalysis>(
            stream: _swotService.getSwotAnalysis(widget.projectId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              if (!snapshot.hasData && !snapshot.hasError) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final analysis = snapshot.data ??
                  SwotAnalysis(); // Provide empty analysis as fallback
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildSwotGrid(analysis),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(_spacing),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search SWOT items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 16),
          PopupMenuButton<SwotType>(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add new item',
            onSelected: _addNewItem,
            itemBuilder: (context) => SwotType.values
                .map((type) => PopupMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            _swotConfig[type]!.icon,
                            color: _swotConfig[type]!.color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text('Add ${_swotConfig[type]!.title}'),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwotGrid(SwotAnalysis analysis) {
    return GridView.count(
      padding: const EdgeInsets.all(_spacing),
      crossAxisCount: 2,
      crossAxisSpacing: _spacing,
      mainAxisSpacing: _spacing,
      children: SwotType.values.map((type) {
        final items = _filterItems(analysis.getItemsByType(type));
        return _buildSwotQuadrant(type, items);
      }).toList(),
    );
  }

  Widget _buildSwotQuadrant(SwotType type, List<SwotItem> items) {
    final config = _swotConfig[type]!;

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
      child: DragTarget<SwotItem>(
        onWillAccept: (item) => item?.type != type,
        onAccept: (item) => _moveItem(item, type),
        builder: (context, candidateData, rejectedData) => Column(
          children: [
            _buildQuadrantHeader(config, items.length),
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState(config)
                  : _buildItemsList(items),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrantHeader(
    ({Color color, IconData icon, String title}) config,
    int itemCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_borderRadius),
        ),
      ),
      child: Row(
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
                  itemCount.toString(),
                  style: TextStyle(
                    color: config.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _addNewItem(
                      SwotType.values.firstWhere(
                        (t) => _swotConfig[t]!.title == config.title,
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
    );
  }

  Widget _buildEmptyState(({Color color, IconData icon, String title}) config) {
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
            'No items yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _addNewItem(
              SwotType.values.firstWhere(
                (t) => _swotConfig[t]!.title == config.title,
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add item'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<SwotItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildSwotItem(items[index]),
    );
  }

  Widget _buildSwotItem(SwotItem item) {
    final config = _swotConfig[item.type]!;

    return Draggable<SwotItem>(
      data: item,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(_borderRadius),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          child: Text(
            item.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          item.text,
          style: TextStyle(color: Colors.grey[400]),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: ListTile(
          title: Text(item.text),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _editItem(item),
                tooltip: 'Edit item',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outlined, size: 20),
                onPressed: () => _deleteItem(item),
                tooltip: 'Delete item',
              ),
            ],
          ),
        ),
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
            'Error loading SWOT analysis',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AddSwotItemDialog extends StatefulWidget {
  final SwotType type;
  final String projectId;
  final SwotService swotService;

  const _AddSwotItemDialog({
    Key? key,
    required this.type,
    required this.projectId,
    required this.swotService,
  }) : super(key: key);

  @override
  _AddSwotItemDialogState createState() => _AddSwotItemDialogState();
}

class _AddSwotItemDialogState extends State<_AddSwotItemDialog> {
  final _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_textController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final newItem = SwotItem(
        id: '',
        text: _textController.text,
        type: widget.type,
        createdAt: DateTime.now(),
      );

      await widget.swotService.createSwotItem(widget.projectId, newItem);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding item: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${_swotConfig[widget.type]!.title}'),
      content: TextField(
        controller: _textController,
        decoration: const InputDecoration(
          labelText: 'Description',
          hintText: 'Enter the description...',
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
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

class _EditSwotItemDialog extends StatefulWidget {
  final SwotItem item;
  final String projectId;
  final SwotService swotService;

  const _EditSwotItemDialog({
    Key? key,
    required this.item,
    required this.projectId,
    required this.swotService,
  }) : super(key: key);

  @override
  _EditSwotItemDialogState createState() => _EditSwotItemDialogState();
}

class _EditSwotItemDialogState extends State<_EditSwotItemDialog> {
  late TextEditingController _textController;
  late SwotType _selectedType;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item.text);
    _selectedType = widget.item.type;
    _textController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    setState(() {
      _hasChanges = _textController.text != widget.item.text ||
          _selectedType != widget.item.type;
    });
  }

  Future<void> _submit() async {
    if (_textController.text.isEmpty) return;
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updatedItem = widget.item.copyWith(
        text: _textController.text,
        type: _selectedType,
        updatedAt: DateTime.now(),
      );

      await widget.swotService.updateSwotItem(
        widget.projectId,
        widget.item.id,
        updatedItem,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating item: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter the description...',
            ),
            maxLines: 3,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<SwotType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: SwotType.values.map((type) {
              final config = _swotConfig[type]!;
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      config.icon,
                      color: config.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(config.title),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newType) {
              if (newType != null) {
                setState(() {
                  _selectedType = newType;
                  _checkChanges();
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
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

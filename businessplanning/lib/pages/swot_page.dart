// lib/pages/swot_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/swot_models.dart';
import '../services/swot_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

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
  // Access global app state
  final AppState _appState = AppState();
  
  // Services
  final SwotService _swotService = SwotService();
  
  // Local state as ValueNotifiers
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  final ValueNotifier<bool> _isOperationLoading = ValueNotifier<bool>(false);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupSearchListener();
    _loadSwotData();
  }
  
  void _setupSearchListener() {
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
    });
  }
  
  void _loadSwotData() {
    _appState.isSwotLoading.value = true;
    _appState.swotError.value = null;
    
    try {
      // Set up a stream subscription through the SwotService
      _swotService.getSwotAnalysis(widget.projectId).listen(
        (analysis) {
          _appState.swotAnalysis.value = analysis;
          _appState.isSwotLoading.value = false;
        },
        onError: (error) {
          _appState.swotError.value = error.toString();
          _appState.isSwotLoading.value = false;
        }
      );
    } catch (e) {
      _appState.swotError.value = e.toString();
      _appState.isSwotLoading.value = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    _isOperationLoading.dispose();
    super.dispose();
  }

  void _addNewItem(SwotType type) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent clicking outside while processing
      builder: (context) => WillPopScope(
        // Prevent back button while processing
        onWillPop: () async => !_isOperationLoading.value,
        child: _AddSwotItemDialog(
          type: type,
          projectId: widget.projectId,
          swotService: _swotService,
          isLoading: _isOperationLoading,
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
        isLoading: _isOperationLoading,
      ),
    );
  }

  Future<void> _deleteItem(SwotItem item) async {
    final theme = Theme.of(context);
    
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
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _isOperationLoading.value = true;
      try {
        await _swotService.deleteSwotItem(widget.projectId, item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: $e')),
          );
        }
      } finally {
        _isOperationLoading.value = false;
      }
    }
  }

  Future<void> _moveItem(SwotItem item, SwotType newType) async {
    _isOperationLoading.value = true;
    try {
      await _swotService.moveSwotItem(widget.projectId, item.id, newType);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving item: $e')),
        );
      }
    } finally {
      _isOperationLoading.value = false;
    }
  }

  List<SwotItem> _filterItems(List<SwotItem> items, String query) {
    if (query.isEmpty) return items;
    return items
        .where((item) =>
            item.text.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        _buildHeader(theme),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _appState.isSwotLoading,
            builder: (context, isLoading, _) {
              if (isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                );
              }
              
              return ValueListenableBuilder<String?>(
                valueListenable: _appState.swotError,
                builder: (context, error, _) {
                  if (error != null) {
                    return _buildErrorState(error, theme);
                  }
                  
                  return ValueListenableBuilder<SwotAnalysis>(
                    valueListenable: _appState.swotAnalysis,
                    builder: (context, analysis, _) {
                      return AnimatedSwitcher(
                        duration: Duration.zero,
                        child: _buildSwotGrid(analysis, theme),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search SWOT items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMD,
                  vertical: AppTheme.spaceSM,
                ),
              ),
              onChanged: (value) => _searchQuery.value = value,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          ValueListenableBuilder<bool>(
            valueListenable: _isOperationLoading,
            builder: (context, isLoading, _) {
              return PopupMenuButton<SwotType>(
                enabled: !isLoading,
                tooltip: 'Add new item',
                icon: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                        ),
                      )
                    : const Icon(Icons.add_circle_outline),
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
                              const SizedBox(width: AppTheme.spaceSM),
                              Text('Add ${_swotConfig[type]!.title}'),
                            ],
                          ),
                        ))
                    .toList(),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildSwotGrid(SwotAnalysis analysis, ThemeData theme) {
    return ValueListenableBuilder<String>(
      valueListenable: _searchQuery,
      builder: (context, query, _) {
        return GridView.count(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          crossAxisCount: 2,
          crossAxisSpacing: AppTheme.spaceLG,
          mainAxisSpacing: AppTheme.spaceLG,
          children: SwotType.values.map((type) {
            final items = _filterItems(analysis.getItemsByType(type), query);
            return _buildSwotQuadrant(type, items, theme);
          }).toList(),
        );
      },
    );
  }

  Widget _buildSwotQuadrant(SwotType type, List<SwotItem> items, ThemeData theme) {
    final config = _swotConfig[type]!;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: theme.isDarkMode ? AppTheme.shadowSmallDark : AppTheme.shadowSmall,
      ),
      child: DragTarget<SwotItem>(
        onWillAccept: (item) => item?.type != type,
        onAccept: (item) => _moveItem(item, type),
        builder: (context, candidateData, rejectedData) => Column(
          children: [
            _buildQuadrantHeader(config, items.length, theme),
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState(config, theme)
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
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLG),
        ),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.color),
          const SizedBox(width: AppTheme.spaceSM),
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
              horizontal: AppTheme.spaceSM,
              vertical: AppTheme.spaceXS,
            ),
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
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

  Widget _buildEmptyState(
    ({Color color, IconData icon, String title}) config,
    ThemeData theme,
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
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'No items yet',
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          TextButton.icon(
            onPressed: () => _addNewItem(
              SwotType.values.firstWhere(
                (t) => _swotConfig[t]!.title == config.title,
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add item'),
            style: TextButton.styleFrom(
              foregroundColor: config.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<SwotItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceSM),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildSwotItem(items[index]),
    );
  }

  Widget _buildSwotItem(SwotItem item) {
    final theme = Theme.of(context);
    final config = _swotConfig[item.type]!;

    return Draggable<SwotItem>(
      data: item,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Text(
            item.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textPrimaryColor,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Text(
          item.text,
          style: TextStyle(color: theme.textSecondaryColor),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        elevation: 0,
        child: ListTile(
          title: Text(item.text),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit_outlined, 
                  size: 20,
                  color: theme.textSecondaryColor,
                ),
                onPressed: () => _editItem(item),
                tooltip: 'Edit item',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outlined, 
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                onPressed: () => _deleteItem(item),
                tooltip: 'Delete item',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Error loading SWOT analysis',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceLG),
            ElevatedButton.icon(
              onPressed: _loadSwotData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog for adding new SWOT items
class _AddSwotItemDialog extends StatefulWidget {
  final SwotType type;
  final String projectId;
  final SwotService swotService;
  final ValueNotifier<bool> isLoading;

  const _AddSwotItemDialog({
    Key? key,
    required this.type,
    required this.projectId,
    required this.swotService,
    required this.isLoading,
  }) : super(key: key);

  @override
  _AddSwotItemDialogState createState() => _AddSwotItemDialogState();
}

class _AddSwotItemDialogState extends State<_AddSwotItemDialog> {
  final _textController = TextEditingController();

  Future<void> _submit() async {
    if (_textController.text.isEmpty) return;

    widget.isLoading.value = true;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
        );
      }
    } finally {
      widget.isLoading.value = false;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _swotConfig[widget.type]!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(config.icon, color: config.color, size: 24),
          const SizedBox(width: AppTheme.spaceSM),
          Text('Add ${config.title}'),
        ],
      ),
      content: TextField(
        controller: _textController,
        decoration: InputDecoration(
          labelText: 'Description',
          hintText: 'Enter the description...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: widget.isLoading,
          builder: (context, isLoading, _) {
            return ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            );
          },
        ),
      ],
    );
  }
}

// Dialog for editing existing SWOT items
class _EditSwotItemDialog extends StatefulWidget {
  final SwotItem item;
  final String projectId;
  final SwotService swotService;
  final ValueNotifier<bool> isLoading;

  const _EditSwotItemDialog({
    Key? key,
    required this.item,
    required this.projectId,
    required this.swotService,
    required this.isLoading,
  }) : super(key: key);

  @override
  _EditSwotItemDialogState createState() => _EditSwotItemDialogState();
}

class _EditSwotItemDialogState extends State<_EditSwotItemDialog> {
  late TextEditingController _textController;
  late SwotType _selectedType;
  final ValueNotifier<bool> _hasChanges = ValueNotifier<bool>(false);

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
    _hasChanges.dispose();
    super.dispose();
  }

  void _checkChanges() {
    _hasChanges.value = _textController.text != widget.item.text ||
        _selectedType != widget.item.type;
  }

  Future<void> _submit() async {
    if (_textController.text.isEmpty || !_hasChanges.value) {
      Navigator.of(context).pop();
      return;
    }

    widget.isLoading.value = true;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    } finally {
      widget.isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Edit Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Enter the description...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            maxLines: 3,
            autofocus: true,
          ),
          const SizedBox(height: AppTheme.spaceMD),
          DropdownButtonFormField<SwotType>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
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
                    const SizedBox(width: AppTheme.spaceSM),
                    Text(config.title),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newType) {
              if (newType != null) {
                _selectedType = newType;
                _checkChanges();
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
        ValueListenableBuilder<bool>(
          valueListenable: _hasChanges,
          builder: (context, hasChanges, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: widget.isLoading,
              builder: (context, isLoading, _) {
                return ElevatedButton(
                  onPressed: isLoading || !hasChanges ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                );
              },
            );
          }
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/action_model.dart';
import '../services/action_service.dart';

class ActionPlanPage extends StatefulWidget {
  final String projectId;

  const ActionPlanPage({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  State<ActionPlanPage> createState() => _ActionPlanPageState();
}

class _ActionPlanPageState extends State<ActionPlanPage> {
  late final ActionPlanService _actionPlanService;
  final _dateFormat = DateFormat('MMM d, yyyy');
  final _scrollController = ScrollController();
  final Map<String, TextEditingController> _controllers = {};
  final _selectedItems = <String>{};

  int? _hoveredRowIndex;
  List<ActionItem> _localItems = [];
  TaskStatus? _statusFilter;
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  static const double _rowHeight = 48.0;
  static const double _headerHeight = 56.0;

  bool get _hasSelection => _selectedItems.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _actionPlanService = ActionPlanService();
    _fetchData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fetchData() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    _actionPlanService.getActionItems(widget.projectId).listen(
      (items) {
        if (mounted) {
          setState(() {
            _localItems = items;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = 'Failed to load action items: $error';
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _addEmptyRow() async {
    try {
      final newItem = ActionItem(
        id: '',
        task: '',
        responsible: '',
        update: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _actionPlanService.createActionItem(widget.projectId, newItem);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create new item: $e')),
        );
      }
    }
  }

  Future<void> _deleteRow(ActionItem item) async {
    try {
      await _actionPlanService.deleteActionItem(widget.projectId, item.id);

      // Clean up controllers
      ['task', 'responsible', 'update'].forEach((field) {
        final key = '${item.id}_$field';
        _controllers.remove(key)?.dispose();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e')),
        );
      }
    }
  }

  Future<void> _handleStatusChange(ActionItem item) async {
    try {
      final nextStatus = switch (item.status) {
        TaskStatus.incomplete => TaskStatus.inProgress,
        TaskStatus.inProgress => TaskStatus.complete,
        TaskStatus.complete => TaskStatus.incomplete,
      };

      final updatedItem = item.copyWith(
        status: nextStatus,
        updatedAt: DateTime.now(),
      );
      await _actionPlanService.updateActionItem(widget.projectId, updatedItem);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _handleDateSelected(ActionItem item) async {
    try {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: item.completionDate ?? DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );

      if (pickedDate != null) {
        final updatedItem = item.copyWith(
          completionDate: pickedDate,
          updatedAt: DateTime.now(),
        );
        await _actionPlanService.updateActionItem(
            widget.projectId, updatedItem);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update date: $e')),
        );
      }
    }
  }

  Future<void> _handleCellSubmitted(
    ActionItem item,
    String field,
    String value,
  ) async {
    if (!mounted) return;

    try {
      final updatedItem = switch (field) {
        'task' => item.copyWith(task: value, updatedAt: DateTime.now()),
        'responsible' =>
          item.copyWith(responsible: value, updatedAt: DateTime.now()),
        'update' => item.copyWith(update: value, updatedAt: DateTime.now()),
        _ => item
      };

      await _actionPlanService.updateActionItem(widget.projectId, updatedItem);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes: $e')),
        );
      }
    }
  }

  void _handleItemSelection(String itemId, bool? selected) {
    setState(() {
      if (selected ?? false) {
        _selectedItems.add(itemId);
      } else {
        _selectedItems.remove(itemId);
      }
    });
  }

  List<ActionItem> _getFilteredItems() {
    return _localItems.where((item) {
      if (_statusFilter != null && item.status != _statusFilter) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return item.task.toLowerCase().contains(query) ||
            item.responsible.toLowerCase().contains(query) ||
            item.update.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  TextEditingController _getController(
      String id, String field, String initialText) {
    final key = '${id}_$field';
    _controllers[key] ??= TextEditingController(text: initialText);
    return _controllers[key]!;
  }

  Widget _buildEditableCell(
    BuildContext context,
    ActionItem item,
    String field,
    String value, {
    required int flex,
  }) {
    final controller = _getController(item.id, field, value);
    if (controller.text != value) {
      controller.text = value;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          style: const TextStyle(fontSize: 14),
          onSubmitted: (newValue) =>
              _handleCellSubmitted(item, field, newValue),
          onEditingComplete: () =>
              _handleCellSubmitted(item, field, controller.text),
          onChanged: (newValue) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && controller.text == newValue) {
                _handleCellSubmitted(item, field, newValue);
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildStatusCell(BuildContext context, ActionItem item, int index) {
    final statusConfig = switch (item.status) {
      TaskStatus.incomplete => (
          icon: Icons.radio_button_unchecked,
          color: Colors.grey[400],
          tooltip: 'Mark as in progress'
        ),
      TaskStatus.inProgress => (
          icon: Icons.pending,
          color: Colors.orange,
          tooltip: 'Mark as complete'
        ),
      TaskStatus.complete => (
          icon: Icons.check_circle,
          color: Colors.green,
          tooltip: 'Mark as incomplete'
        ),
    };

    return SizedBox(
      width: 80,
      child: IconButton(
        icon: Icon(
          statusConfig.icon,
          size: _hoveredRowIndex == index ? 24 : 22,
          color: statusConfig.color,
        ),
        onPressed: () => _handleStatusChange(item),
        tooltip: statusConfig.tooltip,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 96), // Space for action buttons
          const SizedBox(
            width: 80,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child:
                  Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child:
                  Text('Task', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Responsible',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Due Date',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Updates',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final filteredItems = _getFilteredItems();

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredItems.length + 1, // +1 for add row
      itemBuilder: (context, index) {
        if (index == filteredItems.length) {
          return _buildAddRow();
        }

        final item = filteredItems[index];
        return _buildItemRow(item, index);
      },
    );
  }

  Widget _buildAddRow() {
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: _addEmptyRow,
              tooltip: 'Add new task',
            ),
          ),
          const SizedBox(width: 80), // Status column
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Add new task',
                  style: TextStyle(color: Colors.grey[600])),
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 3, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildItemRow(ActionItem item, int index) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: Container(
        key: ValueKey(item.id),
        height:  _rowHeight,
        decoration: BoxDecoration(
          color: _hoveredRowIndex == index ? Colors.grey[50] : Colors.white,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      size: _hoveredRowIndex == index ? 22 : 20,
                      color: _hoveredRowIndex == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                    onPressed: _addEmptyRow,
                    tooltip: 'Add row below',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: _hoveredRowIndex == index ? 22 : 20,
                      color: _hoveredRowIndex == index
                          ? Colors.red[700]
                          : Colors.red[400],
                    ),
                    onPressed: () => _deleteRow(
                        item), // Changed from _deleteSelectedItems to _deleteRow
                    tooltip: 'Delete row',
                  ),
                ],
              ),
            ),
            _buildStatusCell(context, item, index),
            _buildEditableCell(context, item, 'task', item.task, flex: 3),
            _buildEditableCell(context, item, 'responsible', item.responsible,
                flex: 2),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => _handleDateSelected(item),
                  child: Container(
                    height: 40,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      item.completionDate != null
                          ? _dateFormat.format(item.completionDate!)
                          : 'Set date',
                      style: TextStyle(
                        fontSize: 14,
                        color: item.completionDate != null
                            ? null
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildEditableCell(context, item, 'update', item.update, flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final stats = TaskStatus.values
        .map((status) =>
            _localItems.where((item) => item.status == status).length)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (_) => setState(() => _statusFilter = null),
                ),
                ChoiceChip(
                  label: Text('Incomplete (${stats[0]})'),
                  selected: _statusFilter == TaskStatus.incomplete,
                  onSelected: (_) => setState(() => _statusFilter =
                      _statusFilter == TaskStatus.incomplete
                          ? null
                          : TaskStatus.incomplete),
                ),
                ChoiceChip(
                  label: Text('In Progress (${stats[1]})'),
                  selected: _statusFilter == TaskStatus.inProgress,
                  onSelected: (_) => setState(() => _statusFilter =
                      _statusFilter == TaskStatus.inProgress
                          ? null
                          : TaskStatus.inProgress),
                ),
                ChoiceChip(
                  label: Text('Complete (${stats[2]})'),
                  selected: _statusFilter == TaskStatus.complete,
                  onSelected: (_) => setState(() => _statusFilter =
                      _statusFilter == TaskStatus.complete
                          ? null
                          : TaskStatus.complete),
                ),
              ],
            ),
          ),
          if (_localItems.isNotEmpty) ...[
            const VerticalDivider(),
            Text(
              '${_localItems.where((i) => i.status == TaskStatus.complete).length}'
              ' of ${_localItems.length} complete',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilterBar(context),
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Found ${_getFilteredItems().length} items',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _buildTable(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

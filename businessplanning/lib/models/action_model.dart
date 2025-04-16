import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  incomplete,
  inProgress,
  complete;

  String get label => switch (this) {
    TaskStatus.incomplete => 'Incomplete',
    TaskStatus.inProgress => 'In Progress',
    TaskStatus.complete => 'Complete',
  };

  String get tooltip => 'Mark as ${switch (this) {
    TaskStatus.incomplete => 'in progress',
    TaskStatus.inProgress => 'complete',
    TaskStatus.complete => 'incomplete',
  }}';
}

class ActionItem implements Comparable<ActionItem> {
  static const String defaultId = '';
  static const String defaultTask = '';
  static const String defaultResponsible = '';
  static const String defaultUpdate = '';
  
  final String id;
  final String task;
  final String responsible;
  final DateTime? completionDate;
  final String update;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final TaskStatus status;

  bool get isValid => 
    id.isNotEmpty && 
    task.isNotEmpty && 
    responsible.isNotEmpty;

  const ActionItem({
    required this.id,
    required this.task,
    required this.responsible,
    this.completionDate,
    required this.update,
    required this.createdAt,
    this.updatedAt,
    this.status = TaskStatus.incomplete,
  });

  factory ActionItem.empty() => ActionItem(
    id: defaultId,
    task: defaultTask,
    responsible: defaultResponsible,
    update: defaultUpdate,
    createdAt: DateTime.now(),
    status: TaskStatus.incomplete,
  );

  factory ActionItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ActionItem(
      id: data['id']?.toString() ?? defaultId,
      task: data['task'] ?? defaultTask,
      responsible: data['responsible'] ?? defaultResponsible,
      completionDate: (data['completionDate'] as Timestamp?)?.toDate(),
      update: data['update'] ?? defaultUpdate,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      status: TaskStatus.values[data['status'] ?? 0],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'task': task,
    'responsible': responsible,
    'completionDate': completionDate != null ? Timestamp.fromDate(completionDate!) : null,
    'update': update,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'status': status.index,
  };

  ActionItem copyWith({
    String? task,
    String? responsible,
    DateTime? completionDate,
    String? update,
    DateTime? updatedAt,
    TaskStatus? status,
  }) => ActionItem(
    id: id,
    task: task ?? this.task,
    responsible: responsible ?? this.responsible,
    completionDate: completionDate ?? this.completionDate,
    update: update ?? this.update,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    status: status ?? this.status,
  );

  @override
  int compareTo(ActionItem other) => id.compareTo(other.id);

  @override
  String toString() => 'ActionItem(id: $id, task: $task, responsible: $responsible, '
    'completionDate: $completionDate, update: $update, createdAt: $createdAt, '
    'updatedAt: $updatedAt, status: $status)';

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is ActionItem &&
    other.id == id &&
    other.task == task &&
    other.responsible == responsible &&
    other.completionDate == completionDate &&
    other.update == update &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt &&
    other.status == status;

  @override
  int get hashCode => Object.hash(
    id,
    task,
    responsible,
    completionDate,
    update,
    createdAt,
    updatedAt,
    status,
  );
}
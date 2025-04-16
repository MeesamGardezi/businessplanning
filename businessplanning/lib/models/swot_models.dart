import 'package:cloud_firestore/cloud_firestore.dart';

// Enum for SWOT types
enum SwotType {
  strength,
  weakness,
  opportunity,
  threat;

  // Helper method to convert enum to string for storage
  String toShortString() {
    return toString().split('.').last;
  }

  // Helper method to get enum from string
  static SwotType fromString(String value) {
    return SwotType.values.firstWhere(
      (type) => type.toShortString() == value.toLowerCase(),
      orElse: () => SwotType.strength,
    );
  }
}

class SwotItem {
  final String id;
  final String text;
  final SwotType type;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SwotItem({
    required this.id,
    required this.text,
    required this.type,
    required this.createdAt,
    this.updatedAt,
  });

  // Create a copy of the current item with optional new values
  SwotItem copyWith({
    String? id,
    String? text,
    SwotType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SwotItem(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'type': type.toShortString(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore document
  factory SwotItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SwotItem(
      id: doc.id,
      text: data['text'] ?? '',
      type: SwotType.fromString(data['type'] ?? ''),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(), // Handle null timestamp
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create from Map (useful for testing and local operations)
  factory SwotItem.fromMap(Map<String, dynamic> map) {
    return SwotItem(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      type: SwotType.fromString(map['type'] ?? ''),
      createdAt: map['createdAt'] ?? DateTime.now(),
      updatedAt: map['updatedAt'],
    );
  }

  // Convert to Map (useful for testing and local operations)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': type.toShortString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SwotItem(id: $id, text: $text, type: ${type.toShortString()}, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

// Helper class to group SWOT items by type
class SwotAnalysis {
  final List<SwotItem> strengths;
  final List<SwotItem> weaknesses;
  final List<SwotItem> opportunities;
  final List<SwotItem> threats;

  SwotAnalysis({
    this.strengths = const [],
    this.weaknesses = const [],
    this.opportunities = const [],
    this.threats = const [],
  });

  // Factory constructor to create SwotAnalysis from a list of items
  factory SwotAnalysis.fromItems(List<SwotItem> items) {
    return SwotAnalysis(
      strengths: items.where((item) => item.type == SwotType.strength).toList(),
      weaknesses:
          items.where((item) => item.type == SwotType.weakness).toList(),
      opportunities:
          items.where((item) => item.type == SwotType.opportunity).toList(),
      threats: items.where((item) => item.type == SwotType.threat).toList(),
    );
  }

  // Get all items as a flat list
  List<SwotItem> get allItems => [
        ...strengths,
        ...weaknesses,
        ...opportunities,
        ...threats,
      ];

  // Get items by type
  List<SwotItem> getItemsByType(SwotType type) {
    switch (type) {
      case SwotType.strength:
        return strengths;
      case SwotType.weakness:
        return weaknesses;
      case SwotType.opportunity:
        return opportunities;
      case SwotType.threat:
        return threats;
    }
  }
}

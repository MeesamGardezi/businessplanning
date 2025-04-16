// PEST Analysis factor types
import 'package:cloud_firestore/cloud_firestore.dart';

enum PestFactorType {
  political,
  economic,
  social,
  technological;

  String toShortString() {
    return toString().split('.').last;
  }

  static PestFactorType fromString(String value) {
    return PestFactorType.values.firstWhere(
      (type) => type.toShortString() == value.toLowerCase(),
      orElse: () => PestFactorType.political,
    );
  }

  String get displayName {
    switch (this) {
      case PestFactorType.political:
        return 'Political';
      case PestFactorType.economic:
        return 'Economic';
      case PestFactorType.social:
        return 'Social';
      case PestFactorType.technological:
        return 'Technological';
    }
  }
}

// Individual PEST factor item
class PestFactor {
  final String id;
  final String text;
  final PestFactorType type;
  final int impact; // 1-5 scale
  final String? timeframe; // short-term, medium-term, long-term
  final DateTime createdAt;
  final DateTime? updatedAt;

  PestFactor({
    required this.id,
    required this.text,
    required this.type,
    required this.impact,
    this.timeframe,
    required this.createdAt,
    this.updatedAt,
  });

  // Create a copy with optional new values
  PestFactor copyWith({
    String? id,
    String? text,
    PestFactorType? type,
    int? impact,
    String? timeframe,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PestFactor(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      impact: impact ?? this.impact,
      timeframe: timeframe ?? this.timeframe,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'type': type.toShortString(),
      'impact': impact,
      'timeframe': timeframe,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create from Firestore document
  factory PestFactor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PestFactor(
      id: doc.id,
      text: data['text'] ?? '',
      type: PestFactorType.fromString(data['type'] ?? ''),
      impact: data['impact'] ?? 3,
      timeframe: data['timeframe'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

// Complete PEST analysis containing all factors
class PestAnalysis {
  final List<PestFactor> political;
  final List<PestFactor> economic;
  final List<PestFactor> social;
  final List<PestFactor> technological;

  PestAnalysis({
    this.political = const [],
    this.economic = const [],
    this.social = const [],
    this.technological = const [],
  });

  // Create from a list of factors
  factory PestAnalysis.fromFactors(List<PestFactor> factors) {
    return PestAnalysis(
      political:
          factors.where((f) => f.type == PestFactorType.political).toList(),
      economic:
          factors.where((f) => f.type == PestFactorType.economic).toList(),
      social: factors.where((f) => f.type == PestFactorType.social).toList(),
      technological:
          factors.where((f) => f.type == PestFactorType.technological).toList(),
    );
  }

  // Get all factors as a flat list
  List<PestFactor> get allFactors => [
        ...political,
        ...economic,
        ...social,
        ...technological,
      ];

  // Get factors by type
  List<PestFactor> getFactorsByType(PestFactorType type) {
    switch (type) {
      case PestFactorType.political:
        return political;
      case PestFactorType.economic:
        return economic;
      case PestFactorType.social:
        return social;
      case PestFactorType.technological:
        return technological;
    }
  }

  // Get total impact score for a factor type
  double getAverageImpact(PestFactorType type) {
    final factors = getFactorsByType(type);
    if (factors.isEmpty) return 0;
    return factors.map((f) => f.impact).reduce((a, b) => a + b) /
        factors.length;
  }
}

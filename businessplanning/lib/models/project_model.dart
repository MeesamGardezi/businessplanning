import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String documentId;
  final String title;
  final String description;
  final DateTime createdAt; // Add this field

  Project({required this.documentId, required this.title, required this.description, required this.createdAt});

  factory Project.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Project(
      documentId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(), // Convert Firestore Timestamp to DateTime
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(), // Set the creation time
    };
  }

  Project copyWith({String? documentId, String? title, String? description, DateTime? createdAt}) {
    return Project(
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
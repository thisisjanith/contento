import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final int number;
  final String title;
  final String employeeId;
  final String sourceBrief;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.number,
    required this.title,
    required this.employeeId,
    required this.sourceBrief,
    required this.createdAt,
  });

  factory Project.fromMap(String id, Map<String, dynamic> map) {
    return Project(
      id: id,
      number: map['number'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      sourceBrief: map['sourceBrief'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'number': number,
        'title': title,
        'employeeId': employeeId,
        'sourceBrief': sourceBrief,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// e.g. "Project #12 — Wildlife & Recovery Series"
  String get displayTitle => 'Project #$number — $title';
}

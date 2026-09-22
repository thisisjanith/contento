import 'package:cloud_firestore/cloud_firestore.dart';

enum PostStatus { pending, submitted, needsRevision, approved }

extension PostStatusX on PostStatus {
  String get label {
    switch (this) {
      case PostStatus.pending:
        return 'Pending';
      case PostStatus.submitted:
        return 'Submitted';
      case PostStatus.needsRevision:
        return 'Needs Revision';
      case PostStatus.approved:
        return 'Approved';
    }
  }

  /// Verb shown on the post-card action button on "My Project".
  String get actionLabel {
    switch (this) {
      case PostStatus.pending:
        return 'Open';
      case PostStatus.submitted:
        return 'View';
      case PostStatus.needsRevision:
        return 'Revise';
      case PostStatus.approved:
        return 'View';
    }
  }

  String get id {
    switch (this) {
      case PostStatus.pending:
        return 'pending';
      case PostStatus.submitted:
        return 'submitted';
      case PostStatus.needsRevision:
        return 'needsRevision';
      case PostStatus.approved:
        return 'approved';
    }
  }

  static PostStatus fromId(String? id) {
    switch (id) {
      case 'submitted':
        return PostStatus.submitted;
      case 'needsRevision':
        return PostStatus.needsRevision;
      case 'approved':
        return PostStatus.approved;
      default:
        return PostStatus.pending;
    }
  }
}

class Post {
  final String id;
  final int number;
  final String projectId;
  final String title;
  final DateTime dueDate;
  final PostStatus status;
  final String referenceLink;
  final List<String> factCheckNotes;
  final String styleNotes;
  final String caption;
  final String imageUrl;
  final String notes;
  final String feedback;
  final bool scheduled;
  final DateTime? submittedAt;

  const Post({
    required this.id,
    required this.number,
    required this.projectId,
    required this.title,
    required this.dueDate,
    required this.status,
    this.referenceLink = '',
    this.factCheckNotes = const [],
    this.styleNotes = '',
    this.caption = '',
    this.imageUrl = '',
    this.notes = '',
    this.feedback = '',
    this.scheduled = false,
    this.submittedAt,
  });

  factory Post.fromMap(String id, Map<String, dynamic> map) {
    return Post(
      id: id,
      number: map['number'] as int? ?? 0,
      projectId: map['projectId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: PostStatusX.fromId(map['status'] as String?),
      referenceLink: map['referenceLink'] as String? ?? '',
      factCheckNotes: (map['factCheckNotes'] as List?)?.cast<String>() ?? const [],
      styleNotes: map['styleNotes'] as String? ?? '',
      caption: map['caption'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      feedback: map['feedback'] as String? ?? '',
      scheduled: map['scheduled'] as bool? ?? false,
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'number': number,
        'projectId': projectId,
        'title': title,
        'dueDate': Timestamp.fromDate(dueDate),
        'status': status.id,
        'referenceLink': referenceLink,
        'factCheckNotes': factCheckNotes,
        'styleNotes': styleNotes,
        'caption': caption,
        'imageUrl': imageUrl,
        'notes': notes,
        'feedback': feedback,
        'scheduled': scheduled,
        'submittedAt': submittedAt == null ? null : Timestamp.fromDate(submittedAt!),
      };

  String get displayTitle => 'Post #$number — $title';

  bool get hasBrief => referenceLink.isNotEmpty;

  Post copyWith({
    PostStatus? status,
    String? caption,
    String? imageUrl,
    String? notes,
    String? feedback,
    bool? scheduled,
    DateTime? submittedAt,
  }) {
    return Post(
      id: id,
      number: number,
      projectId: projectId,
      title: title,
      dueDate: dueDate,
      status: status ?? this.status,
      referenceLink: referenceLink,
      factCheckNotes: factCheckNotes,
      styleNotes: styleNotes,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      feedback: feedback ?? this.feedback,
      scheduled: scheduled ?? this.scheduled,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}

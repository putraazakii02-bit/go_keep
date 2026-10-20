import 'dart:convert';

class Note {
  final String id;
  String title;
  String content;
  String? color; // hex color string or null for default
  bool isPinned;
  bool isArchived;
  bool isDeleted;
  List<String> labels;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? reminderAt;

  Note({
    required this.id,
    this.title = '',
    this.content = '',
    this.color,
    this.isPinned = false,
    this.isArchived = false,
    this.isDeleted = false,
    List<String>? labels,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.reminderAt,
  })  : labels = labels ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? color,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
    List<String>? labels,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reminderAt,
    bool clearColor = false,
    bool clearReminder = false,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: clearColor ? null : (color ?? this.color),
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      labels: labels ?? List.from(this.labels),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'labels': labels,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reminderAt': reminderAt?.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      color: json['color'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      reminderAt: json['reminderAt'] != null
          ? DateTime.parse(json['reminderAt'] as String)
          : null,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Note.fromJsonString(String jsonString) =>
      Note.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  bool get isEmpty => title.isEmpty && content.isEmpty;
}

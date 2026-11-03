import 'dart:convert';
import '../constants/gate_syllabus.dart';

class TaskItem {
  final String id;
  final String title;
  final String examTag;
  final String subject;
  final List<String> topics;
  final DateTime scheduledAt;
  final bool isCompleted;
  final DateTime createdAt;

  const TaskItem({
    required this.id,
    required this.title,
    this.examTag = GateSyllabus.gateCS,
    required this.subject,
    this.topics = const [],
    required this.scheduledAt,
    this.isCompleted = false,
    required this.createdAt,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    String? examTag,
    String? subject,
    List<String>? topics,
    DateTime? scheduledAt,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      examTag: examTag ?? this.examTag,
      subject: subject ?? this.subject,
      topics: topics ?? this.topics,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'exam_tag': examTag,
      'subject': subject,
      'topics': topics,
      'scheduled_at': scheduledAt.toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    List<String> parsedTopics = [];
    if (json['topics'] is List) {
      parsedTopics = (json['topics'] as List).map((e) => e.toString()).toList();
    }

    final rawExam = json['exam_tag'] as String? ?? GateSyllabus.gateCS;

    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Task',
      examTag: GateSyllabus.normalizeExam(rawExam),
      subject: json['subject'] as String? ?? 'General',
      topics: parsedTopics,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String serialize() => jsonEncode(toJson());

  static TaskItem deserialize(String str) =>
      TaskItem.fromJson(jsonDecode(str) as Map<String, dynamic>);
}

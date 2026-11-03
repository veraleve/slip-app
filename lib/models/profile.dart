import '../constants/gate_syllabus.dart';

class Profile {
  final String id;
  final String handle;
  final List<String> targetExams;
  final String? avatarGlyph;
  final int sharedCount;
  final int clearedCount;
  final int savedCount;
  final Map<String, double> topicMastery;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.handle,
    this.targetExams = const [GateSyllabus.gateCS],
    this.avatarGlyph,
    this.sharedCount = 0,
    this.clearedCount = 0,
    this.savedCount = 0,
    this.topicMastery = const {},
    required this.createdAt,
  });

  String get primaryExam => targetExams.isNotEmpty ? targetExams.first : GateSyllabus.gateCS;

  factory Profile.fromJson(Map<String, dynamic> json) {
    List<String> exams = [];
    if (json['target_exams'] is List) {
      exams = (json['target_exams'] as List).map((e) => GateSyllabus.normalizeExam(e.toString())).toList();
    } else if (json['target_exam'] is String && (json['target_exam'] as String).isNotEmpty) {
      exams = [GateSyllabus.normalizeExam(json['target_exam'] as String)];
    }
    if (exams.isEmpty) {
      exams = [GateSyllabus.gateCS];
    }

    return Profile(
      id: json['id'] as String,
      handle: json['handle'] as String? ?? 'peer_anonymous',
      targetExams: exams,
      avatarGlyph: json['avatar_glyph'] as String?,
      sharedCount: json['shared_count'] as int? ?? 0,
      clearedCount: json['cleared_count'] as int? ?? 0,
      savedCount: json['saved_count'] as int? ?? 0,
      topicMastery: json['topic_mastery'] != null
          ? Map<String, double>.from(json['topic_mastery'] as Map)
          : const {},
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'handle': handle,
      'target_exams': targetExams,
      'target_exam': primaryExam,
      'avatar_glyph': avatarGlyph,
      'shared_count': sharedCount,
      'cleared_count': clearedCount,
      'saved_count': savedCount,
      'topic_mastery': topicMastery,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

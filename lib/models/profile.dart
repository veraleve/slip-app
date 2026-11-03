class Profile {
  final String id;
  final String handle;
  final String targetExam;
  final String? avatarGlyph;
  final int sharedCount;
  final int clearedCount;
  final int savedCount;
  final Map<String, double> topicMastery; // e.g. 'Linear Algebra': 0.88
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.handle,
    this.targetExam = 'GATE CS 2027',
    this.avatarGlyph,
    this.sharedCount = 0,
    this.clearedCount = 0,
    this.savedCount = 0,
    this.topicMastery = const {},
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      handle: json['handle'] as String? ?? 'peer_anonymous',
      targetExam: json['target_exam'] as String? ?? 'GATE CS 2027',
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
      'target_exam': targetExam,
      'avatar_glyph': avatarGlyph,
      'shared_count': sharedCount,
      'cleared_count': clearedCount,
      'saved_count': savedCount,
      'topic_mastery': topicMastery,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

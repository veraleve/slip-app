class Slip {
  final String id;
  final String? authorId;
  final String topic;
  final String? subtopic;
  final String examTag;
  final String trapStatement;
  final String fixStatement;
  final List<String> imageUris;
  final String? scratchpadImageUrl;
  final String? voiceAudioUrl;
  final String? whiteboardVideoUrl;
  final int audioDurationSeconds;
  final int sameCount;
  final int clearedCount;
  final int keepCount;
  final DateTime createdAt;

  // Local interaction states
  final bool hasSaidSame;
  final bool hasKept;
  final bool hasCleared;
  final bool isFixRevealed;

  const Slip({
    required this.id,
    this.authorId,
    required this.topic,
    this.subtopic,
    this.examTag = 'GATE CS 2027',
    required this.trapStatement,
    required this.fixStatement,
    this.imageUris = const [],
    this.scratchpadImageUrl,
    this.voiceAudioUrl,
    this.whiteboardVideoUrl,
    this.audioDurationSeconds = 0,
    this.sameCount = 0,
    this.clearedCount = 0,
    this.keepCount = 0,
    required this.createdAt,
    this.hasSaidSame = false,
    this.hasKept = false,
    this.hasCleared = false,
    this.isFixRevealed = false,
  });

  factory Slip.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['image_uris'] is List) {
      images = (json['image_uris'] as List).map((e) => e.toString()).toList();
    } else if (json['scratchpad_image_url'] != null && (json['scratchpad_image_url'] as String).isNotEmpty) {
      images = [json['scratchpad_image_url'] as String];
    }

    return Slip(
      id: json['id'] as String,
      authorId: json['author_id'] as String?,
      topic: json['topic'] as String? ?? 'General',
      subtopic: json['subtopic'] as String?,
      examTag: json['exam_tag'] as String? ?? 'GATE CS 2027',
      trapStatement: json['trap_statement'] as String? ?? '',
      fixStatement: json['fix_statement'] as String? ?? '',
      imageUris: images,
      scratchpadImageUrl: images.isNotEmpty ? images.first : null,
      voiceAudioUrl: json['voice_audio_url'] as String?,
      whiteboardVideoUrl: json['whiteboard_video_url'] as String?,
      audioDurationSeconds: json['audio_duration_seconds'] as int? ?? 0,
      sameCount: json['same_count'] as int? ?? 0,
      clearedCount: json['cleared_count'] as int? ?? 0,
      keepCount: json['keep_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'topic': topic,
      'subtopic': subtopic,
      'exam_tag': examTag,
      'trap_statement': trapStatement,
      'fix_statement': fixStatement,
      'image_uris': imageUris,
      'scratchpad_image_url': imageUris.isNotEmpty ? imageUris.first : scratchpadImageUrl,
      'voice_audio_url': voiceAudioUrl,
      'whiteboard_video_url': whiteboardVideoUrl,
      'audio_duration_seconds': audioDurationSeconds,
      'same_count': sameCount,
      'cleared_count': clearedCount,
      'keep_count': keepCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Slip copyWith({
    String? id,
    String? authorId,
    String? topic,
    String? subtopic,
    String? examTag,
    String? trapStatement,
    String? fixStatement,
    List<String>? imageUris,
    String? scratchpadImageUrl,
    String? voiceAudioUrl,
    String? whiteboardVideoUrl,
    int? audioDurationSeconds,
    int? sameCount,
    int? clearedCount,
    int? keepCount,
    DateTime? createdAt,
    bool? hasSaidSame,
    bool? hasKept,
    bool? hasCleared,
    bool? isFixRevealed,
  }) {
    return Slip(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      examTag: examTag ?? this.examTag,
      trapStatement: trapStatement ?? this.trapStatement,
      fixStatement: fixStatement ?? this.fixStatement,
      imageUris: imageUris ?? this.imageUris,
      scratchpadImageUrl: scratchpadImageUrl ?? this.scratchpadImageUrl,
      voiceAudioUrl: voiceAudioUrl ?? this.voiceAudioUrl,
      whiteboardVideoUrl: whiteboardVideoUrl ?? this.whiteboardVideoUrl,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      sameCount: sameCount ?? this.sameCount,
      clearedCount: clearedCount ?? this.clearedCount,
      keepCount: keepCount ?? this.keepCount,
      createdAt: createdAt ?? this.createdAt,
      hasSaidSame: hasSaidSame ?? this.hasSaidSame,
      hasKept: hasKept ?? this.hasKept,
      hasCleared: hasCleared ?? this.hasCleared,
      isFixRevealed: isFixRevealed ?? this.isFixRevealed,
    );
  }
}

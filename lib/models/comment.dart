class SlipComment {
  final String id;
  final String slipId;
  final String authorHandle;
  final String body;
  final bool isAcceptedAnswer;
  final DateTime createdAt;

  const SlipComment({
    required this.id,
    required this.slipId,
    required this.authorHandle,
    required this.body,
    this.isAcceptedAnswer = false,
    required this.createdAt,
  });

  factory SlipComment.fromJson(Map<String, dynamic> json) {
    return SlipComment(
      id: json['id'] as String,
      slipId: json['slip_id'] as String,
      authorHandle: json['author_handle'] as String? ?? 'peer',
      body: json['body'] as String? ?? '',
      isAcceptedAnswer: json['is_accepted_answer'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slip_id': slipId,
      'author_handle': authorHandle,
      'body': body,
      'is_accepted_answer': isAcceptedAnswer,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class InterviewQuestion {
  const InterviewQuestion({
    required this.text,
    required this.hint,
    required this.skill,
  });

  final String text;
  final String hint;
  final String skill;

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) {
    return InterviewQuestion(
      text: json['q'] as String,
      hint: json['hint'] as String,
      skill: json['skill'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'q': text,
    'hint': hint,
    'skill': skill,
  };
}

class InterviewSession {
  const InterviewSession({
    required this.id,
    required this.career,
    required this.mode,
    required this.difficulty,
    required this.startedAt,
    required this.durationSeconds,
    required this.responses,
    this.feedback,
  });

  final String id;
  final String career;
  final String mode;
  final String difficulty;
  final DateTime startedAt;
  final int durationSeconds;
  final List<Map<String, dynamic>> responses;
  final Map<String, dynamic>? feedback;

  int get overall => (feedback?['overall'] as num?)?.toInt() ?? 0;

  factory InterviewSession.fromJson(Map<String, dynamic> json) {
    return InterviewSession(
      id: json['id'] as String,
      career: json['career'] as String? ?? 'Chưa rõ',
      mode: json['mode'] as String? ?? 'intern',
      difficulty: json['difficulty'] as String? ?? 'Vừa',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      responses: (json['responses'] as List? ?? const [])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(),
      feedback: json['feedback'] is Map
          ? Map<String, dynamic>.from(json['feedback'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'career': career,
    'mode': mode,
    'difficulty': difficulty,
    'startedAt': startedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'responses': responses,
    if (feedback != null) 'feedback': feedback,
  };
}

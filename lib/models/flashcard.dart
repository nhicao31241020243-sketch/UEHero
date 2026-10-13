enum FlashcardType {
  concept,
  howto,
  query,
  scenario,
  interview,
  tip;

  String get label => switch (this) {
    concept => 'Khái niệm',
    howto => 'Cách làm',
    query => 'Truy vấn',
    scenario => 'Tình huống',
    interview => 'Phỏng vấn',
    tip => 'Mẹo',
  };

  static FlashcardType fromName(String? value) =>
      FlashcardType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => FlashcardType.concept,
      );
}

enum FlashcardCodeLanguage { none, sql, dax }

enum FlashcardDifficulty {
  easy,
  medium,
  hard;

  String get label => switch (this) {
    easy => 'Dễ',
    medium => 'Vừa',
    hard => 'Khó',
  };

  static FlashcardDifficulty fromName(String? value) =>
      FlashcardDifficulty.values.firstWhere(
        (difficulty) => difficulty.name == value,
        orElse: () => FlashcardDifficulty.medium,
      );
}

class Flashcard {
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.type,
    required this.front,
    required this.back,
    this.codeLanguage = FlashcardCodeLanguage.none,
    this.example = '',
    this.tags = const [],
    this.quizOptions = const [],
    this.correctChoice,
    this.subTopic = '',
    this.difficulty = FlashcardDifficulty.medium,
    this.isFavorite = false,
    this.box = 0,
    this.nextReviewAt,
  });

  final String id;
  final String deckId;
  final FlashcardType type;
  final String front;
  final String back;
  final FlashcardCodeLanguage codeLanguage;
  final String example;
  final List<String> tags;
  final List<String> quizOptions;
  final int? correctChoice;
  final String subTopic;
  final FlashcardDifficulty difficulty;
  final bool isFavorite;
  final int box;
  final DateTime? nextReviewAt;

  Flashcard copyWith({
    String? id,
    String? deckId,
    FlashcardType? type,
    String? front,
    String? back,
    FlashcardCodeLanguage? codeLanguage,
    String? example,
    List<String>? tags,
    List<String>? quizOptions,
    int? correctChoice,
    String? subTopic,
    FlashcardDifficulty? difficulty,
    bool? isFavorite,
    int? box,
    DateTime? nextReviewAt,
    bool clearNextReviewAt = false,
  }) => Flashcard(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    type: type ?? this.type,
    front: front ?? this.front,
    back: back ?? this.back,
    codeLanguage: codeLanguage ?? this.codeLanguage,
    example: example ?? this.example,
    tags: tags ?? this.tags,
    quizOptions: quizOptions ?? this.quizOptions,
    correctChoice: correctChoice ?? this.correctChoice,
    subTopic: subTopic ?? this.subTopic,
    difficulty: difficulty ?? this.difficulty,
    isFavorite: isFavorite ?? this.isFavorite,
    box: box ?? this.box,
    nextReviewAt: clearNextReviewAt ? null : nextReviewAt ?? this.nextReviewAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'deckId': deckId,
    'type': type.name,
    'front': front,
    'back': back,
    'codeLanguage': codeLanguage.name,
    'example': example,
    'tags': tags,
    'quizOptions': quizOptions,
    'correctChoice': correctChoice,
    'subTopic': subTopic,
    'difficulty': difficulty.name,
    'isFavorite': isFavorite,
    'box': box,
    'nextReviewAt': nextReviewAt?.toIso8601String(),
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    id: json['id'] as String,
    deckId: json['deckId'] as String,
    type: FlashcardType.fromName(json['type'] as String?),
    front: json['front'] as String,
    back: json['back'] as String,
    codeLanguage: FlashcardCodeLanguage.values.firstWhere(
      (language) => language.name == json['codeLanguage'],
      orElse: () => FlashcardCodeLanguage.none,
    ),
    example: json['example'] as String? ?? '',
    tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
    quizOptions: (json['quizOptions'] as List<dynamic>? ?? const [])
        .cast<String>(),
    correctChoice: (json['correctChoice'] as num?)?.toInt(),
    subTopic: json['subTopic'] as String? ?? '',
    difficulty: FlashcardDifficulty.fromName(json['difficulty'] as String?),
    isFavorite: json['isFavorite'] as bool? ?? false,
    box: (json['box'] as num?)?.toInt() ?? 0,
    nextReviewAt: DateTime.tryParse(json['nextReviewAt'] as String? ?? ''),
  );
}

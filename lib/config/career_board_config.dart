import 'career_roadmap_config.dart';

enum BoardTaskKind {
  flashcards,
  library,
  cvScore,
  interview,
  mentor,
  event,
  jobReadiness,
  studyBuddy,
}

const boardZoneNames = <String>[
  'Sao Thủy',
  'Sao Kim',
  'Sao Hỏa',
  'Sao Mộc',
  'Sao Thổ',
  'Hải Vương Tinh',
];

/// Mỗi vùng có đúng 5 ô: (loại nhiệm vụ, mốc cần đạt, Stardust, bắt buộc).
const _zoneTemplates = <List<(BoardTaskKind, int, int, bool)>>[
  [
    (BoardTaskKind.flashcards, 5, 30, true),
    (BoardTaskKind.library, 1, 20, true),
    (BoardTaskKind.cvScore, 60, 40, true),
    (BoardTaskKind.jobReadiness, 1, 20, true),
    (BoardTaskKind.flashcards, 10, 35, true),
  ],
  [
    (BoardTaskKind.library, 2, 25, true),
    (BoardTaskKind.mentor, 1, 40, true),
    (BoardTaskKind.flashcards, 15, 35, true),
    (BoardTaskKind.event, 1, 30, true),
    (BoardTaskKind.interview, 1, 40, true),
  ],
  [
    (BoardTaskKind.cvScore, 75, 50, true),
    (BoardTaskKind.interview, 2, 45, true),
    (BoardTaskKind.library, 3, 30, true),
    (BoardTaskKind.flashcards, 20, 40, true),
    (BoardTaskKind.studyBuddy, 1, 25, false),
  ],
  [
    (BoardTaskKind.mentor, 2, 45, true),
    (BoardTaskKind.event, 2, 30, true),
    (BoardTaskKind.flashcards, 25, 45, true),
    (BoardTaskKind.library, 4, 35, true),
    (BoardTaskKind.interview, 3, 55, true),
  ],
  [
    (BoardTaskKind.cvScore, 85, 60, true),
    (BoardTaskKind.flashcards, 30, 50, true),
    (BoardTaskKind.mentor, 3, 55, true),
    (BoardTaskKind.event, 3, 35, true),
    (BoardTaskKind.library, 5, 40, true),
  ],
  [
    (BoardTaskKind.flashcards, 40, 60, true),
    (BoardTaskKind.library, 6, 45, true),
    (BoardTaskKind.event, 4, 40, true),
    (BoardTaskKind.interview, 4, 60, true),
    (BoardTaskKind.jobReadiness, 1, 25, true),
  ],
];

const boardTilesPerZone = 5;

class BoardTile {
  const BoardTile({
    required this.id,
    required this.zoneIndex,
    required this.kind,
    required this.target,
    required this.stardust,
    required this.required,
    required this.title,
    required this.description,
  });

  final String id;
  final int zoneIndex;
  final BoardTaskKind kind;
  final int target;
  final int stardust;
  final bool required;
  final String title;
  final String description;
}

class BoardZone {
  const BoardZone({
    required this.index,
    required this.planetName,
    required this.skillHint,
    required this.tiles,
  });

  final int index;
  final String planetName;
  final String skillHint;
  final List<BoardTile> tiles;

  List<BoardTile> get requiredTiles =>
      tiles.where((tile) => tile.required).toList(growable: false);
}

class CareerBoard {
  const CareerBoard({required this.role, required this.zones});

  final String role;
  final List<BoardZone> zones;

  List<BoardTile> get tiles => [for (final zone in zones) ...zone.tiles];
}

CareerBoard careerBoardFor(String role) {
  final milestones = roadmapFor(role);
  final count = milestones.length < _zoneTemplates.length
      ? milestones.length
      : _zoneTemplates.length;
  final zones = <BoardZone>[];
  for (var zoneIndex = 0; zoneIndex < count; zoneIndex++) {
    final tiles = <BoardTile>[];
    final specs = _zoneTemplates[zoneIndex];
    for (var position = 0; position < specs.length; position++) {
      final (kind, target, stardust, required) = specs[position];
      tiles.add(
        BoardTile(
          id: 'z${zoneIndex}t$position',
          zoneIndex: zoneIndex,
          kind: kind,
          target: target,
          stardust: stardust,
          required: required,
          title: _titleFor(kind, target),
          description: _descriptionFor(kind, target),
        ),
      );
    }
    zones.add(
      BoardZone(
        index: zoneIndex,
        planetName: '${boardZoneNames[zoneIndex]} · ${milestones[zoneIndex].shortLabel}',
        skillHint: milestones[zoneIndex].title,
        tiles: tiles,
      ),
    );
  }
  return CareerBoard(role: role, zones: zones);
}

String _titleFor(BoardTaskKind kind, int target) => switch (kind) {
  BoardTaskKind.flashcards => 'Thuộc $target thẻ flashcard',
  BoardTaskKind.library => 'Mở $target học liệu khác nhau',
  BoardTaskKind.cvScore => 'Đạt $target điểm CV Check',
  BoardTaskKind.interview => 'Hoàn thành $target buổi Phỏng vấn thử',
  BoardTaskKind.mentor => 'Hoàn thành $target buổi UEH Mentor',
  BoardTaskKind.event => 'Thêm $target sự kiện vào kế hoạch',
  BoardTaskKind.jobReadiness => 'Xem độ sẵn sàng ở Job Match',
  BoardTaskKind.studyBuddy => 'Hỏi Study Buddy bằng ảnh bài thật',
};

String _descriptionFor(BoardTaskKind kind, int target) => switch (kind) {
  BoardTaskKind.flashcards =>
    'Ôn trong Skill Drills cho đến khi $target thẻ đạt ô 3 trở lên.',
  BoardTaskKind.library => 'Mở $target học liệu khác nhau trong thư viện.',
  BoardTaskKind.cvScore =>
    'Chấm CV ở CV Check và đạt tối thiểu $target điểm trong một lần kiểm tra mới.',
  BoardTaskKind.interview => 'Làm $target buổi phỏng vấn thử trong mục Phỏng vấn.',
  BoardTaskKind.mentor => 'Hoàn thành $target buổi tư vấn với mentor.',
  BoardTaskKind.event =>
    'Thêm $target sự kiện hoặc cuộc thi vào kế hoạch trong Events.',
  BoardTaskKind.jobReadiness =>
    'Mở Job Match để xem độ sẵn sàng theo các nhiệm vụ đã xong.',
  BoardTaskKind.studyBuddy =>
    'Chụp một bài tập thật để hỏi Study Buddy. Nhiệm vụ phụ, không bắt buộc.',
};

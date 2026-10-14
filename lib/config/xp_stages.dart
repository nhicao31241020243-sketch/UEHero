class XpStage {
  const XpStage({
    required this.id,
    required this.name,
    required this.requiredXp,
    required this.unlockedFeatures,
  });

  final int id;
  final String name;
  final int requiredXp;
  final List<String> unlockedFeatures;
}

const bool demoMode = false;

const List<XpStage> xpStages = [
  XpStage(
    id: 1,
    name: 'Khởi động',
    requiredXp: 0,
    unlockedFeatures: ['CV', 'Flashcard', 'Tay'],
  ),
  XpStage(
    id: 2,
    name: 'Xây nền',
    requiredXp: 100,
    unlockedFeatures: ['Cuộc thi', 'Sự kiện'],
  ),
  XpStage(
    id: 3,
    name: 'Bứt phá',
    requiredXp: 300,
    unlockedFeatures: ['Mentor', 'Khóa học'],
  ),
  XpStage(
    id: 4,
    name: 'Sẵn sàng',
    requiredXp: 600,
    unlockedFeatures: ['Cơ hội nghề nghiệp'],
  ),
];

XpStage stageForXp(int xp) {
  var current = xpStages.first;
  for (final stage in xpStages) {
    if (xp >= stage.requiredXp) current = stage;
  }
  return current;
}

double stageProgressForXp(int xp) {
  final current = stageForXp(xp);
  final nextIndex = xpStages.indexOf(current) + 1;
  if (nextIndex >= xpStages.length) return 1;
  final next = xpStages[nextIndex];
  return ((xp - current.requiredXp) / (next.requiredXp - current.requiredXp))
      .clamp(0.0, 1.0);
}

List<String> featuresUnlockedForXp(int xp, {required bool demoMode}) {
  if (demoMode) {
    return List.unmodifiable(
      xpStages.expand((stage) => stage.unlockedFeatures).toSet(),
    );
  }
  final current = stageForXp(xp);
  return List.unmodifiable(
    xpStages
        .where((stage) => stage.id <= current.id)
        .expand((stage) => stage.unlockedFeatures)
        .toSet(),
  );
}

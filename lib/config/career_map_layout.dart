import 'career_progress_config.dart';

class StoneStep {
  const StoneStep({
    required this.index,
    required this.progress,
    required this.x,
    required this.y,
    this.milestoneId,
  });

  final int index;
  final int progress;
  final double x;
  final double y;
  final String? milestoneId;

  bool get isMilestone => milestoneId != null;
}

const int careerMapStoneCount = 29;

List<StoneStep> buildCareerMapSteps({
  int stoneCount = careerMapStoneCount,
  List<CareerNodeConfig> nodes = careerNodes,
}) {
  if (stoneCount < 2) {
    throw ArgumentError.value(stoneCount, 'stoneCount', 'Must be at least 2.');
  }
  final maxProgress = nodes.last.threshold;
  final milestoneByIndex = <int, String>{
    for (final node in nodes)
      (node.threshold * (stoneCount - 1) / maxProgress).round(): node.id,
  };
  final steps = <StoneStep>[];
  for (var index = 0; index < stoneCount; index++) {
    final progress = (maxProgress * index / (stoneCount - 1)).round();
    final wave = index / (stoneCount - 1);
    final x = 0.5 + 0.31 * _sineWave(wave * 2.7);
    final y = 1 - wave;
    steps.add(
      StoneStep(
        index: index,
        progress: progress,
        x: x.clamp(0.12, 0.88),
        y: y,
        milestoneId: milestoneByIndex[index],
      ),
    );
  }
  return steps;
}

int stoneIndexForPoints(int points, List<StoneStep> steps) {
  var current = steps.first.index;
  for (final step in steps) {
    if (step.progress <= points) current = step.index;
  }
  return current;
}

double _sineWave(double value) {
  final segment = value % 1;
  return segment < 0.5
      ? (segment * 4) - 1
      : 3 - (segment * 4);
}

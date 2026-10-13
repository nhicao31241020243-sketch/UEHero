import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/config/career_map_layout.dart';

void main() {
  test('generates a rising S-shaped stone path with milestone markers', () {
    final steps = buildCareerMapSteps();

    expect(steps, hasLength(careerMapStoneCount));
    expect(steps.first.y, 1);
    expect(steps.last.y, 0);
    expect(steps.every((step) => step.x >= 0.12 && step.x <= 0.88), isTrue);
    expect(
      steps.where((step) => step.isMilestone).map((step) => step.milestoneId),
      containsAll([
        'launch-pad',
        'foundation',
        'skill-forge',
        'portfolio-station',
        'interview-orbit',
        'job-galaxy',
      ]),
    );
  });

  test('maps points to the latest reachable stone', () {
    final steps = buildCareerMapSteps();

    expect(stoneIndexForPoints(0, steps), 0);
    expect(stoneIndexForPoints(50, steps), greaterThan(0));
    expect(
      stoneIndexForPoints(350, steps),
      steps.length - 1,
    );
  });
}

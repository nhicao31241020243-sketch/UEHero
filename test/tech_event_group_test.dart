import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/models/tech_event.dart';

void main() {
  group('techEventGroup', () {
    test('classifies hackathons before other categories', () {
      expect(
        techEventGroup('UEH Game Jam', 'Competition'),
        TechEventGroup.hackathon,
      );
    });

    test('recognizes competition and program keywords', () {
      expect(
        techEventGroup('Code Challenge', 'Technology'),
        TechEventGroup.competition,
      );
      expect(
        techEventGroup('Future Talent Camp', 'Career'),
        TechEventGroup.program,
      );
    });

    test('defaults unmatched events to workshops', () {
      expect(
        techEventGroup('Career Orientation Talk', 'Talk'),
        TechEventGroup.program,
      );
      expect(
        techEventGroup('Product Discovery', 'Learning'),
        TechEventGroup.workshop,
      );
    });
  });
}

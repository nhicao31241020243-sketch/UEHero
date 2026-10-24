import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/config/hub_visuals.dart';

void main() {
  group('PlanetAssets', () {
    test('maps hub cards to the requested cartoon planet artwork', () {
      const titles = [
        'Job Match',
        'Book Swap',
        'Study Buddy',
        'Weekly Plan',
        'UEH Mentor',
        'Skill Drills',
        'CV Check',
        'Events',
      ];
      final planets = titles.map(PlanetAssets.planetForCardTitle).toSet();

      expect(planets, hasLength(8));
      expect(titles.map(PlanetAssets.forCardTitle).toList(), [
        'assets/images/planets/mercury.png',
        'assets/images/planets/venus.png',
        'assets/images/planets/earth.png',
        'assets/images/planets/mars.png',
        'assets/images/planets/jupiter.png',
        'assets/images/planets/saturn.png',
        'assets/images/planets/uranus.png',
        'assets/images/planets/mercury.png',
      ]);
      expect(PlanetAssets.planetForCardTitle('Study Buddy'), 'earth');
      expect(PlanetAssets.planetForCardTitle('Events'), 'events');
    });

    test('keeps every card rotation between 8 and 14 seconds', () {
      expect(PlanetAssets.rotationSeconds, hasLength(8));
      expect(
        PlanetAssets.rotationSeconds.values.every(
          (seconds) => seconds >= 8 && seconds <= 14,
        ),
        isTrue,
      );
      expect(PlanetAssets.rotationSeconds.values.toSet(), hasLength(8));
    });
  });
}

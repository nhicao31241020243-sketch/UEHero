import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/config/deck_visuals.dart';
import 'package:uehero/data/flashcard_seed.dart';

void main() {
  test('seed decks receive stable, distinct, high-contrast colors', () {
    final firstPass = DeckPalette.assign(flashcardSeedDecks);
    final secondPass = DeckPalette.assign(flashcardSeedDecks);

    expect(firstPass, secondPass);
    expect(firstPass.values.toSet().length, flashcardSeedDecks.length);
    for (final color in firstPass.values) {
      final textColor = DeckPalette.foreground(color);
      final luminance = color.computeLuminance();
      final textLuminance = textColor.computeLuminance();
      final contrast =
          (luminance + 0.05) / (textLuminance + 0.05) >
              (textLuminance + 0.05) / (luminance + 0.05)
          ? (luminance + 0.05) / (textLuminance + 0.05)
          : (textLuminance + 0.05) / (luminance + 0.05);
      expect(contrast, greaterThanOrEqualTo(4.5));
    }
  });

  test('seed decks have a topic-specific emoji mapping', () {
    for (final deck in flashcardSeedDecks) {
      expect(DeckIconMap.emojiFor(deck), isNot(DeckIconMap.defaultEmoji));
    }
  });
}

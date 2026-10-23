import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/config/career_board_config.dart';
import 'package:uehero/services/career_board_service.dart';

void main() {
  final board = careerBoardFor('Business Analyst');

  group('pure board helpers', () {
    test('mascot index follows completed tile count and stays in range', () {
      expect(boardMascotIndex(0, 36), 0);
      expect(boardMascotIndex(5, 36), 5);
      expect(boardMascotIndex(99, 36), 35);
      expect(boardMascotIndex(3, 0), 0);
    });

    test('readiness is 0 when nothing is done and 1 when all required done', () {
      expect(boardReadiness(board, <String>{}), 0);
      final allRequired = {
        for (final tile in board.tiles)
          if (tile.required) tile.id,
      };
      expect(boardReadiness(board, allRequired), 1);
    });

    test('zone unlocks only when every required tile is done', () {
      final zone = board.zones.first;
      final required = zone.requiredTiles.map((tile) => tile.id).toSet();
      expect(boardZoneUnlocked(zone, required), isTrue);
      expect(boardZoneUnlocked(zone, {...required}..remove(required.first)),
          isFalse);
    });

    test('tilesReachedBy returns only eligible tiles that are not done yet', () {
      final progress = BoardProgress(flashcardsMastered: 5);
      final firstZoneFlashcard = board.zones.first.tiles.firstWhere(
        (tile) => tile.kind == BoardTaskKind.flashcards && tile.target == 5,
      );
      final reached = tilesReachedBy(board, progress, <String>{});
      expect(reached, contains(firstZoneFlashcard.id));
      expect(
        reached.every((id) => board.tiles.any((tile) => tile.id == id)),
        isTrue,
      );

      final alreadyDone = tilesReachedBy(
        board,
        progress,
        {firstZoneFlashcard.id},
      );
      expect(alreadyDone, isNot(contains(firstZoneFlashcard.id)));
    });

    test('legacy zone progress migrates to every tile of those zones', () {
      final migrated = migrateLegacyDone(board, const [0, 1]);
      expect(migrated.length, board.zones[0].tiles.length +
          board.zones[1].tiles.length);
      expect(
        migrated,
        containsAll(board.zones[0].tiles.map((tile) => tile.id)),
      );
      expect(migrateLegacyDone(board, const []), isEmpty);
    });

    test('current zone is the first zone not fully unlocked', () {
      expect(boardCurrentZone(board, <String>{})?.index, 0);
      final firstZoneDone = board.zones.first.requiredTiles
          .map((tile) => tile.id)
          .toSet();
      expect(boardCurrentZone(board, firstZoneDone)?.index, 1);
      final everything = board.tiles.map((tile) => tile.id).toSet();
      expect(boardCurrentZone(board, everything)?.index, board.zones.last.index);
    });

    test('zone matches events that share a keyword with its skill hint', () {
      const zone = BoardZone(
        index: 0,
        planetName: 'Test',
        skillHint: 'SQL Advanced (JOIN, Subquery)',
        tiles: [],
      );
      expect(boardZoneMatchesTags(zone, const ['SQL', 'Data']), isTrue);
      expect(boardZoneMatchesTags(zone, const ['Marketing']), isFalse);
      expect(boardZoneMatchesTags(zone, const <String>[]), isFalse);
    });

    test('weekly task id embeds the role and tile id', () {
      final tile = board.tiles.first;
      final id = boardWeeklyTaskId('Business Analyst', tile);
      expect(id, startsWith('board:Business Analyst:'));
      expect(id, endsWith(tile.id));
    });
  });

  group('CareerBoardService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CareerBoardService.instance.resetForTests();
    });

    test('completing a tile awards Stardust only once', () async {
      final service = CareerBoardService.instance;
      await service.initialize(preferences: await SharedPreferences.getInstance());
      final tile = board.tiles.first;

      final first = await service.completeTile('Business Analyst', tile);
      final second = await service.completeTile('Business Analyst', tile);

      expect(first, greaterThan(0));
      expect(second, 0);
      expect(
        service.doneTileIds('Business Analyst'),
        contains(tile.id),
      );
    });
  });
}

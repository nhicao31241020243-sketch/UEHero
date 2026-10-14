import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../models/character_data.dart';

enum MascotRole { primary, aiCompanion }

class MascotSelection {
  const MascotSelection({this.primary, this.aiCompanion});

  final CharacterData? primary;
  final CharacterData? aiCompanion;

  bool get isComplete => primary != null && aiCompanion != null;
}

class MascotSelectionStore {
  MascotSelectionStore._();

  static final instance = MascotSelectionStore._();
  static final ValueNotifier<MascotSelection?> selectionChanges = ValueNotifier(
    null,
  );

  static const _primaryKey = 'primary_mascot_id_v1';
  static const _aiCompanionKey = 'ai_companion_mascot_id_v1';
  static const _migrationKey = 'mascot_roles_migrated_v1';
  static const _legacyKey = 'selected_mascot';

  static List<CharacterData> charactersFor(MascotRole role) => characterData
      .where(
        (character) => switch (role) {
          MascotRole.primary => character.modelPath.startsWith(
            'assets/3d/Space_',
          ),
          MascotRole.aiCompanion => character.modelPath.startsWith(
            'assets/3d/animal-',
          ),
        },
      )
      .toList(growable: false);

  Future<void> migrateLegacySelection({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) ?? false) return;

    if (!prefs.containsKey(_primaryKey) &&
        !prefs.containsKey(_aiCompanionKey)) {
      final legacy = characterById(prefs.getString(_legacyKey));
      if (legacy != null) {
        final role = legacy.modelPath.startsWith('assets/3d/Space_')
            ? MascotRole.primary
            : MascotRole.aiCompanion;
        await prefs.setString(_keyFor(role), legacy.id);
      }
    }
    await prefs.setBool(_migrationKey, true);
  }

  Future<MascotSelection> read({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await migrateLegacySelection(preferences: prefs);
    final selection = MascotSelection(
      primary: characterById(prefs.getString(_primaryKey)),
      aiCompanion: characterById(prefs.getString(_aiCompanionKey)),
    );
    _publish(selection);
    return selection;
  }

  Future<void> save(
    MascotSelection selection, {
    SharedPreferences? preferences,
  }) async {
    if (!selection.isComplete) {
      throw ArgumentError(
        'Cả mascot chính và bạn đồng hành đều cần được chọn.',
      );
    }
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(_primaryKey, selection.primary!.id);
    await prefs.setString(_aiCompanionKey, selection.aiCompanion!.id);
    _publish(selection);
  }

  Future<String?> idFor(
    MascotRole role, {
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await migrateLegacySelection(preferences: prefs);
    return prefs.getString(_keyFor(role));
  }

  static String _keyFor(MascotRole role) => switch (role) {
    MascotRole.primary => _primaryKey,
    MascotRole.aiCompanion => _aiCompanionKey,
  };

  void _publish(MascotSelection selection) {
    final current = selectionChanges.value;
    if (current?.primary?.id == selection.primary?.id &&
        current?.aiCompanion?.id == selection.aiCompanion?.id) {
      return;
    }
    selectionChanges.value = selection;
  }
}

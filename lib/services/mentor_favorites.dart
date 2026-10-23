import 'package:shared_preferences/shared_preferences.dart';

class MentorFavorites {
  const MentorFavorites._();

  static const _key = 'mentor_favorites';

  static Future<Set<String>> load() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_key) ?? const []).toSet();
  }

  static Future<void> save(Set<String> ids) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key, ids.toList()..sort());
  }
}

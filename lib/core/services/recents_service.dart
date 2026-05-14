// lib/core/services/recents_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class RecentsService {
  RecentsService._();
  static final RecentsService instance = RecentsService._();

  late SharedPreferences _prefs;
  static const _recentsKey = 'recently_visited_monuments';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  List<String> getRecents() {
    return _prefs.getStringList(_recentsKey) ?? [];
  }

  Future<void> addRecent(String id) async {
    final recents = getRecents();
    // Remove if it already exists to move it to the front
    recents.remove(id);
    // Insert at the beginning
    recents.insert(0, id);
    // Keep a maximum of 10 recents
    if (recents.length > 10) {
      recents.removeLast();
    }
    await _prefs.setStringList(_recentsKey, recents);
  }
}

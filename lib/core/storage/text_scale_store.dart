import 'package:shared_preferences/shared_preferences.dart';

class TextScaleStore {
  static const _key = 'chrysotile_text_scale_v1';

  static const normal = 1.0;
  static const larger = 1.2;
  static const largest = 1.4;

  static const levels = [normal, larger, largest];

  Future<double> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_key);
    if (value == null) {
      return normal;
    }
    if (levels.contains(value)) {
      return value;
    }
    // Older saved values (1.15 / 1.3) map to the nearest current level.
    var nearest = normal;
    for (final level in levels) {
      if ((level - value).abs() < (nearest - value).abs()) {
        nearest = level;
      }
    }
    return nearest;
  }

  Future<void> save(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, value);
  }
}

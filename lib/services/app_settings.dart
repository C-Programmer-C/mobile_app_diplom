import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  static const _keyFontScale = 'app_font_scale';

  double _fontScale = 1.0;

  double get fontScale => _fontScale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getDouble(_keyFontScale);
    if (v != null && v >= 0.85 && v <= 1.35) {
      _fontScale = v;
      notifyListeners();
    }
  }

  Future<void> setFontScale(double value) async {
    final clamped = value.clamp(0.85, 1.35);
    _fontScale = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontScale, clamped);
  }
}

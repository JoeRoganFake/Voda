import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Defines the visual color scheme for the water background.
class BackgroundTheme {
  final String id;
  final String label;
  final Color appBackground;
  final List<Color> waterGradient;

  const BackgroundTheme({
    required this.id,
    required this.label,
    required this.appBackground,
    required this.waterGradient,
  });
}

/// All available background themes.
const List<BackgroundTheme> kBackgroundThemes = [
  BackgroundTheme(
    id: 'ocean',
    label: 'Ocean',
    appBackground: Color(0xFF0F172A),
    waterGradient: [
      Color(0xFF1E3A8A),
      Color(0xFF1C44B3),
      Color(0xFF1E63DB),
    ],
  ),
  BackgroundTheme(
    id: 'teal',
    label: 'Teal',
    appBackground: Color(0xFF0D1F1F),
    waterGradient: [
      Color(0xFF134E4A),
      Color(0xFF0F766E),
      Color(0xFF14B8A6),
    ],
  ),
  BackgroundTheme(
    id: 'purple',
    label: 'Purple',
    appBackground: Color(0xFF0F0A1E),
    waterGradient: [
      Color(0xFF3B0764),
      Color(0xFF6D28D9),
      Color(0xFF8B5CF6),
    ],
  ),
  BackgroundTheme(
    id: 'sunset',
    label: 'Sunset',
    appBackground: Color(0xFF1A0A00),
    waterGradient: [
      Color(0xFF7C2D12),
      Color(0xFFEA580C),
      Color(0xFFFB923C),
    ],
  ),
];

class BackgroundManager extends ChangeNotifier {
  static const String _prefKey = 'backgroundThemeId';

  BackgroundTheme _current = kBackgroundThemes.first;

  BackgroundTheme get current => _current;
  List<BackgroundTheme> get themes => kBackgroundThemes;

  BackgroundManager() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefKey);
    if (savedId != null) {
      final found = kBackgroundThemes.where((t) => t.id == savedId);
      if (found.isNotEmpty) {
        _current = found.first;
        notifyListeners();
      }
    }
  }

  Future<void> setTheme(BackgroundTheme theme) async {
    if (_current.id == theme.id) return;
    _current = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, theme.id);
    notifyListeners();
  }
}

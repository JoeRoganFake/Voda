import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterProvider extends ChangeNotifier {
  int _currentIntake = 0;
  int _dailyGoal = 2000;
  int _baseGoal = 2000;   // goal before climate adjustment
  int _cupSize = 250;
  List<int> _log = [];
  bool _autoClimateAdjust = false;

  int get currentIntake => _currentIntake;
  int get dailyGoal => _dailyGoal;
  int get baseGoal => _baseGoal;
  int get cupSize => _cupSize;
  bool get autoClimateAdjust => _autoClimateAdjust;
  List<int> get log => List.unmodifiable(_log);
  double get progress => (_currentIntake / _dailyGoal).clamp(0.0, 1.0);

  WaterProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('lastDate') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    _dailyGoal = prefs.getInt('dailyGoal') ?? 2000;
    _baseGoal = prefs.getInt('baseGoal') ?? _dailyGoal;
    _cupSize = prefs.getInt('cupSize') ?? 250;
    _autoClimateAdjust = prefs.getBool('autoClimateAdjust') ?? false;

    if (lastDate == today) {
      _currentIntake = prefs.getInt('currentIntake') ?? 0;
      _log = (prefs.getStringList('log') ?? []).map(int.parse).toList();
    } else {
      _currentIntake = 0;
      _log = [];
      await prefs.setString('lastDate', today);
      await prefs.setInt('currentIntake', 0);
      await prefs.setStringList('log', []);
    }
    notifyListeners();
  }

  Future<void> drinkCup() async {
    await addWater(_cupSize);
  }

  Future<void> addWater(int ml) async {
    _currentIntake += ml;
    _log.add(ml);
    await _save();
    notifyListeners();
  }

  Future<void> removeLast() async {
    if (_log.isEmpty) return;
    final last = _log.removeLast();
    _currentIntake = (_currentIntake - last).clamp(0, 99999);
    await _save();
    notifyListeners();
  }

  Future<void> reset() async {
    _currentIntake = 0;
    _log = [];
    await _save();
    notifyListeners();
  }

  Future<void> setDailyGoal(int goal) async {
    _baseGoal = goal;
    _dailyGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyGoal', goal);
    await prefs.setInt('baseGoal', goal);
    notifyListeners();
  }

  /// Called by ClimateProvider when auto-adjust is enabled and fresh data arrives.
  Future<void> applyClimateAdjustment(int adjustmentMl) async {
    if (!_autoClimateAdjust) return;
    final adjusted = (_baseGoal + adjustmentMl).clamp(500, 6000);
    _dailyGoal = adjusted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyGoal', adjusted);
    notifyListeners();
  }

  Future<void> setAutoClimateAdjust(bool value) async {
    _autoClimateAdjust = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoClimateAdjust', value);
    notifyListeners();
  }

  Future<void> setCupSize(int size) async {
    _cupSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cupSize', size);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('lastDate', today);
    await prefs.setInt('currentIntake', _currentIntake);
    await prefs.setStringList('log', _log.map((e) => e.toString()).toList());
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterProvider extends ChangeNotifier {
  int _currentIntake = 0;
  int _dailyGoal = 2000;
  int _baseGoal = 2000;   // goal before climate adjustment
  int _cupSize = 250;
  List<int> _log = [];
  bool _autoClimateAdjust = false;
  String? _pendingGoalChangeNotice;
  Timer? _midnightTimer;

  int get currentIntake => _currentIntake;
  int get dailyGoal => _dailyGoal;
  int get baseGoal => _baseGoal;
  int get cupSize => _cupSize;
  bool get autoClimateAdjust => _autoClimateAdjust;
  String? get pendingGoalChangeNotice => _pendingGoalChangeNotice;
  List<int> get log => List.unmodifiable(_log);
  double get progress => (_currentIntake / _dailyGoal).clamp(0.0, 1.0);

  void clearGoalChangeNotice() {
    _pendingGoalChangeNotice = null;
  }

  WaterProvider() {
    _load();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1); // next midnight
    final untilMidnight = midnight.difference(now);
    _midnightTimer = Timer(untilMidnight, () async {
      _currentIntake = 0;
      _log = [];
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString('lastDate', today);
      await prefs.setInt('currentIntake', 0);
      await prefs.setStringList('log', []);
      notifyListeners();
      _scheduleMidnightReset(); // schedule the next day
    });
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
    if (adjusted == _dailyGoal) return; // nothing changed
    final oldGoal = _dailyGoal;
    _dailyGoal = adjusted;
    final sign = adjustmentMl >= 0 ? '+' : '';
    _pendingGoalChangeNotice =
        'Denný cieľ upravený na $adjusted ml (${oldGoal} ml → $adjusted ml, klíma: $sign${adjustmentMl} ml)';
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

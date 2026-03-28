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
  int? _lastClimateAdjustment; // persisted — only show popup when this changes

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
    _lastClimateAdjustment = prefs.getInt('lastClimateAdjustment');

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
    _scheduleMidnightReset();
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
  /// [announce] = true forces a popup even when the goal didn't change (e.g. on startup).
  Future<void> applyClimateAdjustment(int adjustmentMl, {bool announce = false}) async {
    debugPrint('[Water] applyClimateAdjustment($adjustmentMl, announce=$announce) auto=$_autoClimateAdjust base=$_baseGoal current=$_dailyGoal lastAdj=$_lastClimateAdjustment');
    if (!_autoClimateAdjust) return;
    final adjusted = (_baseGoal + adjustmentMl).clamp(500, 6000);
    final sign = adjustmentMl >= 0 ? '+' : '';
    final adjustmentChanged = _lastClimateAdjustment != adjustmentMl;

    // Always update the goal to the correct value.
    if (adjusted != _dailyGoal) {
      _dailyGoal = adjusted;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dailyGoal', adjusted);
    }

    // Only show popup when the climate adjustment itself is different from last time.
    if (adjustmentChanged) {
      _lastClimateAdjustment = adjustmentMl;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastClimateAdjustment', adjustmentMl);
      _pendingGoalChangeNotice =
          'Denný cieľ upravený na $adjusted ml (základ: ${_baseGoal} ml, klíma: $sign${adjustmentMl} ml)';
      debugPrint('[Water] adjustment changed: popup shown');
      notifyListeners();
    } else {
      debugPrint('[Water] adjustment same as last ($adjustmentMl), no popup');
      if (adjusted != _dailyGoal) notifyListeners(); // still notify if goal changed
    }
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

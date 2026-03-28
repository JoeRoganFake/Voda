import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterProvider extends ChangeNotifier {
  int _currentIntake = 0;
  int _dailyGoal = 2000;
  int _baseGoal = 2000;   // goal before climate adjustment
  int _cupSize = 250;
  int _bottleSize = 500;
  List<int> _log = [];
  bool _autoClimateAdjust = false;
  bool _remindersEnabled = false;
  int _reminderIntervalMinutes = 120;
  int _reminderStartHour = 8;
  int _reminderEndHour = 22;
  String? _pendingGoalChangeNotice;
  Timer? _midnightTimer;
  int? _lastClimateAdjustment; // persisted — only show popup when this changes

  int get currentIntake => _currentIntake;
  int get dailyGoal => _dailyGoal;
  int get baseGoal => _baseGoal;
  int get cupSize => _cupSize;
  int get bottleSize => _bottleSize;
  bool get autoClimateAdjust => _autoClimateAdjust;
  bool get remindersEnabled => _remindersEnabled;
  int get reminderIntervalMinutes => _reminderIntervalMinutes;
  int get reminderStartHour => _reminderStartHour;
  int get reminderEndHour => _reminderEndHour;
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
    _bottleSize = prefs.getInt('bottleSize') ?? 500;
    _autoClimateAdjust = prefs.getBool('autoClimateAdjust') ?? false;
    _remindersEnabled = prefs.getBool('remindersEnabled') ?? false;
    _reminderIntervalMinutes = prefs.getInt('reminderIntervalMinutes') ?? 120;
    _reminderStartHour = prefs.getInt('reminderStartHour') ?? 8;
    _reminderEndHour = prefs.getInt('reminderEndHour') ?? 22;
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

  Future<void> setRemindersEnabled(bool value) async {
    _remindersEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remindersEnabled', value);
    notifyListeners();
  }

  Future<void> setReminderIntervalMinutes(int minutes) async {
    _reminderIntervalMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminderIntervalMinutes', minutes);
    notifyListeners();
  }

  Future<void> setReminderStartHour(int hour) async {
    _reminderStartHour = hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminderStartHour', hour);
    notifyListeners();
  }

  Future<void> setReminderEndHour(int hour) async {
    _reminderEndHour = hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminderEndHour', hour);
    notifyListeners();
  }

  Future<void> setCupSize(int size) async {
    _cupSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cupSize', size);
    notifyListeners();
  }

  Future<void> setBottleSize(int size) async {
    _bottleSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bottleSize', size);
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

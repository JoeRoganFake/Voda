import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'water_provider.dart';

/// Broad climate classification derived from temperature + humidity.
enum ClimateLevel {
  cold,     // < 10 °C
  cool,     // 10–18 °C
  moderate, // 18–25 °C
  warm,     // 25–30 °C
  hot,      // 30–35 °C
  veryHot,  // > 35 °C
}

extension ClimateLevelX on ClimateLevel {
  String get label => switch (this) {
        ClimateLevel.cold     => 'Cold',
        ClimateLevel.cool     => 'Cool',
        ClimateLevel.moderate => 'Moderate',
        ClimateLevel.warm     => 'Warm',
        ClimateLevel.hot      => 'Hot',
        ClimateLevel.veryHot  => 'Very Hot',
      };

  Color get color => switch (this) {
        ClimateLevel.cold     => const Color(0xFF93C5FD),
        ClimateLevel.cool     => const Color(0xFF67E8F9),
        ClimateLevel.moderate => const Color(0xFF6EE7B7),
        ClimateLevel.warm     => const Color(0xFFFDE68A),
        ClimateLevel.hot      => const Color(0xFFFB923C),
        ClimateLevel.veryHot  => const Color(0xFFF87171),
      };
}

class ClimateData {
  final double temperature;   // °C
  final int humidity;         // %
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;

  const ClimateData({
    required this.temperature,
    required this.humidity,
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
  });

  ClimateLevel get level {
    if (temperature < 10) return ClimateLevel.cold;
    if (temperature < 18) return ClimateLevel.cool;
    if (temperature < 25) return ClimateLevel.moderate;
    if (temperature < 30) return ClimateLevel.warm;
    if (temperature < 35) return ClimateLevel.hot;
    return ClimateLevel.veryHot;
  }

  /// Extra ml of water recommended on top of the user's base daily goal.
  int get waterAdjustmentMl {
    int extra = switch (level) {
      ClimateLevel.cold     => -200,
      ClimateLevel.cool     => -100,
      ClimateLevel.moderate => 0,
      ClimateLevel.warm     => 300,
      ClimateLevel.hot      => 500,
      ClimateLevel.veryHot  => 750,
    };
    // High humidity makes you feel hotter and sweat more
    if (humidity > 70) extra += 200;
    if (humidity > 85) extra += 150;
    return extra;
  }

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'humidity': humidity,
        'latitude': latitude,
        'longitude': longitude,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory ClimateData.fromJson(Map<String, dynamic> json) => ClimateData(
        temperature: (json['temperature'] as num).toDouble(),
        humidity: json['humidity'] as int,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );
}

enum ClimateStatus { idle, loading, loaded, error, permissionDenied }

class ClimateProvider extends ChangeNotifier {
  static const _cacheKey = 'climateData';
  static const _cacheDuration = Duration(hours: 3);

  ClimateData? _data;
  ClimateStatus _status = ClimateStatus.idle;
  String? _errorMessage;
  WaterProvider? _waterProvider;
  bool _autoClimateWasOn = false;
  String _lastAppliedDate = ''; // track which day adjustment was last applied

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  /// Called by ProxyProvider once when the WaterProvider instance is first
  /// created. Sets up a direct listener so midnight resets and toggle changes
  /// are handled without depending on the widget tree being active.
  void attachWaterProvider(WaterProvider wp) {
    if (_waterProvider == wp) return; // already wired — nothing to do
    _waterProvider?.removeListener(_onWaterChanged);
    _waterProvider = wp;
    _autoClimateWasOn = wp.autoClimateAdjust;
    wp.addListener(_onWaterChanged);
    // Run initial apply in case cache was already loaded.
    _onWaterChanged();
  }

  void _onWaterChanged() {
    final wp = _waterProvider;
    if (wp == null) return;

    final autoJustTurnedOn = !_autoClimateWasOn && wp.autoClimateAdjust;
    _autoClimateWasOn = wp.autoClimateAdjust;

    if (!wp.autoClimateAdjust) return;

    final isNewDay = _lastAppliedDate != _today();

    if (autoJustTurnedOn || isNewDay) {
      if (_status == ClimateStatus.loaded && _data != null) {
        _lastAppliedDate = _today();
        wp.applyClimateAdjustment(_data!.waterAdjustmentMl);
      }
      // Force fresh fetch on a new day; cache prevents redundant fetches.
      refresh(force: isNewDay);
    }
  }

  @override
  void dispose() {
    _waterProvider?.removeListener(_onWaterChanged);
    super.dispose();
  }

  ClimateData? get data => _data;
  ClimateStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// Convenience getters – safe to call even before data is loaded.
  double? get temperature => _data?.temperature;
  int? get humidity => _data?.humidity;
  ClimateLevel? get level => _data?.level;
  int get waterAdjustmentMl => _data?.waterAdjustmentMl ?? 0;
  bool get isLoaded => _status == ClimateStatus.loaded;

  ClimateProvider() {
    _loadCache();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetch fresh climate data. Safe to call multiple times; uses cache when
  /// data is recent enough.
  Future<void> refresh({bool force = false}) async {
    if (!force && _isCacheValid()) {
      // Cache is still valid — no network call, but still apply adjustment
      // in case WaterProvider wasn't ready the first time it was loaded.
      _lastAppliedDate = _today();
      _waterProvider?.applyClimateAdjustment(_data!.waterAdjustmentMl);
      return;
    }

    _setStatus(ClimateStatus.loading);

    try {
      final position = await _getPosition();
      if (position == null) return; // permission denied — status already set

      final weather = await _fetchWeather(position.latitude, position.longitude);

      _data = ClimateData(
        temperature: weather['temperature'],
        humidity: weather['humidity'],
        latitude: position.latitude,
        longitude: position.longitude,
        fetchedAt: DateTime.now(),
      );

      await _saveCache();
      _setStatus(ClimateStatus.loaded);
      _lastAppliedDate = _today();
      // announce: true so a popup always shows after a fresh fetch on startup.
      _waterProvider?.applyClimateAdjustment(_data!.waterAdjustmentMl, announce: true);
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(ClimateStatus.error);
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  bool _isCacheValid() {
    if (_data == null) return false;
    return DateTime.now().difference(_data!.fetchedAt) < _cacheDuration;
  }

  void _setStatus(ClimateStatus s) {
    _status = s;
    notifyListeners();
  }

  Future<Position?> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = 'Location services are disabled.';
      _setStatus(ClimateStatus.error);
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _errorMessage = 'Location permission denied.';
      _setStatus(ClimateStatus.permissionDenied);
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low, // city-level is enough for climate
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Calls the free Open-Meteo API — no API key required.
  Future<Map<String, dynamic>> _fetchWeather(
      double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat'
      '&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m'
      '&timezone=auto',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Weather API error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;

    return {
      'temperature': (current['temperature_2m'] as num).toDouble(),
      'humidity': (current['relative_humidity_2m'] as num).toInt(),
    };
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      _data = ClimateData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (_isCacheValid()) {
        _setStatus(ClimateStatus.loaded);
        _lastAppliedDate = _today();
        _waterProvider?.applyClimateAdjustment(_data!.waterAdjustmentMl);
      }
    } catch (_) {
      // Corrupt cache — ignore, will re-fetch on next refresh()
    }
  }

  Future<void> _saveCache() async {
    if (_data == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(_data!.toJson()));
  }
}

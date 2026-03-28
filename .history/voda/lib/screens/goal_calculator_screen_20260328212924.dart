import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';

class GoalCalculatorScreen extends StatefulWidget {
  const GoalCalculatorScreen({super.key});

  @override
  State<GoalCalculatorScreen> createState() => _GoalCalculatorScreenState();
}

class _GoalCalculatorScreenState extends State<GoalCalculatorScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  int _gender = 0; // 0=male, 1=female
  int _activity = 1; // 0=sedentary, 1=light, 2=moderate, 3=intense
  int _climate = 1; // 0=cold, 1=temperate, 2=warm, 3=hot, 4=tropical

  String? _locationLabel;
  bool _locationDetected = false;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    _detectClimate();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _detectClimate() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _loadingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final lat = pos.latitude.abs();

      int detected;
      String label;
      if (lat < 15) {
        detected = 4;
        label = 'Tropická (detekovaná z polohy)';
      } else if (lat < 25) {
        detected = 3;
        label = 'Horúca (detekovaná z polohy)';
      } else if (lat < 40) {
        detected = 2;
        label = 'Teplá (detekovaná z polohy)';
      } else if (lat < 55) {
        detected = 1;
        label = 'Mierna (detekovaná z polohy)';
      } else {
        detected = 0;
        label = 'Chladná (detekovaná z polohy)';
      }

      setState(() {
        _climate = detected;
        _locationLabel = label;
        _locationDetected = true;
        _loadingLocation = false;
      });
    } catch (_) {
      setState(() => _loadingLocation = false);
    }
  }

  int? _calculate() {
    final weight = int.tryParse(_weightController.text);
    final height = int.tryParse(_heightController.text);
    final age = int.tryParse(_ageController.text);
    if (weight == null || weight <= 0) return null;

    // Base: 35 ml per kg
    double total = weight * 35.0;

    // Height bonus (above 170 cm)
    if (height != null && height > 170) total += (height - 170) * 4.0;

    // Age adjustment (older = slightly less)
    if (age != null) {
      if (age > 55) total -= 200;
      else if (age > 40) total -= 100;
    }

    // Gender
    if (_gender == 1) total -= 150;

    // Activity
    const activityBonus = [0, 350, 600, 900];
    total += activityBonus[_activity];

    // Climate
    const climateBonus = [-200, 0, 300, 500, 700];
    total += climateBonus[_climate];

    // Round to nearest 50ml, clamp sensibly
    return (total / 50).round() * 50;
  }

  @override
  Widget build(BuildContext context) {
    final result = _calculate();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Kalkulátor denného cieľa'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          // Info banner
          _InfoBanner(
            icon: Icons.info_outline,
            text:
                'Odporúčaný príjem vody závisí od tela, aktivity aj prostredia. '
                'Vyplňte údaje pre čo najpresnejší výsledok.',
          ),
          const SizedBox(height: 28),

          // ── Personal info ──
          _SectionLabel(label: 'Osobné údaje'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: _DarkField(
                  controller: _weightController,
                  hint: 'napr. 75',
                  suffix: 'kg',
                  label: 'Hmotnosť',
                  onChanged: (_) => setState(() {})),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DarkField(
                  controller: _heightController,
                  hint: 'napr. 175',
                  suffix: 'cm',
                  label: 'Výška',
                  onChanged: (_) => setState(() {})),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DarkField(
                  controller: _ageController,
                  hint: 'napr. 28',
                  suffix: 'r.',
                  label: 'Vek',
                  onChanged: (_) => setState(() {})),
            ),
          ]),
          const SizedBox(height: 20),

          // Gender
          _SectionLabel(label: 'Pohlavie'),
          const SizedBox(height: 10),
          Row(children: [
            _CalcChip(
                label: '♂ Muž',
                selected: _gender == 0,
                onTap: () => setState(() => _gender = 0)),
            const SizedBox(width: 10),
            _CalcChip(
                label: '♀ Žena',
                selected: _gender == 1,
                onTap: () => setState(() => _gender = 1)),
          ]),
          const SizedBox(height: 24),

          // Activity
          _SectionLabel(label: 'Úroveň aktivity'),
          const SizedBox(height: 10),
          Column(
            children: [
              Row(children: [
                _CalcChip(
                    label: 'Sedavá',
                    sublabel: 'kancelária',
                    selected: _activity == 0,
                    onTap: () => setState(() => _activity = 0)),
                const SizedBox(width: 10),
                _CalcChip(
                    label: 'Nízka',
                    sublabel: '1–2× týž.',
                    selected: _activity == 1,
                    onTap: () => setState(() => _activity = 1)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _CalcChip(
                    label: 'Stredná',
                    sublabel: '3–5× týž.',
                    selected: _activity == 2,
                    onTap: () => setState(() => _activity = 2)),
                const SizedBox(width: 10),
                _CalcChip(
                    label: 'Vysoká',
                    sublabel: 'denne',
                    selected: _activity == 3,
                    onTap: () => setState(() => _activity = 3)),
              ]),
            ],
          ),
          const SizedBox(height: 24),

          // Climate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel(label: 'Klíma'),
              if (_loadingLocation)
                Row(children: [
                  const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: Color(0xFF38BDF8))),
                  const SizedBox(width: 6),
                  Text('Zisťujem polohu…',
                      style: TextStyle(
                          fontSize: 11, color: Colors.white.withOpacity(0.4))),
                ])
              else if (_locationDetected)
                Row(children: [
                  const Icon(Icons.location_on,
                      size: 13, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 4),
                  Text('Automaticky',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF38BDF8))),
                ])
              else
                GestureDetector(
                  onTap: _detectClimate,
                  child: Row(children: [
                    const Icon(Icons.location_searching,
                        size: 13, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 4),
                    const Text('Detekovať',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF38BDF8))),
                  ]),
                ),
            ],
          ),
          if (_locationDetected && _locationLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              '📍 $_locationLabel',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.45),
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
            Text(
              'Môžete ju zmeniť ručne nižšie.',
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.35)),
            ),
          ],
          const SizedBox(height: 10),
          Column(
            children: [
              Row(children: [
                _CalcChip(
                    label: '❄️ Chladná',
                    sublabel: 'sever, zima',
                    selected: _climate == 0,
                    onTap: () =>
                        setState(() { _climate = 0; _locationDetected = false; })),
                const SizedBox(width: 10),
                _CalcChip(
                    label: '🌤 Mierna',
                    sublabel: 'stredná Európa',
                    selected: _climate == 1,
                    onTap: () =>
                        setState(() { _climate = 1; _locationDetected = false; })),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _CalcChip(
                    label: '☀️ Teplá',
                    sublabel: 'Stredomorie',
                    selected: _climate == 2,
                    onTap: () =>
                        setState(() { _climate = 2; _locationDetected = false; })),
                const SizedBox(width: 10),
                _CalcChip(
                    label: '🔥 Horúca',
                    sublabel: 'púšť, juh',
                    selected: _climate == 3,
                    onTap: () =>
                        setState(() { _climate = 3; _locationDetected = false; })),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _CalcChip(
                    label: '🌴 Tropická',
                    sublabel: 'rovník',
                    selected: _climate == 4,
                    onTap: () =>
                        setState(() { _climate = 4; _locationDetected = false; })),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox()),
              ]),
            ],
          ),
          const SizedBox(height: 32),

          // Result
          if (result != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1C44B3).withOpacity(0.5),
                    const Color(0xFF1E3A8A).withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF38BDF8).withOpacity(0.35), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Odporúčaný denný príjem',
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.6))),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$result',
                          style: const TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1)),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('ml',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white.withOpacity(0.6))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _BreakdownRow(label: 'Základný príjem (hmotnosť)',
                      value: '${(int.parse(_weightController.text) * 35)} ml'),
                  if (int.tryParse(_heightController.text) != null &&
                      int.parse(_heightController.text) > 170)
                    _BreakdownRow(
                        label: 'Bonus za výšku',
                        value: '+${(int.parse(_heightController.text) - 170) * 4} ml'),
                  _BreakdownRow(
                      label: 'Aktivita',
                      value: '+${[0, 350, 600, 900][_activity]} ml'),
                  _BreakdownRow(
                      label: 'Klíma',
                      value:
                          '${[-200, 0, 300, 500, 700][_climate] >= 0 ? '+' : ''}${[-200, 0, 300, 500, 700][_climate]} ml'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  context.read<WaterProvider>().setDailyGoal(result);
                  Navigator.pop(context, result);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1C44B3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Použiť ako denný cieľ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                'Zadajte aspoň svoju hmotnosť pre výpočet.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.55),
          letterSpacing: 0.5));
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C44B3).withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF38BDF8).withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final String label;
  final ValueChanged<String> onChanged;
  const _DarkField(
      {required this.controller,
      required this.hint,
      required this.suffix,
      required this.label,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          cursorColor: const Color(0xFF38BDF8),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
            suffixText: suffix,
            suffixStyle:
                TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _CalcChip extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _CalcChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF1C44B3)
                : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.5))),
              if (sublabel != null)
                Text(sublabel!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? Colors.white.withOpacity(0.6)
                            : Colors.white.withOpacity(0.3))),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  const _BreakdownRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withOpacity(0.45))),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

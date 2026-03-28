import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import '../providers/climate_provider.dart';

class GoalCalculatorScreen extends StatefulWidget {
  const GoalCalculatorScreen({super.key});

  @override
  State<GoalCalculatorScreen> createState() => _GoalCalculatorScreenState();
}

class _GoalCalculatorScreenState extends State<GoalCalculatorScreen> {
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  int _gender = 0;    // 0=male, 1=female
  int _activity = 1;  // 0=sedentary, 1=light, 2=moderate, 3=intense
  bool _pregnant = false;
  bool _breastfeeding = false;

  int? get _recommended {
    final weight = int.tryParse(_weightController.text);
    final age = int.tryParse(_ageController.text);
    if (weight == null || weight <= 0) return null;

    // Base: 35 ml per kg
    double base = weight * 35.0;

    // Age adjustment — older adults need slightly more
    if (age != null) {
      if (age >= 55) base += 200;
    }

    // Gender adjustment
    if (_gender == 1) base -= 200; // females slightly less base

    // Activity bonus
    const activityBonus = [0, 300, 600, 900];
    base += activityBonus[_activity];

    // Pregnancy / breastfeeding
    if (_pregnant) base += 300;
    if (_breastfeeding) base += 700;

    // Round to nearest 50 ml
    return (base / 50).round() * 50;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final climate = context.watch<ClimateProvider>();
    final baseResult = _recommended;
    final climateAdj = climate.isLoaded ? climate.waterAdjustmentMl : 0;
    final result = baseResult != null ? (baseResult + climateAdj).clamp(500, 6000) as int : null;

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
          Text(
            'Vypočítame váš odporúčaný denný príjem vody na základe vašich údajov.',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5), height: 1.5),
          ),
          const SizedBox(height: 32),

          // ── Gender ──────────────────────────────────────────────────────
          _Label('Pohlavie'),
          const SizedBox(height: 10),
          Row(
            children: [
              _OptionChip(
                label: 'Muž',
                icon: Icons.male,
                selected: _gender == 0,
                onTap: () => setState(() => _gender = 0),
              ),
              const SizedBox(width: 12),
              _OptionChip(
                label: 'Žena',
                icon: Icons.female,
                selected: _gender == 1,
                onTap: () => setState(() {
                  _gender = 1;
                }),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Weight & Age ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Hmotnosť'),
                    const SizedBox(height: 10),
                    _InputField(
                      controller: _weightController,
                      hint: '70',
                      suffix: 'kg',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Vek'),
                    const SizedBox(height: 10),
                    _InputField(
                      controller: _ageController,
                      hint: '25',
                      suffix: 'r.',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Activity ─────────────────────────────────────────────────────
          _Label('Úroveň aktivity'),
          const SizedBox(height: 10),
          _ActivityCard(
            label: 'Sedavý',
            subtitle: 'Väčšinou sedenie, bez cvičenia',
            icon: Icons.chair_outlined,
            selected: _activity == 0,
            onTap: () => setState(() => _activity = 0),
          ),
          const SizedBox(height: 8),
          _ActivityCard(
            label: 'Ľahká aktivita',
            subtitle: '1–3× týždenne cvičenie',
            icon: Icons.directions_walk_outlined,
            selected: _activity == 1,
            onTap: () => setState(() => _activity = 1),
          ),
          const SizedBox(height: 8),
          _ActivityCard(
            label: 'Stredná aktivita',
            subtitle: '3–5× týždenne cvičenie',
            icon: Icons.directions_run_outlined,
            selected: _activity == 2,
            onTap: () => setState(() => _activity = 2),
          ),
          const SizedBox(height: 8),
          _ActivityCard(
            label: 'Intenzívna aktivita',
            subtitle: 'Každodenný tréning alebo fyzická práca',
            icon: Icons.fitness_center_outlined,
            selected: _activity == 3,
            onTap: () => setState(() => _activity = 3),
          ),
          const SizedBox(height: 28),

          // ── Climate (live) ────────────────────────────────────────────
          _Label('Klíma (aktuálna poloha)'),
          const SizedBox(height: 10),
          _ClimateInfoCard(climate: climate),
          const SizedBox(height: 28),

          // ── Pregnancy / breastfeeding (female only) ───────────────────
          if (_gender == 1) ...[
            _Label('Ďalšie faktory'),
            const SizedBox(height: 10),
            _ToggleCard(
              label: 'Tehotenstvo',
              subtitle: '+300 ml denne',
              value: _pregnant,
              onChanged: (v) => setState(() => _pregnant = v),
            ),
            const SizedBox(height: 8),
            _ToggleCard(
              label: 'Dojčenie',
              subtitle: '+700 ml denne',
              value: _breastfeeding,
              onChanged: (v) => setState(() => _breastfeeding = v),
            ),
            const SizedBox(height: 28),
          ],

          // ── Result ───────────────────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: result != null
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                'Zadajte hmotnosť pre výpočet odporúčania',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
              ),
            ),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF1C44B3)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Odporúčaný denný príjem',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result ?? 0} ml',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${((result ?? 0) / 1000).toStringAsFixed(1)} litrov denne',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                  if (climate.isLoaded && climateAdj != 0) ...
                    [
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'vrátane ${climateAdj > 0 ? '+' : ''}$climateAdj ml za klímu',
                          style: TextStyle(
                            color: climateAdj > 0
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF6EE7B7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ),

          if (result != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                context.read<WaterProvider>().setDailyGoal(result);
                Navigator.pop(context, result);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1C44B3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Použiť ako denný cieľ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final ValueChanged<String> onChanged;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      cursorColor: const Color(0xFF38BDF8),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontWeight: FontWeight.normal),
        suffixText: suffix,
        suffixStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1C44B3) : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : Colors.white.withOpacity(0.4)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white.withOpacity(0.4),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1C44B3).withOpacity(0.4) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.3), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF38BDF8), size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? const Color(0xFF1C44B3).withOpacity(0.3) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: value ? Colors.white : Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF38BDF8),
            activeTrackColor: const Color(0xFF1C44B3),
            inactiveThumbColor: Colors.white.withOpacity(0.3),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import '../providers/climate_provider.dart';
import '../services/notification_service.dart';
import 'goal_calculator_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _goalSlider;
  late double _cupSlider;
  late double _bottleSlider;

  @override
  void initState() {
    super.initState();
    final water = context.read<WaterProvider>();
    // Use baseGoal so the slider always shows the user's intended base,
    // not the climate-adjusted value.
    _goalSlider = water.baseGoal.toDouble();
    _cupSlider = water.cupSize.toDouble();
    _bottleSlider = water.bottleSize.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Nastavenia'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Daily goal section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(icon: Icons.flag_outlined, label: 'Denný cieľ'),
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalCalculatorScreen()),
                  );
                  if (result != null) {
                    setState(() => _goalSlider = result.toDouble());
                  }
                },
                icon: const Icon(Icons.calculate_outlined, size: 16, color: Color(0xFF38BDF8)),
                label: const Text(
                  'Kalkulátor',
                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_goalSlider.toInt()} ml',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Slider(
            value: _goalSlider,
            min: 500,
            max: 5000,
            divisions: 45,
            label: '${_goalSlider.toInt()} ml',
            activeColor: Colors.white,
            inactiveColor: Colors.white.withOpacity(0.3),
            onChanged: (val) => setState(() => _goalSlider = val),
            onChangeEnd: (val) {
              final w = context.read<WaterProvider>();
              final c = context.read<ClimateProvider>();
              w.setDailyGoal(val.toInt());
              // Re-apply climate on top of the new base immediately.
              if (w.autoClimateAdjust && c.isLoaded) {
                w.applyClimateAdjustment(c.waterAdjustmentMl);
              }
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('500 ml', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              Text('5000 ml', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),

          const SizedBox(height: 32),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),

          // Auto climate adjust toggle
          _AutoClimateToggle(),

          const SizedBox(height: 32),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),

          // Cup size section
          const _SectionHeader(
              icon: Icons.local_drink_outlined, label: 'Veľkosť pohára'),
          const SizedBox(height: 8),
          Text(
            '${_cupSlider.toInt()} ml',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Slider(
            value: _cupSlider,
            min: 50,
            max: 1000,
            divisions: 19,
            label: '${_cupSlider.toInt()} ml',
            activeColor: Colors.white,
            inactiveColor: Colors.white.withOpacity(0.3),
            onChanged: (val) => setState(() => _cupSlider = val),
            onChangeEnd: (val) =>
                context.read<WaterProvider>().setCupSize(val.toInt()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('50 ml', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              Text('1000 ml',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),

          const SizedBox(height: 32),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),

          // Bottle size section
          const _SectionHeader(
              icon: Icons.water_outlined, label: 'Veľkosť fľaše'),
          const SizedBox(height: 8),
          Text(
            '${_bottleSlider.toInt()} ml',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Slider(
            value: _bottleSlider,
            min: 200,
            max: 3000,
            divisions: 28,
            label: '${_bottleSlider.toInt()} ml',
            activeColor: Colors.white,
            inactiveColor: Colors.white.withOpacity(0.3),
            onChanged: (val) => setState(() => _bottleSlider = val),
            onChangeEnd: (val) =>
                context.read<WaterProvider>().setBottleSize(val.toInt()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('200 ml', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              Text('3000 ml',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),

          const SizedBox(height: 32),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),

          // Reset section
          const _SectionHeader(icon: Icons.restart_alt, label: 'Dáta'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            label: const Text(
              "Resetovať denný príjem",
              style: TextStyle(color: Colors.redAccent),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _confirmReset(context),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Resetovať príjem', style: TextStyle(color: Colors.white)),
        content:
            const Text("Naozaj chcete resetovať dnešný príjem vody?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušiť', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              context.read<WaterProvider>().reset();
              Navigator.pop(ctx);
            },
            child: const Text('Resetovať',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _AutoClimateToggle extends StatelessWidget {
  const _AutoClimateToggle();

  @override
  Widget build(BuildContext context) {
    final water = context.watch<WaterProvider>();
    final climate = context.watch<ClimateProvider>();
    final enabled = water.autoClimateAdjust;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFF1C44B3).withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? const Color(0xFF38BDF8).withOpacity(0.5)
              : Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFF38BDF8).withOpacity(0.15)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.thermostat_outlined,
              size: 20,
              color: enabled
                  ? const Color(0xFF38BDF8)
                  : Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automatická úprava podľa klímy',
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(water, climate, enabled),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (val) {
              final w = context.read<WaterProvider>();
              final c = context.read<ClimateProvider>();
              w.setAutoClimateAdjust(val);
              if (val) {
                if (c.isLoaded) {
                  // Apply instantly — no need to re-fetch
                  w.applyClimateAdjustment(c.waterAdjustmentMl);
                } else {
                  c.refresh(force: true);
                }
              } else {
                // Restore to the user's base goal (no climate effect)
                w.setDailyGoal(w.baseGoal);
              }
            },
            activeColor: const Color(0xFF38BDF8),
            activeTrackColor: const Color(0xFF1C44B3),
            inactiveThumbColor: Colors.white.withOpacity(0.3),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  String _subtitle(WaterProvider water, ClimateProvider climate, bool enabled) {
    if (!enabled) return 'Cieľ sa nemení podľa počasia';
    if (!climate.isLoaded) return 'Načítavam počasie…';
    final adj = climate.waterAdjustmentMl;
    if (adj == 0) return 'Žiadna úprava potrebná dnes';
    final sign = adj > 0 ? '+' : '';
    return 'Dnes: $sign$adj ml (${water.baseGoal} ml → ${water.dailyGoal} ml)';
  }
}

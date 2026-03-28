import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _goalSlider;
  late double _cupSlider;

  @override
  void initState() {
    super.initState();
    final water = context.read<WaterProvider>();
    _goalSlider = water.dailyGoal.toDouble();
    _cupSlider = water.cupSize.toDouble();
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
                onPressed: () => _showGoalCalculator(context),
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
            onChangeEnd: (val) =>
                context.read<WaterProvider>().setDailyGoal(val.toInt()),
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

          // Cup size section
          const _SectionHeader(
              icon: Icons.local_drink_outlined, label: 'Velkosť pohára'),
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

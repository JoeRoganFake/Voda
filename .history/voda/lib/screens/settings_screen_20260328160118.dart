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
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Daily goal section
          const _SectionHeader(icon: Icons.flag_outlined, label: 'Daily Goal'),
          const SizedBox(height: 8),
          Text(
            '${_goalSlider.toInt()} ml',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A73E8),
            ),
          ),
          Slider(
            value: _goalSlider,
            min: 500,
            max: 5000,
            divisions: 45,
            label: '${_goalSlider.toInt()} ml',
            activeColor: const Color(0xFF1A73E8),
            onChanged: (val) => setState(() => _goalSlider = val),
            onChangeEnd: (val) =>
                context.read<WaterProvider>().setDailyGoal(val.toInt()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('500 ml', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('5000 ml', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Cup size section
          const _SectionHeader(
              icon: Icons.local_drink_outlined, label: 'Cup Size'),
          const SizedBox(height: 8),
          Text(
            '${_cupSlider.toInt()} ml',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A73E8),
            ),
          ),
          Slider(
            value: _cupSlider,
            min: 50,
            max: 1000,
            divisions: 19,
            label: '${_cupSlider.toInt()} ml',
            activeColor: const Color(0xFF1A73E8),
            onChanged: (val) => setState(() => _cupSlider = val),
            onChangeEnd: (val) =>
                context.read<WaterProvider>().setCupSize(val.toInt()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('50 ml', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('1000 ml',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Reset section
          const _SectionHeader(icon: Icons.restart_alt, label: 'Data'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            label: const Text(
              "Reset Today's Intake",
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
        title: const Text('Reset Intake'),
        content:
            const Text("Are you sure you want to reset today's water intake?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<WaterProvider>().reset();
              Navigator.pop(ctx);
            },
            child: const Text('Reset',
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
        Icon(icon, color: const Color(0xFF1A73E8), size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A73E8),
          ),
        ),
      ],
    );
  }
}

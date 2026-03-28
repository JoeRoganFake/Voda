import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import 'goal_calculator_screen.dart';

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
                onPressed: () async {
                  final result = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GoalCalculatorScreen()),
                  );
                  if (result != null) setState(() => _goalSlider = result.toDouble());
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

  // ignore: unused_element
  void _showGoalCalculator_REMOVED(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          int? weight = int.tryParse(weightController.text);
          int? recommended;
          if (weight != null && weight > 0) {
            double base = weight * 35.0;
            if (_activity == 1) base += 350;
            if (_activity == 2) base += 700;
            if (_climate == 1) base += 500;
            recommended = (base / 100).round() * 100;
          }

          return Dialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kalkulátor denného cieľa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text('Vypočítame odporúčaný príjem vody',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 24),

                  // Weight input
                  Text('Hmotnosť (kg)',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: const Color(0xFF38BDF8),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: 'napr. 70',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      suffixText: 'kg',
                      suffixStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Activity level
                  Text('Aktivita',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _CalcChip(label: 'Nízka', selected: _activity == 0,
                          onTap: () => setDialogState(() => _activity = 0)),
                      const SizedBox(width: 8),
                      _CalcChip(label: 'Stredná', selected: _activity == 1,
                          onTap: () => setDialogState(() => _activity = 1)),
                      const SizedBox(width: 8),
                      _CalcChip(label: 'Vysoká', selected: _activity == 2,
                          onTap: () => setDialogState(() => _activity = 2)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Climate
                  Text('Klíma',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _CalcChip(label: 'Normálna', selected: _climate == 0,
                          onTap: () => setDialogState(() => _climate = 0)),
                      const SizedBox(width: 8),
                      _CalcChip(label: 'Horúca', selected: _climate == 1,
                          onTap: () => setDialogState(() => _climate = 1)),
                    ],
                  ),

                  if (recommended != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C44B3).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Odporúčané',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                          Text('$recommended ml',
                              style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.white.withOpacity(0.15)),
                            ),
                          ),
                          child: Text('Zrušiť',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w600)),
                        ),
                      ),
                      if (recommended != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() => _goalSlider = recommended!.toDouble());
                              context.read<WaterProvider>().setDailyGoal(recommended!);
                              Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1C44B3),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Použiť', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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

class _CalcChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CalcChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1C44B3) : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF38BDF8) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}

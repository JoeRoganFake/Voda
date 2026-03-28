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

class _ClimateSuggestionCard extends StatelessWidget {
  const _ClimateSuggestionCard();

  String _labelSk(ClimateLevel level) => switch (level) {
        ClimateLevel.cold     => 'Chladno',
        ClimateLevel.cool     => 'Chladnejšie',
        ClimateLevel.moderate => 'Mierne',
        ClimateLevel.warm     => 'Teplo',
        ClimateLevel.hot      => 'Horúco',
        ClimateLevel.veryHot  => 'Veľmi horúco',
      };

  String _adjustmentText(int ml) {
    if (ml == 0) return 'Žiadna úprava potrebná';
    if (ml > 0) return '+$ml ml odporúčame navyše';
    return '$ml ml menej ako zvyčajne';
  }

  @override
  Widget build(BuildContext context) {
    final climate = context.watch<ClimateProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionHeader(icon: Icons.thermostat_outlined, label: 'Klíma dnes'),
            if (climate.status == ClimateStatus.loading)
              const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
              )
            else
              GestureDetector(
                onTap: () => context.read<ClimateProvider>().refresh(force: true),
                child: Icon(Icons.refresh, size: 18, color: Colors.white.withOpacity(0.4)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBody(context, climate),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ClimateProvider climate) {
    if (climate.status == ClimateStatus.idle || climate.status == ClimateStatus.loading && climate.data == null) {
      return _InfoTile(
        icon: Icons.cloud_outlined,
        iconColor: Colors.white.withOpacity(0.3),
        title: 'Načítavam polohu…',
        subtitle: 'Zisťujeme aktuálne počasie',
      );
    }

    if (climate.status == ClimateStatus.permissionDenied) {
      return _InfoTile(
        icon: Icons.location_off_outlined,
        iconColor: Colors.orange,
        title: 'Prístup k polohe zamietnutý',
        subtitle: 'Povoľte prístup k polohe pre odporúčania podľa klímy',
      );
    }

    if (climate.status == ClimateStatus.error && climate.data == null) {
      return _InfoTile(
        icon: Icons.wifi_off_outlined,
        iconColor: Colors.redAccent,
        title: 'Nepodarilo sa načítať počasie',
        subtitle: climate.errorMessage ?? 'Skúste to znova',
      );
    }

    final data = climate.data!;
    final level = data.level;
    final adj = data.waterAdjustmentMl;
    final dailyGoal = context.read<WaterProvider>().dailyGoal;
    final suggested = (dailyGoal + adj).clamp(500, 6000);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: level.color.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        children: [
          // Weather row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: level.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_climateIcon(level), color: level.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labelSk(level),
                        style: TextStyle(color: level.color, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text(
                        '${data.temperature.toStringAsFixed(1)}°C  ·  vlhkosť ${data.humidity}%',
                        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.white.withOpacity(0.08)),

          // Adjustment row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Úprava príjmu',
                      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _adjustmentText(adj),
                      style: TextStyle(
                        color: adj > 0
                            ? const Color(0xFF38BDF8)
                            : adj < 0
                                ? const Color(0xFF6EE7B7)
                                : Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Odporúčaný cieľ',
                      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$suggested ml',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Apply button
          if (adj != 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.read<WaterProvider>().setDailyGoal(suggested);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Denný cieľ nastavený na $suggested ml'),
                        backgroundColor: const Color(0xFF1E293B),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: level.color.withOpacity(0.25),
                    foregroundColor: level.color,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Použiť odporúčaný cieľ', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _climateIcon(ClimateLevel level) => switch (level) {
        ClimateLevel.cold     => Icons.ac_unit,
        ClimateLevel.cool     => Icons.wb_cloudy_outlined,
        ClimateLevel.moderate => Icons.wb_sunny_outlined,
        ClimateLevel.warm     => Icons.wb_sunny,
        ClimateLevel.hot      => Icons.local_fire_department_outlined,
        ClimateLevel.veryHot  => Icons.local_fire_department,
      };
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

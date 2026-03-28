import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text(
          'Voda',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3),
        ),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<WaterProvider>(
        builder: (context, water, _) {
          return Column(
            children: [
              // Blue header with circular progress
              Container(
                color: const Color(0xFF1A73E8),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: _WaterProgressCircle(
                    progress: water.progress,
                    current: water.currentIntake,
                    goal: water.dailyGoal,
                  ),
                ),
              ),

              // Stats row
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCard(
                        label: 'Intake', value: '${water.currentIntake} ml'),
                    _StatCard(label: 'Goal', value: '${water.dailyGoal} ml'),
                    _StatCard(
                        label: 'Cups', value: '${water.log.length}'),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Log list
              Expanded(
                child: water.log.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.water_drop_outlined,
                                size: 64, color: Color(0xFFB0C4DE)),
                            SizedBox(height: 12),
                            Text(
                              'No water logged yet.\nTap the button below!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        reverse: true,
                        itemCount: water.log.length,
                        itemBuilder: (context, index) {
                          final reversedIndex =
                              water.log.length - 1 - index;
                          final isLast = reversedIndex == water.log.length - 1;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF1A73E8).withAlpha(30),
                              child: const Icon(Icons.water_drop,
                                  color: Color(0xFF1A73E8), size: 20),
                            ),
                            title: Text(
                              '${water.log[reversedIndex]} ml',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle:
                                Text('Cup ${reversedIndex + 1}'),
                            trailing: isLast
                                ? IconButton(
                                    icon: const Icon(Icons.undo,
                                        color: Colors.redAccent),
                                    tooltip: 'Remove last',
                                    onPressed: () => context
                                        .read<WaterProvider>()
                                        .removeLast(),
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<WaterProvider>(
        builder: (context, water, _) => FloatingActionButton.extended(
          onPressed: () => context.read<WaterProvider>().drinkCup(),
          backgroundColor: const Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.water_drop),
          label: Text('+${water.cupSize} ml'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _WaterProgressCircle extends StatelessWidget {
  final double progress;
  final int current;
  final int goal;

  const _WaterProgressCircle({
    required this.progress,
    required this.current,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 14,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$current / $goal ml',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withAlpha(220),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A73E8),
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

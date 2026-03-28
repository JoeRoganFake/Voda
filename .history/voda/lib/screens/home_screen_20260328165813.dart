import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';
import '../widgets/water_background.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark blue-gray background
      body: Consumer<WaterProvider>(
        builder: (context, water, _) {
          return Stack(
            children: [
              // Water background
              WaterBackground(progress: water.progress),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pytný režim',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.9),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            ),
                            color: Colors.white.withOpacity(0.8),
                            iconSize: 28,
                          ),
                        ],
                      ),
                    ),

                    // Main circular progress
                    Expanded(
                      child: Center(
                        child: _WaterDisplay(water: water),
                      ),
                    ),

                    // Quick actions
                    const _QuickActionsRow(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Water display
// ─────────────────────────────────────────────────────────────────────────────

class _WaterDisplay extends StatelessWidget {
  final WaterProvider water;
  const _WaterDisplay({required this.water});

  @override
  Widget build(BuildContext context) {
    final goalReached = water.progress >= 1.0;
    final textColor = goalReached ? const Color(0xFF22C55E) : Colors.white.withOpacity(0.9);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${water.currentIntake}',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ml',
          style: TextStyle(
            fontSize: 24,
            color: textColor.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: goalReached
                ? const Color(0xFF22C55E).withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: goalReached
                  ? const Color(0xFF22C55E)
                  : Colors.white.withOpacity(0.3),
            ),
          ),
          child: Text(
            goalReached
                ? 'Goal Reached!'
                : '${(water.progress * 100).toInt()}% of ${water.dailyGoal} ml',
            style: TextStyle(
              fontSize: 16,
              color: goalReached ? const Color(0xFFDCFCE7) : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final water = context.watch<WaterProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Add',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _QuickAddButton(
                label: '250ml',
                subtitle: 'Cup',
                onTap: () => water.addWater(250),
              ),
              const SizedBox(width: 12),
              _QuickAddButton(
                label: '500ml',
                subtitle: 'Bottle',
                onTap: () => water.addWater(500),
              ),
              const SizedBox(width: 12),
              _QuickAddButton(
                label: 'Custom',
                subtitle: 'Amount',
                onTap: () => _showCustomDialog(context),
                isCustom: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCustomDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Water'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (ml)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                context.read<WaterProvider>().addWater(amount);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isCustom;

  const _QuickAddButton({
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isCustom
                    ? [
                        const Color(0xFF06B6D4),
                        const Color(0xFF0EA5E9),
                      ]
                    : [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCustom
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isCustom ? const Color(0xFF0EA5E9) : Colors.black)
                      .withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCustom ? Colors.white : Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isCustom
                        ? Colors.white.withOpacity(0.9)
                        : Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


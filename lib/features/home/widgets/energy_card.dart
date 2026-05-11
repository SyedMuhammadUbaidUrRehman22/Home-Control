import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class EnergyCard extends StatelessWidget {
  final double totalKwh;
  final double totalCost;

  const EnergyCard({
    super.key,
    required this.totalKwh,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (totalKwh / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Energy Usage This Month',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalKwh.toStringAsFixed(2)} kWh',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Estimated Cost: ${totalCost.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

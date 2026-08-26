import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/brew_method.dart';
import '../main.dart'; // Access CoffeeColors

class MethodDetailScreen extends StatelessWidget {
  final BrewMethod method;

  const MethodDetailScreen({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    final minutes = (method.totalTargetTimeSeconds ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final seconds = (method.totalTargetTimeSeconds % 60).toString().padLeft(
      2,
      '0',
    );

    return Scaffold(
      backgroundColor: CoffeeColors.background,
      appBar: AppBar(title: Text(method.methodName)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // --- RECIPE OVERVIEW ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CoffeeColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOverviewStat('Coffee', '${method.defaultDose}g'),
                _buildOverviewStat('Water', '${method.defaultWater}g'),
                _buildOverviewStat(
                  'Ratio',
                  '1:${method.targetRatio.toStringAsFixed(1)}',
                ),
                _buildOverviewStat('Time', '$minutes:$seconds'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'POUR STRUCTURE',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: CoffeeColors.accent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // --- VISUAL TIMELINE ---
          ...method.steps.asMap().entries.map((entry) {
            int index = entry.key;
            MethodStep step = entry.value;
            bool isLast = index == method.steps.length - 1;

            IconData stepIcon = Icons.water_drop;
            if (step.type == 'Wait') stepIcon = Icons.timer_outlined;
            if (step.type == 'Swirl') stepIcon = Icons.cyclone;
            if (step.type == 'Bloom') stepIcon = Icons.filter_vintage;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline Line & Icon
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: CoffeeColors.primary.withOpacity(0.1),
                        child: Icon(
                          stepIcon,
                          size: 16,
                          color: CoffeeColors.primary,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: Colors.grey.shade200,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Step Details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.type,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: CoffeeColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.waterAmount > 0
                                ? 'Pour ${step.waterAmount}g  •  Wait ${step.durationSeconds}s'
                                : 'Wait ${step.durationSeconds}s',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: CoffeeColors.textDark,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/coffee_bean.dart';
import '../providers/brew_log_provider.dart';
import 'add_brew_screen.dart';
import '../main.dart'; // To access CoffeeColors

class BrewHistoryScreen extends ConsumerWidget {
  final CoffeeBean bean;

  const BrewHistoryScreen({super.key, required this.bean});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(brewLogProvider(bean.id!));

    return Scaffold(
      backgroundColor: CoffeeColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              bean.beanName,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Remaining: ${bean.currentWeight}g',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CoffeeColors.primary,
              ),
            ),
          ],
        ),
      ),
      body: logsState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CoffeeColors.primary),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Text(
                'No brews logged yet.\nTap + to dial in!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 100,
              left: 16,
              right: 16,
            ),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final minutes = (log.brewTimeSeconds ~/ 60).toString().padLeft(
                2,
                '0',
              );
              final seconds = (log.brewTimeSeconds % 60).toString().padLeft(
                2,
                '0',
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    16,
                  ), // Softer, modern radius
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1.5,
                  ), // Flat design! No shadows.
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TOP ROW: Title & Date ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            log.appliedMethod != null
                                ? '${log.brewMethod} • ${log.appliedMethod}' // Shows "Pour-over • Kasuya 4:6"
                                : log.brewMethod, // Fallback if no template was used
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: CoffeeColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM').format(log.dateOfMaking),
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- COLOR CODED STAT BADGES ---
                    // This mimics the clean look of the screenshot you liked!
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatBadge(
                          Icons.water_drop,
                          Colors.blue.shade400,
                          '${log.waterMass} g',
                        ),
                        _buildStatBadge(
                          Icons.grain,
                          CoffeeColors.primary,
                          '${log.dose} g',
                        ),
                        _buildStatBadge(
                          Icons.access_time,
                          Colors.amber.shade600,
                          '$minutes:$seconds',
                        ),
                        _buildStatBadge(
                          Icons.local_fire_department,
                          Colors.deepOrange.shade400,
                          '${log.temperature}°C',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // --- GRINDER INFO ---
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${log.grinder} (${log.grindSize})',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '1:${log.brewRatio.toStringAsFixed(1)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CoffeeColors.primary,
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                    ),

                    // --- MINIMALIST TASTING BARS ---
                    _buildTasteBar('Acidity', log.acidityScore),
                    _buildTasteBar('Sweetness', log.sweetnessScore),
                    _buildTasteBar('Body', log.bodyScore),

                    if (log.tastingNotes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        '"${log.tastingNotes}"',
                        style: GoogleFonts.inter(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    // Delete Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () =>
                            BrewLogController.deleteLog(ref, log.id!, bean.id!),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      // Clean, Premium Action Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CoffeeColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddBrewScreen(bean: bean)),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(
          'New Brew',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // --- HELPER: Color Coded Stat Badge ---
  Widget _buildStatBadge(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: CoffeeColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER: Minimalist Taste Bar ---
  Widget _buildTasteBar(String label, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(5, (index) {
                bool isFilled = index < score;
                return Expanded(
                  child: Container(
                    height: 6, // Thinner, more elegant lines
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isFilled
                          ? CoffeeColors.accent
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

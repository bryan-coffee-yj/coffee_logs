import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/bean_provider.dart';
import '../services/export_service.dart';
import 'add_bean_screen.dart';
import 'brew_history_screen.dart';
import '../main.dart'; // To access CoffeeColors
import '../models/coffee_bean.dart';

class BeanListScreen extends ConsumerWidget {
  const BeanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beanState = ref.watch(beanProvider);

    return Scaffold(
      body: beanState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CoffeeColors.primary),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (beans) {
          if (beans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cellar is empty.\nTap + to add your first bag!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
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
            itemCount: beans.length,
            itemBuilder: (context, index) {
              final bean = beans[index];
              final daysSinceRoast = DateTime.now()
                  .difference(bean.roastDate)
                  .inDays;
              final double percentLeft = bean.initialWeight > 0
                  ? (bean.currentWeight / bean.initialWeight).clamp(0.0, 1.0)
                  : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BrewHistoryScreen(bean: bean),
                      ),
                    );
                  },

                  // --- NEW: LONG PRESS TO DELETE BEAN ---
                  onLongPress: () {
                    _showDeleteConfirmation(context, ref, bean);
                  },

                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              bean.roasterName.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: CoffeeColors.accent,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (bean.currentWeight <= 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'EMPTY',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bean.beanName,
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: CoffeeColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildTag(
                              Icons.whatshot,
                              bean.roastLevel,
                              CoffeeColors.primary,
                            ),
                            const SizedBox(width: 8),
                            _buildTag(
                              Icons.calendar_today,
                              '$daysSinceRoast Days Ago',
                              Colors.blueGrey.shade600,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Inventory',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${bean.currentWeight.toStringAsFixed(1)}g / ${bean.initialWeight.toStringAsFixed(1)}g',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: CoffeeColors.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentLeft,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade100,
                            color: percentLeft > 0.15
                                ? CoffeeColors.accent
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CoffeeColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBeanScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(
          'Add Beans',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // --- UI HELPER: Small Info Tags ---
  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER: Delete Confirmation Dialog ---
  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    CoffeeBean bean,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Bean?',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${bean.beanName}"? This will permanently delete all brew logs associated with it.',
            style: GoogleFonts.inter(color: Colors.grey.shade600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(beanProvider.notifier).deleteBean(bean.id!);
                Navigator.pop(ctx);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

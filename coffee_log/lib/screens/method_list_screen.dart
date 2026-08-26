import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/method_provider.dart';
import '../main.dart'; // Access CoffeeColors
import 'add_method_screen.dart'; // We will create this next!
import 'method_detail_screen.dart';

class MethodListScreen extends ConsumerWidget {
  const MethodListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodState = ref.watch(methodProvider);

    return Scaffold(
      backgroundColor: CoffeeColors.background,
      appBar: AppBar(title: const Text('My Methods')),
      body: methodState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CoffeeColors.primary),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (methods) {
          if (methods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No methods saved yet.\nCreate your first recipe!',
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
            padding: const EdgeInsets.all(16),
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              final minutes = (method.totalTargetTimeSeconds ~/ 60)
                  .toString()
                  .padLeft(2, '0');
              final seconds = (method.totalTargetTimeSeconds % 60)
                  .toString()
                  .padLeft(2, '0');

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 16,
                ), // Moved margin here so the empty space isn't clickable
                child: Material(
                  color: Colors
                      .white, // Moved color here so the InkWell ripple effect is visible
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MethodDetailScreen(method: method),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(
                      16,
                    ), // Keeps the ripple effect inside your curved edges
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    method.methodName,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: CoffeeColors.textDark,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    ref
                                        .read(methodProvider.notifier)
                                        .deleteMethod(method.id!);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Stat Badges Row (Matches your history cards!)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatBadge(
                                  Icons.coffee,
                                  CoffeeColors.primary,
                                  '${method.defaultDose}g',
                                ),
                                _buildStatBadge(
                                  Icons.water_drop,
                                  Colors.blue.shade600,
                                  '${method.defaultWater}g',
                                ),
                                _buildStatBadge(
                                  Icons.timer_outlined,
                                  Colors.amber.shade700,
                                  '$minutes:$seconds',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Steps Preview
                            Text(
                              '${method.steps.length} Steps in this recipe',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMethodScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(
          'New Method',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // --- UI HELPER ---
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: CoffeeColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

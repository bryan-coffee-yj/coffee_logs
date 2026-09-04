import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/method_provider.dart';
import '../main.dart'; // Access CoffeeColors
import 'add_method_screen.dart';
import 'method_detail_screen.dart';

class MethodListScreen extends ConsumerWidget {
  const MethodListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodState = ref.watch(methodProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.only(top: 110), // Clears the frosted AppBar!
        child: Column(
          children: [
            // --- TOP ADD METHOD BUTTON ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(
                      color: CoffeeColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddMethodScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: CoffeeColors.primary),
                  label: Text(
                    'Add New Method',
                    style: GoogleFonts.montserrat(
                      color: CoffeeColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // --- METHOD LIST ---
            Expanded(
              child: methodState.when(
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
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 120,
                      left: 16,
                      right: 16,
                    ), // Clears bottom bar
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
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MethodDetailScreen(method: method),
                              ),
                            ),
                            onLongPress: () => _showDeleteConfirmation(
                              context,
                              ref,
                              method.id!,
                              method.methodName,
                            ),
                            borderRadius: BorderRadius.circular(16),
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${method.brewMethodType.toUpperCase()} • ${method.equipment.toUpperCase()}',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: CoffeeColors.accent,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      method.methodName,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: CoffeeColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
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
            'Delete Method?',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "$name"? Your old logs will keep the name, but you cannot use this template anymore.',
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
                ref.read(methodProvider.notifier).deleteMethod(id);
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

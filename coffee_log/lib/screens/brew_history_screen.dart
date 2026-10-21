import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/coffee_bean.dart';
import '../providers/brew_log_provider.dart';
import '../providers/bean_provider.dart';
import 'add_brew_screen.dart';
import '../main.dart'; // To access CoffeeColors

class BrewHistoryScreen extends ConsumerWidget {
  final CoffeeBean bean;

  const BrewHistoryScreen({super.key, required this.bean});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(brewLogProvider(bean.id!));
    // Watch beanProvider to keep remaining weight live after edits/refunds
    final activeBeans = ref.watch(beanProvider);
    final currentBean = activeBeans.maybeWhen(
      data: (beans) => beans.firstWhere((b) => b.id == bean.id, orElse: () => bean),
      orElse: () => bean,
    );

    return Scaffold(
      backgroundColor: CoffeeColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              currentBean.beanName,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Remaining: ${currentBean.currentWeight.toStringAsFixed(1)}g',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CoffeeColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: CoffeeColors.primary, size: 20),
            tooltip: 'Adjust Weight',
            onPressed: () => _showWeightAdjustModal(context, ref, currentBean),
          ),
          const SizedBox(width: 8),
        ],
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

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Repeat this exact brew
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddBrewScreen(
                                  bean: currentBean,
                                  repeatFromLog: log,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.replay,
                            color: CoffeeColors.primary,
                            size: 16,
                          ),
                          label: Text(
                            'Repeat',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: CoffeeColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Edit this brew log
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddBrewScreen(
                                  bean: currentBean,
                                  existingLog: log,
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.edit_outlined,
                            color: Colors.grey.shade700,
                            size: 16,
                          ),
                          label: Text(
                            'Edit',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Delete this brew log
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          tooltip: 'Delete Brew',
                          onPressed: () async {
                            final double doseRefunded = log.dose;
                            await BrewLogController.deleteLog(
                              ref,
                              log.id!,
                              currentBean.id!,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Deleted brew. ${doseRefunded}g refunded to ${currentBean.beanName}!',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
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
            MaterialPageRoute(
              builder: (context) => AddBrewScreen(bean: currentBean),
            ),
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
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

  void _showWeightAdjustModal(
    BuildContext context,
    WidgetRef ref,
    CoffeeBean bean,
  ) {
    final TextEditingController weightCtrl = TextEditingController(
      text: bean.currentWeight.toStringAsFixed(1),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adjust Remaining Weight',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CoffeeColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bean.beanName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Purge / Adjustment chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPurgeChip(
                        '-2g Purge',
                        () {
                          double cur =
                              double.tryParse(
                                weightCtrl.text.replaceAll(',', '.'),
                              ) ??
                              bean.currentWeight;
                          double next = (cur - 2.0).clamp(0.0, double.infinity);
                          setModalState(
                            () => weightCtrl.text = next.toStringAsFixed(1),
                          );
                        },
                      ),
                      _buildPurgeChip(
                        '-5g Purge',
                        () {
                          double cur =
                              double.tryParse(
                                weightCtrl.text.replaceAll(',', '.'),
                              ) ??
                              bean.currentWeight;
                          double next = (cur - 5.0).clamp(0.0, double.infinity);
                          setModalState(
                            () => weightCtrl.text = next.toStringAsFixed(1),
                          );
                        },
                      ),
                      _buildPurgeChip(
                        '+5g Add',
                        () {
                          double cur =
                              double.tryParse(
                                weightCtrl.text.replaceAll(',', '.'),
                              ) ??
                              bean.currentWeight;
                          double next = cur + 5.0;
                          setModalState(
                            () => weightCtrl.text = next.toStringAsFixed(1),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Text field for exact weight
                  TextField(
                    controller: weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: CoffeeColors.primary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Remaining Weight (g)',
                      labelStyle: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                      ),
                      border: const UnderlineInputBorder(),
                      suffixText: 'g',
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CoffeeColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final double newWeight =
                            double.tryParse(
                              weightCtrl.text.replaceAll(',', '.'),
                            ) ??
                            bean.currentWeight;

                        final updatedBean = CoffeeBean(
                          id: bean.id,
                          roasterName: bean.roasterName,
                          beanName: bean.beanName,
                          roastLevel: bean.roastLevel,
                          process: bean.process,
                          roastDate: bean.roastDate,
                          price: bean.price,
                          initialWeight: bean.initialWeight,
                          currentWeight: newWeight,
                          isArchived: bean.isArchived,
                          archiveStatus: bean.archiveStatus,
                          archiveNotes: bean.archiveNotes,
                        );

                        ref.read(beanProvider.notifier).updateBean(updatedBean);
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${bean.beanName} updated to ${newWeight.toStringAsFixed(1)}g',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Save Weight',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPurgeChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: CoffeeColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: CoffeeColors.textDark,
          ),
        ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/coffee_bean.dart';
import '../providers/bean_provider.dart';
import 'add_bean_screen.dart';
import 'brew_history_screen.dart';
import '../main.dart'; // Access CoffeeColors
import '../databases/database_helper.dart';

class BeanListScreen extends ConsumerStatefulWidget {
  const BeanListScreen({super.key});

  @override
  ConsumerState<BeanListScreen> createState() => _BeanListScreenState();
}

class _BeanListScreenState extends ConsumerState<BeanListScreen> {
  // Track active sub-tab (0 = Stash, 1 = Archive)
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final stashState = ref.watch(beanProvider);
    final archiveState = ref.watch(archiveProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.only(top: 110), // Clears the frosted AppBar!
        child: Column(
          children: [
            // --- SEGMENT TOGGLE (Stash vs Archive) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildSegmentButton('Stash', 0)),
                    Expanded(child: _buildSegmentButton('Archive', 1)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- CONTENT LISTS ---
            Expanded(
              child: _activeTab == 0
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
                                    builder: (context) => const AddBeanScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.add,
                                color: CoffeeColors.primary,
                              ),
                              label: Text(
                                'Add New Bean',
                                style: GoogleFonts.montserrat(
                                  color: CoffeeColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: _buildStashList(stashState)),
                      ],
                    )
                  : _buildArchiveList(archiveState),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER: Custom Sliding Toggle ---
  Widget _buildSegmentButton(String label, int index) {
    bool isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          // FIXED: Animates to a solid light grey instead of transparent to prevent muddy flashes
          color: isSelected ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? CoffeeColors.textDark : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  // --- STASH LIST (Active Inventory) ---
  Widget _buildStashList(AsyncValue<List<CoffeeBean>> stashState) {
    return stashState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CoffeeColors.primary),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (beans) {
        if (beans.isEmpty) {
          return Center(
            child: Text(
              'No active beans.\nAdd a bag to get started!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
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
                onLongPress: () =>
                    _showDeleteConfirmation(context, ref, bean, isActive: true),
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
                          // Archive Trigger Button
                          IconButton(
                            icon: const Icon(
                              Icons.archive_outlined,
                              color: CoffeeColors.primary,
                              size: 20,
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () =>
                                _showArchiveDialog(context, ref, bean),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bean.beanName,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
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
    );
  }

  // --- ARCHIVE LIST (Finished Bag History) ---
  Widget _buildArchiveList(AsyncValue<List<CoffeeBean>> archiveState) {
    return archiveState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CoffeeColors.primary),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (beans) {
        if (beans.isEmpty) {
          return Center(
            child: Text(
              'No archived beans.\nFinish some bags to see them here!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
          itemCount: beans.length,
          itemBuilder: (context, index) {
            final bean = beans[index];

            // Customize card colors based on your exact Excel sheet ratings!
            Color cardColor = Colors.white;
            Color borderColor = Colors.grey.shade200;
            IconData statusIcon = Icons.sentiment_neutral;
            Color statusColor = Colors.grey;

            if (bean.archiveStatus == 'best') {
              cardColor = const Color(0xFFF0FDF4); // Soft Green
              borderColor = Colors.green.shade200;
              statusIcon = Icons.sentiment_very_satisfied;
              statusColor = Colors.green.shade700;
            } else if (bean.archiveStatus == 'bad') {
              cardColor = const Color(0xFFFEF2F2); // Soft Red
              borderColor = Colors.red.shade200;
              statusIcon = Icons.sentiment_very_dissatisfied;
              statusColor = Colors.red.shade700;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
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
                onLongPress: () => _showDeleteConfirmation(
                  context,
                  ref,
                  bean,
                  isActive: false,
                ),
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
                              color: statusColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Icon(statusIcon, color: statusColor, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bean.beanName,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CoffeeColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Display Price and Initial Weight beautifully
                      Text(
                        'Stats: ${bean.initialWeight}g ${bean.price != null ? "• RM${bean.price!.toStringAsFixed(2)}" : ""}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      if (bean.archiveNotes != null &&
                          bean.archiveNotes!.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1, color: Color(0xFFE5E5E5)),
                        ),
                        Text(
                          '"${bean.archiveNotes}"',
                          style: GoogleFonts.inter(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI HELPER: Custom Archive Feedback Dialog ---
  void _showArchiveDialog(
    BuildContext context,
    WidgetRef ref,
    CoffeeBean bean,
  ) {
    String selectedStatus = 'normal'; // 'best', 'normal', 'bad'
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Finish this bag?',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How was this coffee?',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Row of custom status selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatusButton(
                        'best',
                        Icons.sentiment_very_satisfied,
                        Colors.green,
                        selectedStatus,
                        () => setDialogState(() => selectedStatus = 'best'),
                      ),
                      _buildStatusButton(
                        'normal',
                        Icons.sentiment_neutral,
                        Colors.grey,
                        selectedStatus,
                        () => setDialogState(() => selectedStatus = 'normal'),
                      ),
                      _buildStatusButton(
                        'bad',
                        Icons.sentiment_very_dissatisfied,
                        Colors.red,
                        selectedStatus,
                        () => setDialogState(() => selectedStatus = 'bad'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: notesCtrl,
                    style: GoogleFonts.inter(),
                    decoration: InputDecoration(
                      labelText: 'Final Notes/Comments',
                      labelStyle: GoogleFonts.inter(fontSize: 14),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
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
                    // Update bean variables to archive it
                    final archivedBean = CoffeeBean(
                      id: bean.id,
                      roasterName: bean.roasterName,
                      beanName: bean.beanName,
                      roastLevel: bean.roastLevel,
                      roastDate: bean.roastDate,
                      price: bean.price,
                      initialWeight: bean.initialWeight,
                      currentWeight: 0.0, // Wipes remaining weight
                      isArchived: true,
                      archiveStatus: selectedStatus,
                      archiveNotes: notesCtrl.text,
                    );

                    // Call the archive provider
                    ref
                        .read(archiveProvider.notifier)
                        .archiveBean(archivedBean);
                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${bean.beanName}" has been archived!'),
                      ),
                    );
                  },
                  child: Text(
                    'Archive',
                    style: GoogleFonts.inter(
                      color: CoffeeColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusButton(
    String value,
    IconData icon,
    Color color,
    String currentSelection,
    VoidCallback onTap,
  ) {
    bool isSelected = currentSelection == value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.transparent, // Updated!
          border: Border.all(color: isSelected ? color : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? color : Colors.grey.shade400,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), // Updated to .withValues!
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.1)), // Updated!
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

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    CoffeeBean bean, {
    required bool isActive,
  }) {
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
                if (isActive) {
                  ref.read(beanProvider.notifier).deleteBean(bean.id!);
                } else {
                  // If deleting from Archive tab
                  DatabaseHelper.instance.deleteCoffeeBean(bean.id!);
                  ref.invalidate(archiveProvider);
                }
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

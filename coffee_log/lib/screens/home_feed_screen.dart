import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/home_feed_provider.dart';
import '../providers/bean_provider.dart';
import '../models/brew_log.dart';
import '../models/coffee_bean.dart';
import '../main.dart'; // Access CoffeeColors

class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(homeFeedProvider);
    final beanState = ref.watch(beanProvider);

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Let background gradient glow through
      body: feedState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CoffeeColors.primary),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.coffee_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No brews logged yet.\nYour global timeline is empty!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          // Get beans to map IDs to names
          List<CoffeeBean> beans = [];
          beanState.whenData((bList) => beans = bList);
          final beanMap = {for (var b in beans) b.id: b};

          return ListView.builder(
            padding: const EdgeInsets.only(
              top: 110,
              bottom: 100,
              left: 16,
              right: 16,
            ),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final bean = beanMap[log.beanId];

              return _ExpandingFeedCard(log: log, bean: bean);
            },
          );
        },
      ),
    );
  }
}

// --- SUB-WIDGET: The Animated Expanding Card ---
class _ExpandingFeedCard extends StatefulWidget {
  final BrewLog log;
  final CoffeeBean? bean;

  const _ExpandingFeedCard({required this.log, required this.bean});

  @override
  State<_ExpandingFeedCard> createState() => _ExpandingFeedCardState();
}

class _ExpandingFeedCardState extends State<_ExpandingFeedCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final minutes = (widget.log.brewTimeSeconds ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final seconds = (widget.log.brewTimeSeconds % 60).toString().padLeft(
      2,
      '0',
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          if (_isExpanded)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TOP: Roaster & Date ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.bean?.roasterName.toUpperCase() ??
                          'UNKNOWN ROASTER',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: CoffeeColors.accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(widget.log.dateOfMaking),
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // --- MAIN: Bean Name ---
                Text(
                  widget.bean?.beanName ?? 'Deleted Bean',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CoffeeColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // --- METHOD & TEMPLATE BADGE ---
                Text(
                  widget.log.appliedMethod != null
                      ? '${widget.log.brewMethod} • ${widget.log.equipment} • ${widget.log.appliedMethod}'
                      : widget.log.brewMethod,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CoffeeColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // --- STAT BADGES ---
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatBadge(
                      Icons.water_drop,
                      Colors.blue.shade600,
                      '${widget.log.waterMass} g',
                    ),
                    _buildStatBadge(
                      Icons.grain,
                      CoffeeColors.primary,
                      '${widget.log.dose} g',
                    ),
                    _buildStatBadge(
                      Icons.access_time,
                      Colors.amber.shade700,
                      '$minutes:$seconds',
                    ),
                    _buildStatBadge(
                      Icons.local_fire_department,
                      Colors.deepOrange.shade400,
                      '${widget.log.temperature}°C',
                    ),
                  ],
                ),

                // --- EXPANDED SECTION (Tasting Notes & Sliders) ---
                if (_isExpanded) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                  ),

                  Row(
                    children: [
                      Icon(
                        Icons.settings,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.log.grinder} (${widget.log.grindSize})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '1:${widget.log.brewRatio.toStringAsFixed(1)}',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          color: CoffeeColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTasteBar('Acidity', widget.log.acidityScore),
                  _buildTasteBar('Sweetness', widget.log.sweetnessScore),
                  _buildTasteBar('Body', widget.log.bodyScore),

                  if (widget.log.tastingNotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      '"${widget.log.tastingNotes}"',
                      style: GoogleFonts.inter(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],

                // Subtle prompt indicator at the bottom
                const SizedBox(height: 8),
                Center(
                  child: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
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
                    height: 6,
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

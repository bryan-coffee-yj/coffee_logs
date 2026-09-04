import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/method_provider.dart';
import '../models/brew_method.dart';
import '../models/coffee_bean.dart';
import '../models/brew_log.dart';
import '../databases/database_helper.dart';
import '../main.dart'; // Access CoffeeColors

class ToolkitScreen extends ConsumerStatefulWidget {
  const ToolkitScreen({super.key});

  @override
  ConsumerState<ToolkitScreen> createState() => _ToolkitScreenState();
}

class _ToolkitScreenState extends ConsumerState<ToolkitScreen> {
  int _selectedTab = 0; // 0 = Ratio Calculator, 1 = Stats & Insights

  // Calculator State
  BrewMethod? _selectedMethod;
  final _doseCtrl = TextEditingController(text: '15.0');
  double _customDose = 15.0;

  @override
  void dispose() {
    _doseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final methodState = ref.watch(methodProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.only(top: 110),
        child: Column(
          children: [
            // --- TOP SEGMENT TOGGLE ---
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
                    Expanded(child: _buildSegmentButton('Ratio Scaler', 0)),
                    Expanded(child: _buildSegmentButton('Stats & Insights', 1)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- TAB CONTENT ---
            Expanded(
              child: _selectedTab == 0
                  ? _buildRatioCalculator(methodState)
                  : _buildStatsDashboard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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

  // --- SECTION 1: RATIO CALCULATOR ---
  Widget _buildRatioCalculator(AsyncValue<List<BrewMethod>> methodState) {
    return methodState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CoffeeColors.primary),
      ),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (methods) {
        if (methods.isEmpty) {
          return Center(
            child: Text(
              'Create a recipe in the Methods tab first to use the scaler!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey.shade500),
            ),
          );
        }

        _selectedMethod ??= methods.first;
        final scaleFactor = _customDose / _selectedMethod!.defaultDose;
        final totalScaledWater = _selectedMethod!.defaultWater * scaleFactor;
        double cumulativeWater = 0.0;

        return ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
          children: [
            // Recipe Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BrewMethod>(
                  value: _selectedMethod,
                  isExpanded: true,
                  items: methods
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                            m.methodName,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (m) => setState(() => _selectedMethod = m),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dose Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR TARGET DOSE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: CoffeeColors.accent,
                          ),
                        ),
                        TextField(
                          controller: _doseCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: CoffeeColors.textDark,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            suffixText: 'g',
                          ),
                          onChanged: (v) {
                            setState(() {
                              _customDose =
                                  double.tryParse(v.replaceAll(',', '.')) ??
                                  0.0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TARGET WATER',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CoffeeColors.accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${totalScaledWater.toStringAsFixed(1)}g',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CoffeeColors.primary,
                        ),
                      ),
                      Text(
                        '1:${_selectedMethod!.targetRatio.toStringAsFixed(1)} Ratio',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'SCALED SCALE TARGETS',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: CoffeeColors.accent,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Scaled Steps Table
            ..._selectedMethod!.steps.map((step) {
              final stepWater = step.waterAmount * scaleFactor;
              cumulativeWater += stepWater;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      step.type,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (step.waterAmount > 0)
                      Text(
                        'Pour ${stepWater.toStringAsFixed(1)}g  ➔  Scale: ${cumulativeWater.toStringAsFixed(1)}g',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: CoffeeColors.primary,
                          fontSize: 13,
                        ),
                      )
                    else
                      Text(
                        'Wait ${step.durationSeconds}s',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // --- SECTION 2: STATS DASHBOARD ---
  Widget _buildStatsDashboard() {
    return FutureBuilder(
      future: Future.wait([
        DatabaseHelper.instance.getAllCoffeeBeans(),
        DatabaseHelper.instance.getAllBrewLogs(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (!snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: CoffeeColors.primary),
          );

        final List<CoffeeBean> beans = snapshot.data![0] as List<CoffeeBean>;
        final List<BrewLog> logs = snapshot.data![1] as List<BrewLog>;

        double totalSpent = beans.fold(0.0, (sum, b) => sum + (b.price ?? 0.0));
        double totalGramsBrewed = logs.fold(0.0, (sum, l) => sum + l.dose);
        double avgCostPerCup = logs.isNotEmpty && totalSpent > 0
            ? (totalSpent / logs.length)
            : 0.0;

        return ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Spent',
                    'RM ${totalSpent.toStringAsFixed(2)}',
                    Icons.payments_outlined,
                    Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Coffee Brewed',
                    '${(totalGramsBrewed / 1000).toStringAsFixed(2)} kg',
                    Icons.coffee,
                    CoffeeColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Bags',
                    '${beans.length} Bags',
                    Icons.inventory_2_outlined,
                    Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Avg / Cup',
                    'RM ${avgCostPerCup.toStringAsFixed(2)}',
                    Icons.local_cafe_outlined,
                    Colors.deepOrange.shade400,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            radius: 18,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CoffeeColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

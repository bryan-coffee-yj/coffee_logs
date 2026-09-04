import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../models/brew_method.dart';
import '../providers/method_provider.dart';
import '../models/coffee_bean.dart';
import '../models/brew_log.dart';
import '../databases/database_helper.dart';
import '../providers/brew_log_provider.dart';
import '../providers/bean_provider.dart'; // Needed to refresh home screen weight
import '../main.dart';

class AddBrewScreen extends ConsumerStatefulWidget {
  final CoffeeBean bean;
  const AddBrewScreen({super.key, required this.bean});

  @override
  ConsumerState<AddBrewScreen> createState() => _AddBrewScreenState();
}

class _AddBrewScreenState extends ConsumerState<AddBrewScreen> {
  bool _isLoading = true;

  BrewMethod? _selectedMethod;

  // State Variables
  String _brewMethod = 'Pour-over';
  String _equipment = 'V60';
  String _grinder = 'C3Esp Pro';
  String _grindSize = '1.6.0';
  double _dose = 15.0;
  double _waterMass = 250.0;
  double _temperature = 93.0;
  int _timeMin = 2;
  int _timeSec = 30;

  double _acidity = 3;
  double _sweetness = 3;
  double _body = 3;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreviousBrew();
  }

  // Barista Quick-Log Logic
  Future<void> _loadPreviousBrew() async {
    final lastLog = await DatabaseHelper.instance.getLatestBrewLogForBean(
      widget.bean.id!,
    );
    if (lastLog != null) {
      setState(() {
        _brewMethod = lastLog.brewMethod;
        _equipment = lastLog.equipment;
        _grinder = lastLog.grinder;
        _grindSize = lastLog.grindSize;
        // Notice we DO NOT load the previous dose/water here anymore,
        // because you'll select a template instead!
      });
    }
    setState(() => _isLoading = false);
  }

  void _applyMethodTemplate(BrewMethod method) {
    setState(() {
      _selectedMethod = method;
      _brewMethod = method.brewMethodType;
      _dose = method.defaultDose;
      _waterMass = method.defaultWater;
      _timeMin = method.totalTargetTimeSeconds ~/ 60;
      _timeSec = method.totalTargetTimeSeconds % 60;
    });
  }

  void _saveBrew() async {
    final newLog = BrewLog(
      beanId: widget.bean.id!,
      dateOfMaking: DateTime.now(),
      brewMethod: _brewMethod,
      appliedMethod:
          _selectedMethod?.methodName, // <--- NEW: Grabs the template name!
      equipment: _equipment,
      grinder: _grinder,
      grindSize: _grindSize,
      dose: _dose,
      waterMass: _waterMass,
      temperature: _temperature,
      brewTimeSeconds: (_timeMin * 60) + _timeSec,
      acidityScore: _acidity.toInt(),
      sweetnessScore: _sweetness.toInt(),
      bodyScore: _body.toInt(),
      tastingNotes: _notesCtrl.text,
    );

    // Save logic that triggers the inventory math!
    await BrewLogController.addLog(ref, newLog, widget.bean);

    // Refresh the home screen so the remaining weight updates instantly
    ref.invalidate(beanProvider);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      extendBodyBehindAppBar:
          true, // Lets gradient canvas flow under the header!
      // --- FROSTED GLASS APPBAR ---
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              scrolledUnderElevation: 0.0, // Kills the grey scroll tint!
              title: const Text('Prepare Recipe'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save, color: CoffeeColors.primary),
                  onPressed: _saveBrew,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),

      // --- GRADIENT CANVAS + DASHBOARD BODY ---
      body: Stack(
        children: [
          // 1. Soft organic warm milk gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFFFFBF0), Color(0xFFF5EFE6)],
              ),
            ),
          ),

          // 2. The Content with safe top padding to clear the glass header
          ListView(
            padding: const EdgeInsets.only(
              top: 110,
              bottom: 40,
              left: 20,
              right: 20,
            ),
            children: [
              // Header
              Text(
                widget.bean.beanName,
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CoffeeColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Remaining: ${widget.bean.currentWeight.toStringAsFixed(1)}g',
                    style: GoogleFonts.inter(
                      color: CoffeeColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• ${widget.bean.process}',
                    style: GoogleFonts.inter(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // --- TEMPLATE SELECTOR ---
              Consumer(
                builder: (context, ref, child) {
                  final methodsState = ref.watch(methodProvider);
                  return methodsState.when(
                    loading: () => const SizedBox(),
                    error: (e, s) => const SizedBox(),
                    data: (methods) {
                      if (methods.isEmpty) return const SizedBox();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CoffeeColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CoffeeColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<BrewMethod>(
                            isExpanded: true,
                            hint: Text(
                              'Apply Saved Recipe...',
                              style: GoogleFonts.inter(
                                color: CoffeeColors.primary,
                              ),
                            ),
                            value: _selectedMethod,
                            icon: const Icon(
                              Icons.auto_awesome,
                              color: CoffeeColors.primary,
                              size: 18,
                            ),
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
                            onChanged: (method) {
                              if (method != null) _applyMethodTemplate(method);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // --- BREW METHOD & EQUIPMENT ---
              Row(
                children: [
                  // Method Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CoffeeColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _brewMethod,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: CoffeeColors.primary,
                          ),
                          style: GoogleFonts.inter(
                            color: CoffeeColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          items:
                              [
                                    'Pour-over',
                                    'Espresso',
                                    'Moka Pot',
                                    'French Press',
                                    'Aeropress',
                                  ]
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) =>
                              setState(() => _brewMethod = val!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Equipment Input (Uses the same Bottom Sheet modal!)
                  Expanded(
                    child: InkWell(
                      onTap: () => _showInputDialog(
                        title: 'Brewer / Equipment',
                        initialValue: _equipment,
                        isNumber: false,
                        onSave: (v) => setState(() => _equipment = v),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: CoffeeColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _equipment,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: CoffeeColors.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.edit,
                              size: 14,
                              color: CoffeeColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- THE 2x2 PREMIUM GRID ---
              Row(
                children: [
                  Expanded(
                    child: _buildGridCard(
                      title: 'Coffee Amount',
                      value: '$_dose g',
                      icon: Icons
                          .coffee, // Note: using grain as fallback if coffee_bean isn't in your icon pack
                      color: CoffeeColors.primary,
                      onTap: () => _showInputDialog(
                        title: 'Coffee Amount (g)',
                        initialValue: _dose.toString(),
                        isNumber: true,
                        onSave: (v) {
                          double newDose = double.parse(v);
                          setState(() {
                            // SMART SCALING: If a method is selected, keep the exact same ratio!
                            if (_selectedMethod != null) {
                              _waterMass = double.parse(
                                (newDose * _selectedMethod!.targetRatio)
                                    .toStringAsFixed(1),
                              );
                            }
                            _dose = newDose;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGridCard(
                      title: 'Water Amount',
                      value: '$_waterMass ml',
                      icon: Icons.water_drop,
                      color: Colors.blue.shade600,
                      onTap: () => _showInputDialog(
                        title: 'Water Amount (ml)',
                        initialValue: _waterMass.toString(),
                        isNumber: true,
                        onSave: (v) =>
                            setState(() => _waterMass = double.parse(v)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildGridCard(
                      title: _grinder, // Dynamically shows your grinder name!
                      value: _grindSize,
                      icon: Icons.settings,
                      color: Colors.green.shade600,
                      onTap: _showGrinderDialog, // Calls our new custom modal
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGridCard(
                      title: 'Heat',
                      value: '$_temperature°C',
                      icon: Icons.local_fire_department,
                      color: Colors.deepOrange.shade500,
                      onTap: () => _showInputDialog(
                        title: 'Temperature (°C)',
                        initialValue: _temperature.toString(),
                        isNumber: true,
                        onSave: (v) =>
                            setState(() => _temperature = double.parse(v)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- TIME & PROCESS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROCESS',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showTimeDialog(),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${_timeMin.toString().padLeft(2, '0')}:${_timeSec.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- TASTING SLIDERS ---
              Text(
                'TASTING PROFILE',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildSlider(
                'Acidity',
                _acidity,
                (v) => setState(() => _acidity = v),
              ),
              _buildSlider(
                'Sweetness',
                _sweetness,
                (v) => setState(() => _sweetness = v),
              ),
              _buildSlider('Body', _body, (v) => setState(() => _body = v)),
              const SizedBox(height: 24),

              // Notes
              Container(
                decoration: BoxDecoration(
                  color: CoffeeColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  style: GoogleFonts.inter(),
                  decoration: InputDecoration(
                    hintText: 'Add Tag / Tasting Notes...',
                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                    prefixIcon: const Icon(
                      Icons.sell_outlined,
                      color: CoffeeColors.primary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }

  void _showGrinderDialog() {
    final TextEditingController grinderCtrl = TextEditingController(
      text: _grinder,
    );
    final TextEditingController sizeCtrl = TextEditingController(
      text: _grindSize,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                'Grinder Settings',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 1. Grinder Name Input
              TextField(
                controller: grinderCtrl,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Grinder (e.g., Comandante C40)',
                  labelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  border: const UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Grind Size Input (Accepts TEXT, so any format works!)
              TextField(
                controller: sizeCtrl,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CoffeeColors.primary,
                ),
                decoration: InputDecoration(
                  labelText: 'Grind Size (e.g., 25 Clicks, 1.6.0)',
                  labelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  border: const UnderlineInputBorder(),
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
                  ),
                  onPressed: () {
                    setState(() {
                      _grinder = grinderCtrl.text.isEmpty
                          ? 'Unknown Grinder'
                          : grinderCtrl.text;
                      _grindSize = sizeCtrl.text;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // --- UI HELPER: Premium 2x2 Grid Card ---
  // --- UI HELPER: Premium 2x2 Grid Card ---
  Widget _buildGridCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // The colored stripe on the left
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and Title Row
                  Row(
                    children: [
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // The Big Number
                  Text(
                    value,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CoffeeColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER: Bottom Sheet Modal for clean data entry ---
  void _showInputDialog({
    required String title,
    required String initialValue,
    required bool isNumber,
    required Function(String) onSave,
  }) {
    final TextEditingController ctrl = TextEditingController(
      text: initialValue,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Moves up with keyboard
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                'Edit $title',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: isNumber
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoffeeColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    onSave(
                      ctrl.text.replaceAll(',', '.'),
                    ); // Handle commas as dots
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // --- UI HELPER: Custom Time Modal ---
  void _showTimeDialog() {
    _showInputDialog(
      title: 'Time (Seconds)',
      initialValue: ((_timeMin * 60) + _timeSec).toString(),
      isNumber: true,
      onSave: (v) {
        int totalSecs = int.tryParse(v) ?? 0;
        setState(() {
          _timeMin = totalSecs ~/ 60;
          _timeSec = totalSecs % 60;
        });
      },
    );
  }

  // --- UI HELPER: Clean Slider ---
  Widget _buildSlider(String label, double value, Function(double) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: CoffeeColors.primary,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: CoffeeColors.primary,
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

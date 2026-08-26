import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/brew_method.dart';
import '../providers/method_provider.dart';
import '../main.dart'; // Access CoffeeColors

class AddMethodScreen extends ConsumerStatefulWidget {
  const AddMethodScreen({super.key});

  @override
  ConsumerState<AddMethodScreen> createState() => _AddMethodScreenState();
}

class _AddMethodScreenState extends ConsumerState<AddMethodScreen> {
  final _formKey = GlobalKey<FormState>();

  String _methodName = '';
  String _brewType = 'Pour-over';
  double _defaultDose = 15.0;
  double _defaultWater = 250.0;

  // The list holding our custom steps
  List<MethodStep> _steps = [];

  void _saveMethod() {
    if (_formKey.currentState!.validate()) {
      if (_steps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one step!')),
        );
        return;
      }

      _formKey.currentState!.save();

      final newMethod = BrewMethod(
        methodName: _methodName,
        brewMethodType: _brewType,
        defaultDose: _defaultDose,
        defaultWater: _defaultWater,
        steps: _steps,
      );

      ref.read(methodProvider.notifier).addMethod(newMethod);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total time visually
    final totalSecs = _steps.fold(0, (sum, s) => sum + s.durationSeconds);
    final min = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final sec = (totalSecs % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: CoffeeColors.background,
      appBar: AppBar(
        title: const Text('Create Recipe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: CoffeeColors.primary),
            onPressed: _saveMethod,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'BASIC DETAILS',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: CoffeeColors.accent,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Name Input
            _buildInputField(
              label: 'Recipe Name (e.g. Hoffmann V60)',
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _methodName = v!,
            ),
            const SizedBox(height: 16),

            // Default Ratios
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Coffee Dose (g)',
                    initial: '15',
                    isNumber: true,
                    onSaved: (v) => _defaultDose = double.tryParse(v!) ?? 15.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    label: 'Target Water (g)',
                    initial: '250',
                    isNumber: true,
                    onSaved: (v) =>
                        _defaultWater = double.tryParse(v!) ?? 250.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PROCESS STEPS',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CoffeeColors.accent,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Total: $min:$sec',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: CoffeeColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // The Step List
            if (_steps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No steps added yet.',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ),
              ),

            ..._steps.asMap().entries.map((entry) {
              int index = entry.key;
              MethodStep step = entry.value;
              return _buildStepCard(step, index);
            }),

            const SizedBox(height: 24),

            // Add Step Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: CoffeeColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  _showStepBuilderModal(), // Opens our Dynamic Modal!
              icon: const Icon(Icons.add, color: CoffeeColors.primary),
              label: Text(
                'Add New Step',
                style: GoogleFonts.montserrat(
                  color: CoffeeColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER: A single Step Card ---
  Widget _buildStepCard(MethodStep step, int index) {
    IconData stepIcon = Icons.water_drop;
    if (step.type == 'Wait') stepIcon = Icons.timer_outlined;
    if (step.type == 'Swirl') stepIcon = Icons.cyclone;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: CoffeeColors.surface,
          child: Icon(stepIcon, color: CoffeeColors.primary, size: 20),
        ),
        title: Text(
          '${index + 1}. ${step.type}',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          step.waterAmount > 0
              ? 'Pour ${step.waterAmount}g • ${step.durationSeconds}s'
              : '${step.durationSeconds} seconds',
          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
          onPressed: () => setState(() => _steps.removeAt(index)),
        ),
      ),
    );
  }

  // --- THE MAGIC: DYNAMIC STEP BUILDER MODAL ---
  void _showStepBuilderModal() {
    String selectedType = 'Pour';
    final waterCtrl = TextEditingController();
    final timeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          // StatefulBuilder allows the modal to update its UI when icons are tapped!
          builder: (BuildContext context, StateSetter setModalState) {
            bool needsWater =
                (selectedType == 'Pour' || selectedType == 'Bloom');

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
                    'Add Process Step',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Icon Selector Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTypeSelector(
                        'Pour',
                        Icons.water_drop,
                        selectedType,
                        () => setModalState(() => selectedType = 'Pour'),
                      ),
                      _buildTypeSelector(
                        'Bloom',
                        Icons.filter_vintage,
                        selectedType,
                        () => setModalState(() => selectedType = 'Bloom'),
                      ),
                      _buildTypeSelector(
                        'Wait',
                        Icons.timer_outlined,
                        selectedType,
                        () => setModalState(() => selectedType = 'Wait'),
                      ),
                      _buildTypeSelector(
                        'Swirl',
                        Icons.cyclone,
                        selectedType,
                        () => setModalState(() => selectedType = 'Swirl'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Dynamic Inputs
                  if (needsWater) ...[
                    TextField(
                      controller: waterCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Water Amount (g)',
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: timeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (seconds)',
                      border: UnderlineInputBorder(),
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
                          _steps.add(
                            MethodStep(
                              type: selectedType,
                              waterAmount: needsWater
                                  ? (double.tryParse(waterCtrl.text) ?? 0.0)
                                  : 0.0,
                              durationSeconds: int.tryParse(timeCtrl.text) ?? 0,
                            ),
                          );
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Add to Recipe',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
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

  Widget _buildTypeSelector(
    String label,
    IconData icon,
    String currentSelection,
    VoidCallback onTap,
  ) {
    bool isSelected = currentSelection == label;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: isSelected
                ? CoffeeColors.primary
                : CoffeeColors.surface,
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? CoffeeColors.textDark : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    String? initial,
    bool isNumber = false,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CoffeeColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        initialValue: initial,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}

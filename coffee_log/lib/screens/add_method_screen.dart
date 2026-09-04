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

  // NEW: Persistent Controllers to prevent text from wiping!
  final _nameCtrl = TextEditingController();
  final _equipmentCtrl = TextEditingController();
  final _doseCtrl = TextEditingController(text: '15.0');
  final _waterCtrl = TextEditingController(text: '250.0');

  String _brewType = 'Pour-over';
  final List<MethodStep> _steps = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _equipmentCtrl.dispose();
    _doseCtrl.dispose();
    _waterCtrl.dispose();
    super.dispose();
  }

  void _saveMethod() {
    if (_formKey.currentState!.validate()) {
      if (_steps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one step!')),
        );
        return;
      }

      final newMethod = BrewMethod(
        methodName: _nameCtrl.text,
        brewMethodType: _brewType,
        equipment: _equipmentCtrl.text.isEmpty
            ? 'Unknown Brewer'
            : _equipmentCtrl.text,
        defaultDose:
            double.tryParse(_doseCtrl.text.replaceAll(',', '.')) ?? 15.0,
        defaultWater:
            double.tryParse(_waterCtrl.text.replaceAll(',', '.')) ?? 250.0,
        steps: _steps,
      );

      ref.read(methodProvider.notifier).addMethod(newMethod);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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

            _buildInputField(
              controller: _nameCtrl,
              label: 'Recipe Name (e.g. The Devil\'s Recipe)',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CoffeeColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _brewType,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: CoffeeColors.primary,
                        ),
                        style: GoogleFonts.inter(
                          color: CoffeeColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
                        onChanged: (value) =>
                            setState(() => _brewType = value!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    controller: _equipmentCtrl,
                    label: 'Brewer (e.g. V60)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _doseCtrl,
                    label: 'Coffee Dose (g)',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    controller: _waterCtrl,
                    label: 'Target Water (g)',
                    isNumber: true,
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

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: CoffeeColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showStepBuilderModal(),
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

  Widget _buildStepCard(MethodStep step, int index) {
    IconData stepIcon = Icons.water_drop;
    if (step.type == 'Wait') stepIcon = Icons.timer_outlined;
    if (step.type == 'Swirl') stepIcon = Icons.cyclone;
    if (step.type == 'Bloom') stepIcon = Icons.filter_vintage;

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

void _showStepBuilderModal() {
    String selectedType = 'Pour';
    final waterCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final notesCtrl = TextEditingController(); // NEW: Notes controller

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool needsWater = (selectedType == 'Pour' || selectedType == 'Bloom');

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Process Step', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTypeSelector('Pour', Icons.water_drop, selectedType, () => setModalState(() => selectedType = 'Pour')),
                      _buildTypeSelector('Bloom', Icons.filter_vintage, selectedType, () => setModalState(() => selectedType = 'Bloom')),
                      _buildTypeSelector('Wait', Icons.timer_outlined, selectedType, () => setModalState(() => selectedType = 'Wait')),
                      _buildTypeSelector('Swirl', Icons.cyclone, selectedType, () => setModalState(() => selectedType = 'Swirl')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (needsWater) ...[
                    TextField(
                      controller: waterCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Water Amount (g)', border: UnderlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  TextField(
                    controller: timeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Duration (seconds)', border: UnderlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  // NEW: Instruction / Step Notes Field
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Step Instruction (Optional)',
                      hintText: 'e.g. Pour in concentric circles',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: CoffeeColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () {
                        setState(() {
                          _steps.add(MethodStep(
                            type: selectedType,
                            waterAmount: needsWater ? (double.tryParse(waterCtrl.text.replaceAll(',', '.')) ?? 0.0) : 0.0,
                            durationSeconds: int.tryParse(timeCtrl.text) ?? 0,
                            notes: notesCtrl.text, // Saved to step!
                          ));
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Add to Recipe', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
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
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CoffeeColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller, // Linked directly to our persistent controller!
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: GoogleFonts.inter(
          color: CoffeeColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        validator: validator,
      ),
    );
  }
}

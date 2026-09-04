import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/coffee_bean.dart';
import '../providers/bean_provider.dart';
import '../main.dart'; // To access CoffeeColors

class AddBeanScreen extends ConsumerStatefulWidget {
  const AddBeanScreen({super.key});

  @override
  ConsumerState<AddBeanScreen> createState() => _AddBeanScreenState();
}

class _AddBeanScreenState extends ConsumerState<AddBeanScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Variables
  String _roasterName = '';
  String _beanName = '';
  String _roastLevel = 'Light';
  String _process = 'Washed';
  DateTime _roastDate = DateTime.now();
  double _weight = 0.0;
  double? _price;

  final List<String> _roastLevels = [
    'Light',
    'Medium-Light',
    'Medium',
    'Medium-Dark',
    'Dark',
  ];

  void _saveBean() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newBean = CoffeeBean(
        roasterName: _roasterName,
        beanName: _beanName,
        roastLevel: _roastLevel,
        process: _process, // NEW
        roastDate: _roastDate,
        initialWeight: _weight,
        currentWeight: _weight, // When you buy it, current = initial
        price: _price,
      );

      ref.read(beanProvider.notifier).addBean(newBean);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Beans')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // We use Montserrat for Section Headers
            Text(
              'COFFEE DETAILS',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: CoffeeColors.accent,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            _buildInputField(
              label: 'Roaster Name',
              hint: 'e.g., Ghostbird Coffee Roasters',
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _roasterName = v!,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              label: 'Bean Name',
              hint: 'e.g., Milkyway Classic',
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _beanName = v!,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              label: 'Process Method',
              hint: 'e.g., Thermal Shock, Anaerobic, Washed',
              onSaved: (v) => _process = (v != null && v.trim().isNotEmpty)
                  ? v.trim()
                  : 'Washed',
            ),
            const SizedBox(height: 16),

            // Custom Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: CoffeeColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: _roastLevel,
                  decoration: const InputDecoration(border: InputBorder.none),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: CoffeeColors.primary,
                  ),
                  style: GoogleFonts.inter(
                    color: CoffeeColors.textDark,
                    fontSize: 16,
                  ),
                  items: _roastLevels.map((level) {
                    return DropdownMenuItem(value: level, child: Text(level));
                  }).toList(),
                  onChanged: (value) => setState(() => _roastLevel = value!),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'PURCHASE & INVENTORY',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: CoffeeColors.accent,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Weight (g)',
                    hint: 'e.g., 200',
                    isNumber: true,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onSaved: (v) => _weight =
                        double.tryParse(v!.replaceAll(',', '.')) ?? 0.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    label: 'Price',
                    hint: 'Optional',
                    isNumber: true,
                    onSaved: (v) => _price = v!.isEmpty
                        ? null
                        : double.tryParse(v.replaceAll(',', '.')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Custom Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _roastDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: CoffeeColors.primary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) setState(() => _roastDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CoffeeColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Roast Date',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(_roastDate),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: CoffeeColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Premium Save Button
            ElevatedButton(
              onPressed: _saveBean,
              style: ElevatedButton.styleFrom(
                backgroundColor: CoffeeColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Save Beans',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: Clean, borderless input fields ---
  Widget _buildInputField({
    required String label,
    required String hint,
    bool isNumber = false,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CoffeeColors.surface, // Light grey background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: GoogleFonts.inter(color: CoffeeColors.textDark, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          border: InputBorder.none, // Kills the ugly underline!
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

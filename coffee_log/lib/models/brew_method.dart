import 'dart:convert';

class BrewMethod {
  final int? id;
  final String methodName; // e.g., "Hoffmann V60 1-Cup"
  final String brewMethodType; // e.g., "Pour-over", "Espresso"
  final String equipment; // NEW: e.g., "V60", "Solo Dripper"
  final double defaultDose; // Default target coffee (g)
  final double defaultWater; // Default target water (ml)
  final List<MethodStep> steps; // List of our customizable pour steps

  BrewMethod({
    this.id,
    required this.methodName,
    required this.brewMethodType,
    required this.equipment, // NEW
    required this.defaultDose,
    required this.defaultWater,
    required this.steps,
  });

  // Dynamic Getter: Automatically calculates target time by summing up step seconds!
  int get totalTargetTimeSeconds {
    return steps.fold(0, (sum, step) => sum + step.durationSeconds);
  }

  // Barista Helper: Automatically calculates target ratio
  double get targetRatio => defaultWater / defaultDose;

  // Convert to Map for SQLite (Serializes the steps list into a JSON string)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'methodName': methodName,
      'brewMethodType': brewMethodType,
      'equipment': equipment, // NEW
      'defaultDose': defaultDose,
      'defaultWater': defaultWater,
      'stepsJson': jsonEncode(steps.map((s) => s.toMap()).toList()),
    };
  }

  // Convert from SQLite Map back to Dart Object (Deserializes JSON string)
  factory BrewMethod.fromMap(Map<String, dynamic> map) {
    final List<dynamic> decodedSteps = jsonDecode(map['stepsJson'] as String);
    final List<MethodStep> stepsList = decodedSteps
        .map((s) => MethodStep.fromMap(s as Map<String, dynamic>))
        .toList();

    return BrewMethod(
      id: map['id'] as int?,
      methodName: map['methodName'] as String,
      brewMethodType: map['brewMethodType'] as String,
      equipment:
          map['equipment'] as String? ??
          'Unknown Brewer', // NEW (with safe fallback)
      defaultDose: (map['defaultDose'] as num).toDouble(),
      defaultWater: (map['defaultWater'] as num).toDouble(),
      steps: stepsList,
    );
  }
}

// --- HELPER CLASS FOR INDIVIDUAL STEPS ---
class MethodStep {
  final String type; // "Pour", "Bloom", "Wait", "Swirl", "Stir"
  final double
  waterAmount; // Amount of water (ml) added during this step (0.0 for wait/swirl)
  final int durationSeconds; // Duration of this step in seconds
  final String notes; // e.g., "Pour slowly in circles"

  MethodStep({
    required this.type,
    this.waterAmount = 0.0,
    required this.durationSeconds,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'waterAmount': waterAmount,
      'durationSeconds': durationSeconds,
      'notes': notes,
    };
  }

  factory MethodStep.fromMap(Map<String, dynamic> map) {
    return MethodStep(
      type: map['type'] as String,
      waterAmount: (map['waterAmount'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: map['durationSeconds'] as int,
      notes: map['notes'] as String? ?? '',
    );
  }
}

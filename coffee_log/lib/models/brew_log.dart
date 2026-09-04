class BrewLog {
  final int? id;
  final int beanId;
  final int? methodId; // Links to Method Template (nullable)
  final String? appliedMethod; // Unified to appliedMethod
  final DateTime dateOfMaking;

  final String brewMethod;
  final String equipment;
  final String grinder;
  final String grindSize;

  final double dose;
  final double waterMass;
  final double temperature;
  final int brewTimeSeconds;

  final int acidityScore;
  final int sweetnessScore;
  final int bodyScore;
  final String tastingNotes;

  BrewLog({
    this.id,
    required this.beanId,
    this.methodId,
    this.appliedMethod, // Corrected
    required this.dateOfMaking,
    required this.brewMethod,
    required this.equipment,
    required this.grinder,
    required this.grindSize,
    required this.dose,
    required this.waterMass,
    required this.temperature,
    required this.brewTimeSeconds,
    required this.acidityScore,
    required this.sweetnessScore,
    required this.bodyScore,
    required this.tastingNotes,
  });

  double get brewRatio => waterMass / dose;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'beanId': beanId,
      'methodId': methodId,
      'appliedMethod': appliedMethod, // Corrected
      'dateOfMaking': dateOfMaking.toIso8601String(),
      'brewMethod': brewMethod,
      'equipment': equipment,
      'grinder': grinder,
      'grindSize': grindSize,
      'dose': dose,
      'waterMass': waterMass,
      'temperature': temperature,
      'brewTimeSeconds': brewTimeSeconds,
      'acidityScore': acidityScore,
      'sweetnessScore': sweetnessScore,
      'bodyScore': bodyScore,
      'tastingNotes': tastingNotes,
    };
  }

  factory BrewLog.fromMap(Map<String, dynamic> map) {
    return BrewLog(
      id: map['id'] as int?,
      beanId: map['beanId'] as int,
      methodId: map['methodId'] as int?,
      appliedMethod: map['appliedMethod'] as String?, // Corrected
      dateOfMaking: DateTime.parse(map['dateOfMaking'] as String),
      brewMethod: map['brewMethod'] as String,
      equipment: map['equipment'] as String,
      grinder: map['grinder'] as String,
      grindSize: map['grindSize'] as String,
      dose: (map['dose'] as num).toDouble(),
      waterMass: (map['waterMass'] as num).toDouble(),
      temperature: (map['temperature'] as num).toDouble(),
      brewTimeSeconds: map['brewTimeSeconds'] as int,
      acidityScore: map['acidityScore'] as int,
      sweetnessScore: map['sweetnessScore'] as int,
      bodyScore: map['bodyScore'] as int,
      tastingNotes: map['tastingNotes'] as String,
    );
  }
}

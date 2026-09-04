class CoffeeBean {
  final int? id;
  final String roasterName;
  final String beanName;
  final String roastLevel;
  final String process; // NEW: Washed, Natural, Anaerobic, etc.
  final DateTime roastDate;

  final double? price;
  final double initialWeight;
  final double currentWeight;
  final bool isArchived;
  final String? archiveStatus;
  final String? archiveNotes;

  CoffeeBean({
    this.id,
    required this.roasterName,
    required this.beanName,
    required this.roastLevel,
    this.process = 'Washed', // Default to Washed
    required this.roastDate,
    this.price,
    this.initialWeight = 0.0,
    this.currentWeight = 0.0,
    this.isArchived = false,
    this.archiveStatus,
    this.archiveNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roasterName': roasterName,
      'beanName': beanName,
      'roastLevel': roastLevel,
      'process': process, // NEW
      'roastDate': roastDate.toIso8601String(),
      'price': price,
      'initialWeight': initialWeight,
      'currentWeight': currentWeight,
      'isArchived': isArchived ? 1 : 0,
      'archiveStatus': archiveStatus,
      'archiveNotes': archiveNotes,
    };
  }

  factory CoffeeBean.fromMap(Map<String, dynamic> map) {
    return CoffeeBean(
      id: map['id'] as int?,
      roasterName: map['roasterName'] as String,
      beanName: map['beanName'] as String,
      roastLevel: map['roastLevel'] as String,
      process: map['process'] as String? ?? 'Washed', // NEW (safe fallback)
      roastDate: DateTime.parse(
        map['dateOfMaking'] ?? map['roastDate'] as String,
      ),
      price: map['price'] as double?,
      initialWeight: (map['initialWeight'] as num?)?.toDouble() ?? 0.0,
      currentWeight: (map['currentWeight'] as num?)?.toDouble() ?? 0.0,
      isArchived: (map['isArchived'] as int?) == 1,
      archiveStatus: map['archiveStatus'] as String?,
      archiveNotes: map['archiveNotes'] as String?,
    );
  }
}

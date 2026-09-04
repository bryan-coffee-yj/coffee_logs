class CoffeeBean {
  final int? id;
  final String roasterName;
  final String beanName;
  final String roastLevel;
  final DateTime roastDate;

  // INVENTORY & ARCHIVE FIELDS
  final double? price;
  final double initialWeight;
  final double currentWeight;
  final bool isArchived; // true = Archived, false = Active Stash
  final String? archiveStatus; // "best", "normal", "bad"
  final String? archiveNotes; // Custom final thoughts on the bean

  CoffeeBean({
    this.id,
    required this.roasterName,
    required this.beanName,
    required this.roastLevel,
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
      'roastDate': roastDate.toIso8601String(),
      'price': price,
      'initialWeight': initialWeight,
      'currentWeight': currentWeight,
      'isArchived': isArchived ? 1 : 0, // SQLite stores bools as 1 or 0
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
      roastDate: DateTime.parse(map['roastDate'] as String),
      price: map['price'] as double?,
      initialWeight: (map['initialWeight'] as num?)?.toDouble() ?? 0.0,
      currentWeight: (map['currentWeight'] as num?)?.toDouble() ?? 0.0,
      isArchived: (map['isArchived'] as int?) == 1,
      archiveStatus: map['archiveStatus'] as String?,
      archiveNotes: map['archiveNotes'] as String?,
    );
  }
}

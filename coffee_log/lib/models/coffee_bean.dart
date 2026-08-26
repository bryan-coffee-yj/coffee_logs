class CoffeeBean {
  final int? id;
  final String roasterName;
  final String beanName;
  final String roastLevel;
  final DateTime roastDate;

  // NEW INVENTORY FIELDS
  final double? price;
  final double initialWeight;
  final double currentWeight;

  CoffeeBean({
    this.id,
    required this.roasterName,
    required this.beanName,
    required this.roastLevel,
    required this.roastDate,
    this.price,
    this.initialWeight = 0.0,
    this.currentWeight = 0.0,
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
    );
  }
}

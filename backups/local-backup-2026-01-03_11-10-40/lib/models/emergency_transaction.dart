class EmergencyTransaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;

  const EmergencyTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
  });

  factory EmergencyTransaction.fromJson(Map<String, dynamic> json) {
    return EmergencyTransaction(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  EmergencyTransaction copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
  }) {
    return EmergencyTransaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}

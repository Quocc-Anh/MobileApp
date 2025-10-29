import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String categoryId;
  final double amountLimit;
  final Timestamp date;

  Budget({
    required this.id,
    required this.categoryId,
    required this.amountLimit,
    required this.date,
  });


  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'amountLimit': amountLimit,
      'date': date,
    };
  }


  factory Budget.fromJson(String id, Map<String, dynamic> json) {
    return Budget(
      id: id,
      categoryId: json['categoryId'] as String,
      amountLimit: (json['amountLimit'] as num).toDouble(),
      date: json['date'] as Timestamp,
    );
  }
}
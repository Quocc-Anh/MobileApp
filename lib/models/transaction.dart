import 'package:cloud_firestore/cloud_firestore.dart';

class MyTransaction {
  final String id;
  final String categoryId;
  final String accountId;
  final String note;
  final double amount;
  final DateTime date;

  MyTransaction({
    required this.id,
    required this.categoryId,
    required this.accountId,
    required this.note,
    required this.amount,
    required this.date,
  });


  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'accountId': accountId,
      'note': note,
      'amount': amount,
      'date': Timestamp.fromDate(date),
    };
  }


  factory MyTransaction.fromJson(String id, Map<String, dynamic> json) {
    return MyTransaction(
      id: id,
      categoryId: json['categoryId'] as String,
      accountId: json['accountId'] as String,
      note: json['note'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: (json['date'] as Timestamp).toDate(),
    );
  }
}
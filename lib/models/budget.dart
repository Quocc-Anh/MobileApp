import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String categoryId; // ID của danh mục được áp dụng ngân sách
  final double amountLimit; // Hạn mức chi tiêu
  final Timestamp date;     // Đại diện cho tháng áp dụng (VD: 2025-10-01)

  Budget({
    required this.id,
    required this.categoryId,
    required this.amountLimit,
    required this.date,
  });

  // Chuyển từ đối tượng Dart sang JSON (để gửi lên Firestore)
  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'amountLimit': amountLimit,
      'date': date,
    };
  }

  // Chuyển từ JSON (lấy từ Firestore) sang đối tượng Dart
  factory Budget.fromJson(String id, Map<String, dynamic> json) {
    return Budget(
      id: id,
      categoryId: json['categoryId'] as String,
      amountLimit: (json['amountLimit'] as num).toDouble(),
      date: json['date'] as Timestamp,
    );
  }
}
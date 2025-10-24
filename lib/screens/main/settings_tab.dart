import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Nơi đây bạn sẽ tạo các ListView để hiển thị:
    // 1. Danh sách Danh mục (có nút Thêm/Xóa) - Cốt lõi 2
    // 2. Danh sách Tài khoản (có nút Thêm/Xóa) - Quan trọng 1
    // 3. Danh sách Ngân sách (có nút Thêm/Xóa) - Quan trọng 3

    return Center(
      child: Text('Nơi quản lý Danh mục, Tài khoản và Ngân sách'),
    );
  }
}
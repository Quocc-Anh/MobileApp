import 'package:flutter/material.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Lấy dữ liệu giao dịch từ Firestore (dùng StreamBuilder)
    // 2. Xử lý dữ liệu (nhóm theo danh mục, tính tổng)
    // 3. Hiển thị bằng PieChart() từ gói fl_chart

    return Center(
      child: Text('Nơi đây sẽ là các biểu đồ báo cáo'),
      // Ví dụ: PieChart(...)
    );
  }
}
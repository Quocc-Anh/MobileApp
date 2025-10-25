import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaction.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId == null) {
      return Center(child: Text('Lỗi: Không tìm thấy người dùng.'));
    }

    return StreamBuilder<List<MyTransaction>>(
      // 1. LẤY TẤT CẢ GIAO DỊCH
      stream: firestoreService.getTransactionsStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final allTransactions = snapshot.data!;
        if (allTransactions.isEmpty) {
          return Center(child: Text('Chưa có dữ liệu giao dịch.'));
        }

        // 2. XỬ LÝ VÀ NHÓM DỮ LIỆU
        // Map<Ngày, Tổng chi tiêu>
        final Map<int, double> dailySpending = {};
        final now = DateTime.now();
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

        // Lọc các giao dịch CHI TIÊU trong THÁNG NÀY
        final expensesThisMonth = allTransactions.where((tx) {
          return tx.amount < 0 && // Là chi tiêu
              !tx.date.isBefore(firstDayOfMonth) && // Từ ngày 1
              !tx.date.isAfter(lastDayOfMonth); // Đến ngày cuối tháng
        }).toList();

        if (expensesThisMonth.isEmpty) {
          return Center(child: Text('Tháng này bạn chưa chi tiêu gì.'));
        }

        // Tính tổng chi tiêu cho mỗi ngày
        double maxY = 0.0; // Dùng để set giới hạn trục Y của biểu đồ
        for (var tx in expensesThisMonth) {
          int day = tx.date.day;
          double amount = -tx.amount; // Chuyển thành số dương

          dailySpending[day] = (dailySpending[day] ?? 0) + amount;

          if (dailySpending[day]! > maxY) {
            maxY = dailySpending[day]!;
          }
        }

        // Thêm 20% vào giới hạn Y cho đẹp
        maxY = maxY * 1.2;

        // Tạo dữ liệu cho các cột
        List<BarChartGroupData> barGroups = [];
        for (int i = 1; i <= lastDayOfMonth.day; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i, // Ngày (trục X)
              barRods: [
                BarChartRodData(
                  toY: dailySpending[i] ?? 0, // Số tiền (trục Y)
                  color: Colors.teal,
                  width: 12, // Độ rộng cột
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }

        // 3. VẼ BIỂU ĐỒ
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiêu hàng ngày (Tháng ${now.month}/${now.year})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              // Container chứa biểu đồ
              SizedBox(
                height: 300, // Cần 1 chiều cao cố định
                // Thêm thanh cuộn ngang
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    // Đặt chiều rộng cho biểu đồ để cuộn
                    // (30 ngày * (12 độ rộng cột + 10 khoảng cách))
                    width: lastDayOfMonth.day * 22.0,
                    child: BarChart(
                      BarChartData(
                        maxY: maxY,
                        barGroups: barGroups,
                        titlesData: _buildTitlesData(), // Hàm cấu hình trục X, Y
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          // Thêm tooltip khi chạm vào cột
                          touchTooltipData: BarTouchTooltipData(
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final oCcy = NumberFormat("#,##0", "vi_VN");
                              String day = 'Ngày ${group.x.toInt()}';
                              String amount = '${oCcy.format(rod.toY)} VNĐ';
                              return BarTooltipItem(
                                '$day\n$amount',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hàm Helper để cấu hình các Trục (Axis) X, Y
  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      // Ẩn trục trên và phải
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

      // Trục Dưới (Trục X - Ngày)
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (double value, TitleMeta meta) {
            if (value.toInt() % 2 == 0) {
              return const SizedBox();
            }
            return Text(
              value.toInt().toString(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
              ),
            );
          },
        ),
      ),

      // Trục Trái (Trục Y - Tiền)
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value == 0) return Container(); // Ẩn số 0

            // Hiển thị dạng rút gọn (100k, 1M)
            String text = '';
            if (value > 1000000) {
              text = '${(value / 1000000).toStringAsFixed(1)}M';
            } else if (value > 1000) {
              text = '${(value / 1000).toStringAsFixed(0)}k';
            } else {
              text = value.toStringAsFixed(0);
            }
            return Text(text, style: TextStyle(fontSize: 10));
          },
          reservedSize: 40, // Chỗ trống cho các số tiền
        ),
      ),
    );
  }
}
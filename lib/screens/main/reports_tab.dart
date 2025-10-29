import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  // Biến để lưu trữ tháng/năm được chọn
  // Mặc định là tháng hiện tại
  DateTime _selectedMonth = DateTime.now();

  static const List<Color> _pieColors = [
    Colors.blue, Colors.green, Colors.red, Colors.orange, Colors.purple,
    Colors.teal, Colors.pink, Colors.amber, Colors.cyan, Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUserId;
    final theme = Theme.of(context);
    final oCcy = NumberFormat("#,##0", "vi_VN");

    if (userId == null) {
      return Center(child: Text('Lỗi: Không tìm thấy người dùng.'));
    }

    // Tính toán ngày đầu và ngày cuối của tháng được chọn
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day; // Số ngày trong tháng

    return StreamBuilder<List<Category>>(
      stream: firestoreService.getCategoriesStream(userId),
      builder: (context, catSnapshot) {
        return StreamBuilder<List<MyTransaction>>(
          stream: firestoreService.getTransactionsStream(userId),
          builder: (context, txSnapshot) {
            if (!catSnapshot.hasData || !txSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final allTransactions = txSnapshot.data!;
            final categories = catSnapshot.data!;

            // Tạo một Map để tìm tên danh mục từ ID
            final categoryMap = {for (var cat in categories) cat.id: cat.name};

            // Lọc ra các giao dịch CHI TIÊU trong THÁNG ĐƯỢC CHỌN
            final expensesThisMonth = allTransactions.where((tx) {
              return tx.amount < 0 &&
                  !tx.date.isBefore(firstDayOfMonth) &&
                  !tx.date.isAfter(lastDayOfMonth);
            }).toList();

            // Tính tổng chi tiêu của tháng
            double totalMonthlyExpense = expensesThisMonth.fold(
                0.0, (sum, tx) => sum + (-tx.amount)
            );

            return SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Báo cáo tháng ${DateFormat.yM('vi_VN').format(_selectedMonth)}',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.calendar_month),
                        onPressed: () => _selectMonth(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.money_off, color: Colors.red, size: 32),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tổng chi tiêu tháng',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${oCcy.format(totalMonthlyExpense)} VNĐ',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  _buildCategoryPieChartCard(
                    context,
                    expensesThisMonth,
                    categoryMap,
                  ),

                  SizedBox(height: 20),

                  _buildDailyBarChartCard(
                    context,
                    expensesThisMonth,
                    daysInMonth,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }


  Widget _buildCategoryPieChartCard(
      BuildContext context,
      List<MyTransaction> expenses,
      Map<String, String> categoryMap
      ) {
    final theme = Theme.of(context);
    final oCcy = NumberFormat("#,##0", "vi_VN");

    Map<String, double> categorySpending = {};
    double totalSpending = 0;

    for (var tx in expenses) {
      double amount = -tx.amount;
      categorySpending[tx.categoryId] = (categorySpending[tx.categoryId] ?? 0) + amount;
      totalSpending += amount;
    }

    if (expenses.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(child: Text('Tháng này chưa có chi tiêu theo danh mục.')),
        ),
      );
    }

    int colorIndex = 0;
    List<PieChartSectionData> pieSections = categorySpending.entries.map((entry) {
      final amount = entry.value;
      final percentage = (amount / totalSpending * 100);

      final color = _pieColors[colorIndex % _pieColors.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: amount,
        title: percentage >= 7 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    }).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiêu theo danh mục',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tổng chi: ${oCcy.format(totalSpending)} VNĐ',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.red[700]),
            ),
            SizedBox(height: 16),

            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sections: pieSections,
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                    },
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: categorySpending.keys.toList().asMap().entries.map((entry) {
                int index = entry.key;
                String categoryId = entry.value;
                String name = categoryMap[categoryId] ?? 'Không rõ';
                final color = _pieColors[index % _pieColors.length];

                return _buildLegendItem(color, name);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBarChartCard(
      BuildContext context,
      List<MyTransaction> expenses,
      int daysInMonth
      ) {
    final theme = Theme.of(context);

    Map<int, double> dailySpending = {};
    double maxY = 0.0;

    for (var tx in expenses) {
      int day = tx.date.day;
      double amount = -tx.amount;
      dailySpending[day] = (dailySpending[day] ?? 0) + amount;
      if (dailySpending[day]! > maxY) {
        maxY = dailySpending[day]!;
      }
    }
    // Nếu không có chi tiêu, maxY = 0, gây lỗi. Sửa thành:
    maxY = (maxY == 0) ? 100000 : maxY * 1.2; // Đặt 1 giá trị mặc định nếu = 0

    List<BarChartGroupData> barGroups = [];
    for (int i = 1; i <= daysInMonth; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: dailySpending[i] ?? 0,
              color: theme.colorScheme.primary,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiêu hàng ngày',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.6,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
                  child: SizedBox(
                    width: daysInMonth * 22.0,
                    child: BarChart(
                      BarChartData(
                        maxY: maxY,
                        barGroups: barGroups,
                        titlesData: _buildTitlesData(),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 4, // Đã sửa lỗi chia cho 0
                          getDrawingHorizontalLine: (value) {
                            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final oCcy = NumberFormat("#,##0", "vi_VN");
                              return BarTooltipItem(
                                'Ngày ${group.x}\n${oCcy.format(rod.toY)} VNĐ',
                                theme.textTheme.bodyMedium!.copyWith(color: Colors.white),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2), // Bo góc nhẹ
          ),
        ),
        SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13)),
      ],
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (dayValue, meta) {
            String text = dayValue.toInt().toString();
            if (dayValue.toInt() % 2 != 0 && dayValue.toInt() != 1 && dayValue.toInt() != 31 ) {
              return Container();
            }
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 4,
              child: Text(text, style: TextStyle(fontSize: 10)),
            );
          },
          reservedSize: 28,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value == 0) {
              return Container();
            }
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
          reservedSize: 40,
        ),
      ),
    );
  }
}
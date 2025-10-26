// lib/screens/main/budget_tab.dart (FILE MỚI)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/category.dart';
import '../../models/budget.dart';
import '../../models/transaction.dart'; // <-- Bắt buộc import

class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key});

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

    // Lấy ngày đầu và cuối của tháng HIỆN TẠI
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Lồng 3 StreamBuilder: Categories -> Budgets -> Transactions
    return StreamBuilder<List<Category>>(
      stream: firestoreService.getCategoriesStream(userId),
      builder: (context, catSnapshot) {
        return StreamBuilder<List<Budget>>(
          stream: firestoreService.getBudgetsStream(userId),
          builder: (context, budgetSnapshot) {
            return StreamBuilder<List<MyTransaction>>(
              stream: firestoreService.getTransactionsStream(userId),
              builder: (context, txSnapshot) {
                // Xử lý trạng thái loading
                if (!catSnapshot.hasData || !budgetSnapshot.hasData || !txSnapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final categories = catSnapshot.data!;
                final budgets = budgetSnapshot.data!;
                final allTransactions = txSnapshot.data!;

                // Tạo Map để tra cứu tên danh mục
                final categoryMap = {for (var cat in categories) cat.id: cat.name};

                // Lọc giao dịch CHI TIÊU trong THÁNG NÀY
                final expensesThisMonth = allTransactions.where((tx) {
                  return tx.amount < 0 &&
                      !tx.date.isBefore(firstDayOfMonth) &&
                      !tx.date.isAfter(lastDayOfMonth);
                }).toList();

                // Lọc ngân sách chỉ áp dụng cho tháng này
                // (Giả sử Budget.date lưu ngày đầu tháng)
                final budgetsThisMonth = budgets.where((b) {
                  final budgetMonth = b.date.toDate();
                  return budgetMonth.year == now.year && budgetMonth.month == now.month;
                }).toList();

                if (budgetsThisMonth.isEmpty) {
                  return Center(
                    child: Text(
                      'Bạn chưa đặt ngân sách nào cho tháng này.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: budgetsThisMonth.length,
                  itemBuilder: (context, index) {
                    final budget = budgetsThisMonth[index];
                    final categoryName = categoryMap[budget.categoryId] ?? 'Không rõ';

                    // Tính tổng chi tiêu cho ngân sách này
                    double totalSpentForBudget = expensesThisMonth
                        .where((tx) => tx.categoryId == budget.categoryId)
                        .fold(0.0, (sum, tx) => sum + (-tx.amount)); // Cộng số dương

                    // Tính phần trăm tiến độ (tránh chia cho 0)
                    double progress = budget.amountLimit > 0
                        ? (totalSpentForBudget / budget.amountLimit)
                        : 0;
                    // Đảm bảo progress không vượt quá 1 (100%) cho màu sắc thanh bar
                    double displayProgress = progress > 1.0 ? 1.0 : progress;

                    bool isOverBudget = totalSpentForBudget > budget.amountLimit;

                    // Màu sắc cho thanh tiến độ
                    Color progressColor = isOverBudget
                        ? theme.colorScheme.error // Màu đỏ nếu vượt
                        : theme.colorScheme.primary; // Màu chính nếu chưa vượt

                    return Card(
                      elevation: 1,
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên Danh mục và Hạn mức
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  categoryName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Hạn mức: ${oCcy.format(budget.amountLimit)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // Thanh tiến độ
                            LinearProgressIndicator(
                              value: displayProgress, // Giá trị từ 0.0 đến 1.0
                              backgroundColor: progressColor.withAlpha(51),
                              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                              minHeight: 8, // Độ dày của thanh
                              borderRadius: BorderRadius.circular(4),
                            ),
                            SizedBox(height: 8),

                            // Hiển thị số tiền đã chi và cảnh báo nếu vượt
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đã chi: ${oCcy.format(totalSpentForBudget)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isOverBudget ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                if (isOverBudget)
                                  Text(
                                    'Vượt ${(progress * 100 - 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                else
                                  Text(
                                    'Còn lại: ${oCcy.format(budget.amountLimit - totalSpentForBudget)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurfaceVariant.withAlpha(204),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaction.dart';
import '../../models/account.dart';
import '../../models/category.dart'; // <-- THÊM IMPORT NÀY
import 'package:intl/intl.dart';

// Đã chuyển sang StatefulWidget
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Biến trạng thái ẩn/hiện số dư
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUserId;
    final oCcy = NumberFormat("#,##0", "vi_VN");

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (userId == null) {
      return Center(child: Text('Lỗi: Không tìm thấy người dùng.'));
    }

    // --- BẮT ĐẦU SỬA: LỒNG 3 STREAMBUILDER ---
    // 1. Lấy TÀI KHOẢN
    return StreamBuilder<List<Account>>(
      stream: firestoreService.getAccountsStream(userId),
      builder: (context, accSnapshot) {
        // 2. Lấy DANH MỤC
        return StreamBuilder<List<Category>>(
          stream: firestoreService.getCategoriesStream(userId),
          builder: (context, catSnapshot) {
            // 3. Lấy GIAO DỊCH
            return StreamBuilder<List<MyTransaction>>(
              stream: firestoreService.getTransactionsStream(userId),
              builder: (context, txSnapshot) {
                // Kiểm tra cả 3 snapshots
                if (!accSnapshot.hasData || !catSnapshot.hasData || !txSnapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final accounts = accSnapshot.data!;
                final categories = catSnapshot.data!;
                final transactions = txSnapshot.data!;

                // Tạo Maps để tra cứu tên
                final categoryMap = {for (var cat in categories) cat.id: cat.name};
                final accountMap = {for (var acc in accounts) acc.id: acc.name};

                // Tính toán số dư
                double totalInitialBalance = accounts.fold(
                    0.0, (sum, acc) => sum + acc.initialBalance);
                double totalTransactionAmount = transactions.fold(
                    0.0, (sum, tx) => sum + tx.amount);
                double totalBalance = totalInitialBalance + totalTransactionAmount;

                return Column(
                  children: [
                    // --- Card Hiển thị Số dư (Đã có logic ẩn/hiện) ---
                    Card(
                      color: colorScheme.surfaceContainerHigh,
                      margin: EdgeInsets.all(12),
                      elevation: 1,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'TỔNG SỐ DƯ',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  icon: Icon(
                                    _isBalanceVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isBalanceVisible = !_isBalanceVisible;
                                    });
                                  },
                                )
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              _isBalanceVisible ? '${oCcy.format(totalBalance)} VNĐ' : '******** VNĐ',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: totalBalance >= 0 ? colorScheme.primary : colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                    Expanded(
                      child: transactions.isEmpty
                          ? Center(
                        child: Text(
                          'Chưa có giao dịch nào.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                          : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        itemCount: transactions.length,
                        itemBuilder: (ctx, index) {
                          final tx = transactions[index];
                          bool isExpense = tx.amount < 0;

                          // Lấy tên từ Maps
                          final categoryName = categoryMap[tx.categoryId] ?? 'Không rõ';
                          final accountName = accountMap[tx.accountId] ?? 'Không rõ';

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withAlpha(128),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                backgroundColor: isExpense
                  ? colorScheme.errorContainer.withAlpha(128)
                  : Colors.green[100],
                                child: Icon(
                                  isExpense
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isExpense
                                      ? colorScheme.onErrorContainer
                                      : Colors.green[800],
                                  size: 20,
                                ),
                              ),
                              // Sửa Title thành Tên Danh mục
                              title: Text(
                                categoryName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Sửa Subtitle để hiển thị Ghi chú, Ngày, Tài khoản
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (tx.note.isNotEmpty)
                                    Text(
                                      tx.note,
                                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    '${DateFormat.yMd('vi_VN').format(tx.date)} • $accountName', // Thêm Tên tài khoản
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant.withAlpha(179), // Mờ hơn chút
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                oCcy.format(tx.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isExpense
                                      ? colorScheme.error
                                      : Colors.green[700],
                                ),
                              ),
                              isThreeLine: tx.note.isNotEmpty, // Tự động tăng chiều cao nếu có ghi chú
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
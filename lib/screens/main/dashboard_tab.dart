import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaction.dart';
import '../../models/account.dart';
import 'package:intl/intl.dart';

// --- THAY ĐỔI 1: Chuyển sang StatefulWidget ---
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // --- THAY ĐỔI 2: Thêm biến trạng thái để quản lý ẩn/hiện ---
  bool _isBalanceVisible = true; // Mặc định là HIỆN

  @override
  Widget build(BuildContext context) {
    // Toàn bộ logic build của bạn được chuyển vào đây
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUserId;
    final oCcy = NumberFormat("#,##0", "vi_VN");

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (userId == null) {
      return Center(child: Text('Lỗi: Không tìm thấy người dùng.'));
    }

    return StreamBuilder<List<Account>>(
      stream: firestoreService.getAccountsStream(userId),
      builder: (context, accSnapshot) {
        return StreamBuilder<List<MyTransaction>>(
          stream: firestoreService.getTransactionsStream(userId),
          builder: (context, txSnapshot) {
            if (!accSnapshot.hasData || !txSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final accounts = accSnapshot.data!;
            final transactions = txSnapshot.data!;

            double totalInitialBalance = accounts.fold(
                0.0, (sum, acc) => sum + acc.initialBalance);
            double totalTransactionAmount = transactions.fold(
                0.0, (sum, tx) => sum + tx.amount);
            double totalBalance = totalInitialBalance + totalTransactionAmount;

            return Column(
              children: [
                // --- Hiển thị Số dư (NÂNG CẤP GIAO DIỆN) ---
                Card(
                  color: colorScheme.surfaceContainerHigh,
                  margin: EdgeInsets.all(12),
                  elevation: 1,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      children: [
                        // --- THAY ĐỔI 3: Bọc tiêu đề bằng Row và thêm Icon ---
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
                            // Nút "con mắt"
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
                                // --- THAY ĐỔI 4: Dùng setState để cập nhật UI ---
                                setState(() {
                                  _isBalanceVisible = !_isBalanceVisible;
                                });
                              },
                            )
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          // --- THAY ĐỔI 5: Hiển thị số dư hoặc '****' ---
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

                // --- Lịch sử Giao dịch (Giữ nguyên) ---
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
                                ? colorScheme.errorContainer
                                : Colors.green[100],
                            child: Icon(
                              isExpense
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isExpense
                                  ? colorScheme.onErrorContainer
                                  : Colors.green[800],
                            ),
                          ),
                          title: Text(
                            tx.note.isEmpty ? 'Giao dịch' : tx.note,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            DateFormat.yMd('vi_VN').format(tx.date),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
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
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaction.dart';
import '../../models/account.dart';
import 'package:intl/intl.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUserId;
    final oCcy = NumberFormat("#,##0", "vi_VN");

    // Lấy theme (Màu sắc) từ Material 3
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

            // Xử lý trạng thái loading (như cũ)
            if (!accSnapshot.hasData || !txSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final accounts = accSnapshot.data!;
            final transactions = txSnapshot.data!;

            // --- TÍNH TOÁN (Giữ nguyên logic của bạn) ---
            double totalInitialBalance = accounts.fold(
                0.0, (sum, acc) => sum + acc.initialBalance);
            double totalTransactionAmount = transactions.fold(
                0.0, (sum, tx) => sum + tx.amount);
            double totalBalance = totalInitialBalance + totalTransactionAmount;
            // --- KẾT THÚC TÍNH TOÁN ---

            return Column(
              children: [

                // --- Hiển thị Số dư (NÂNG CẤP GIAO DIỆN) ---
                Card(
                  // Dùng màu surfaceContainerHigh (hơi xám) của M3
                  color: colorScheme.surfaceContainerHigh,
                  margin: EdgeInsets.all(12),
                  elevation: 1, // M3 dùng elevation thấp
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      children: [
                        Text(
                          'TỔNG SỐ DƯ',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant, // Màu chữ phụ
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1, // Giãn cách chữ
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${oCcy.format(totalBalance)} VNĐ',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            // Dùng màu `primary` hoặc `error` từ theme
                            color: totalBalance >= 0 ? colorScheme.primary : colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Lịch sử Giao dịch (NÂNG CẤP GIAO DIỆN) ---
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
                    // Thêm padding để danh sách không dính sát viền
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    itemCount: transactions.length,
                    itemBuilder: (ctx, index) {
                      final tx = transactions[index];
                      bool isExpense = tx.amount < 0;

                      // Bọc ListTile trong Card
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        elevation: 0, // Dùng viền thay vì bóng đổ
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
                          // Giữ nguyên logic title của bạn
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
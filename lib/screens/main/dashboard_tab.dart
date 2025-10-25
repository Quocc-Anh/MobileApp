import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaction.dart';
import '../../models/account.dart'; // <-- THÊM IMPORT
import 'package:intl/intl.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUserId;

    final oCcy = NumberFormat("#,##0", "vi_VN");

    if (userId == null) {
      return Center(child: Text('Lỗi: Không tìm thấy người dùng.'));
    }

    // Chúng ta cần lồng 2 StreamBuilder để lấy dữ liệu từ 2 collection
    // 1. Lấy danh sách TÀI KHOẢN (để tính tổng số dư ban đầu)
    return StreamBuilder<List<Account>>(
      stream: firestoreService.getAccountsStream(userId),
      builder: (context, accSnapshot) {

        // 2. Lấy danh sách GIAO DỊCH (để tính tổng tiền giao dịch)
        return StreamBuilder<List<MyTransaction>>(
          stream: firestoreService.getTransactionsStream(userId),
          builder: (context, txSnapshot) {

            // Xử lý trạng thái loading
            if (!accSnapshot.hasData || !txSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final accounts = accSnapshot.data!;
            final transactions = txSnapshot.data!;

            // --- TÍNH TOÁN CHÍNH XÁC ---

            // 1. Tính tổng số dư ban đầu từ TẤT CẢ tài khoản
            double totalInitialBalance = accounts.fold(
                0.0,
                    (sum, acc) => sum + acc.initialBalance
            );

            // 2. Tính tổng tiền từ TẤT CẢ giao dịch
            double totalTransactionAmount = transactions.fold(
                0.0,
                    (sum, tx) => sum + tx.amount
            );

            // 3. Tổng số dư = (Tổng ban đầu) + (Tổng giao dịch)
            double totalBalance = totalInitialBalance + totalTransactionAmount;

            // --- KẾT THÚC TÍNH TOÁN ---

            return Column(
              children: [
                // --- Hiển thị Số dư ---
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  color: Colors.teal[50],
                  child: Column(
                    children: [
                      Text('TỔNG SỐ DƯ', style: TextStyle(color: Colors.grey[600])),
                      Text(
                        '${oCcy.format(totalBalance)} VNĐ', // Dùng biến totalBalance đã tính
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: totalBalance >= 0 ? Colors.teal[700] : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Lịch sử Giao dịch ---
                Expanded(
                  child: transactions.isEmpty
                      ? Center(child: Text('Chưa có giao dịch nào.'))
                      : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (ctx, index) {
                      final tx = transactions[index];
                      bool isExpense = tx.amount < 0;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isExpense ? Colors.red[100] : Colors.green[100],
                          child: Icon(
                            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                        // (Bạn cần logic để hiển thị tên Danh mục/Tài khoản từ ID)
                        title: Text(tx.note.isEmpty ? 'Giao dịch' : tx.note),
                        subtitle: Text(DateFormat.yMd('vi_VN').format(tx.date)),
                        trailing: Text(
                          oCcy.format(tx.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isExpense ? Colors.red : Colors.green,
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
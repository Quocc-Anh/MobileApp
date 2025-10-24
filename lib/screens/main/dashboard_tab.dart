import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaction.dart';
import 'package:intl/intl.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUserId;

    // Định dạng tiền tệ
    final oCcy = new NumberFormat("#,##0", "vi_VN");

    if (userId == null) {
      return Center(child: Text('Lỗi: Không tìm thấy người dùng.'));
    }

    return StreamBuilder<List<MyTransaction>>(
      // Lắng nghe stream giao dịch real-time từ Firestore
      stream: firestoreService.getTransactionsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Chưa có giao dịch nào.'));
        }

        final transactions = snapshot.data!;

        // Tính toán tổng số dư (đơn giản)
        // (Bạn cần kết hợp với số dư tài khoản ban đầu để chính xác hơn)
        double totalBalance = transactions.fold(0.0, (sum, item) => sum + item.amount);

        return Column(
          children: [
            // --- Hiển thị Số dư (Cốt lõi 3) ---
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              color: Colors.teal[50],
              child: Column(
                children: [
                  Text('TỔNG SỐ DƯ', style: TextStyle(color: Colors.grey[600])),
                  Text(
                    '${oCcy.format(totalBalance)} VNĐ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: totalBalance >= 0 ? Colors.teal : Colors.red,
                    ),
                  ),
                  // (Nơi đây bạn có thể hiển thị số dư theo từng tài khoản - Quan trọng 1)
                ],
              ),
            ),

            // --- Lịch sử Giao dịch (Cốt lõi 3) ---
            Expanded(
              child: ListView.builder(
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
                    // (Bạn cần 1 hàm để lấy Tên Danh mục từ ID)
                    title: Text(tx.note.isEmpty ? 'Giao dịch' : tx.note),
                    subtitle: Text(DateFormat.yMd('vi_VN').format(tx.date)),
                    trailing: Text(
                      '${oCcy.format(tx.amount)}',
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
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // <-- THÊM
import 'package:shimmer/shimmer.dart'; // <-- THÊM

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/transaction.dart';
import '../../models/account.dart';
import '../../models/category.dart'; // <-- THÊM

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

    // Chúng ta lồng 3 StreamBuilder
    // 1. Lấy TÀI KHOẢN (để tính số dư ban đầu)
    return StreamBuilder<List<Account>>(
      stream: firestoreService.getAccountsStream(userId),
      builder: (context, accSnapshot) {
        // 2. Lấy DANH MỤC (để lấy tên danh mục)
        return StreamBuilder<List<Category>>(
          stream: firestoreService.getCategoriesStream(userId),
          builder: (context, catSnapshot) {
            // 3. Lấy GIAO DỊCH
            return StreamBuilder<List<MyTransaction>>(
              stream: firestoreService.getTransactionsStream(userId),
              builder: (context, txSnapshot) {
                // --- XỬ LÝ TRẠNG THÁI LOADING (Nâng cấp) ---
                if (!accSnapshot.hasData || !catSnapshot.hasData || !txSnapshot.hasData) {
                  // Hiển thị giao diện "xương" lấp lánh
                  return _buildLoadingShimmer(context);
                }

                final accounts = accSnapshot.data!;
                final categories = catSnapshot.data!;
                final transactions = txSnapshot.data!;

                // --- TẠO MAP ĐỂ TÌM TÊN DANH MỤC NHANH (Nâng cấp) ---
                // Chuyển List<Category> thành Map<String, String>
                // Ví dụ: {'cat_id_1': 'Ăn uống', 'cat_id_2': 'Đi lại'}
                final categoryMap = {for (var cat in categories) cat.id: cat.name};

                // --- TÍNH TOÁN SỐ DƯ (Giữ nguyên) ---
                double totalInitialBalance =
                accounts.fold(0.0, (sum, acc) => sum + acc.initialBalance);
                double totalTransactionAmount =
                transactions.fold(0.0, (sum, tx) => sum + tx.amount);
                double totalBalance = totalInitialBalance + totalTransactionAmount;

                // --- KẾT THÚC TÍNH TOÁN ---

                return Column(
                  children: [
                    // --- HIỂN THỊ SỐ DƯ (Nâng cấp) ---
                    _buildBalanceCard(context, totalBalance, oCcy),

                    // --- LỊCH SỬ GIAO DỊCH (Nâng cấp) ---
                    Expanded(
                      child: transactions.isEmpty
                      // --- TRẠNG THÁI RỖNG (Nâng cấp) ---
                          ? _buildEmptyState()
                      // --- DANH SÁCH (Nâng cấp) ---
                          : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        itemCount: transactions.length,
                        itemBuilder: (ctx, index) {
                          final tx = transactions[index];
                          bool isExpense = tx.amount < 0;
                          // Lấy tên danh mục từ Map
                          final categoryName =
                              categoryMap[tx.categoryId] ?? 'Không rõ';

                          return _buildTransactionCard(
                              tx, categoryName, isExpense, oCcy);
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

  /// WIDGET HIỂN THỊ TỔNG SỐ DƯ (MỚI)
  Widget _buildBalanceCard(BuildContext context, double totalBalance, NumberFormat oCcy) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.all(12),
      elevation: 2,
      // Dùng màu surfaceContainerHigh của Material 3
      color: colors.surfaceContainerHigh,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'TỔNG SỐ DƯ',
              style: TextStyle(
                  color: colors.onSurfaceVariant, // Màu chữ phụ
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1
              ),
            ),
            SizedBox(height: 8),
            Text(
              '                          totalBalance,',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: totalBalance >= 0 ? colors.primary : colors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// WIDGET HIỂN THỊ MỘT GIAO DỊCH (MỚI)
  Widget _buildTransactionCard(
      MyTransaction tx, String categoryName, bool isExpense, NumberFormat oCcy) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          isExpense ? Colors.red.withAlpha(25) : Colors.green.withAlpha(25),
          child: Icon(
            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
        // Hiển thị tên Danh mục
        title: Text(
          categoryName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // Hiển thị Ghi chú (nếu có) và Ngày
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tx.note.isNotEmpty)
              Text(tx.note, style: TextStyle(fontSize: 12)),
            Text(
              DateFormat.yMd('vi_VN').add_Hm().format(tx.date), // Thêm giờ phút
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Text(
          oCcy.format(tx.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
        isThreeLine: tx.note.isNotEmpty, // Tăng chiều cao nếu có Ghi chú
      ),
    );
  }

  /// WIDGET TRẠNG THÁI RỖNG (MỚI)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hãy chắc chắn bạn có file này trong assets
          Lottie.asset('assets/animations/empty_state.json', height: 200),
          SizedBox(height: 16),
          Text(
            'Chưa có giao dịch nào',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// WIDGET TRẠNG THÁI TẢI DỮ LIỆU (MỚI)
  Widget _buildLoadingShimmer(BuildContext context) {
    final shimmerColor = Colors.grey[300]!;
    final shimmerHighlight = Colors.grey[100]!;

    // Hàm tạo 1 hộp "xương"
    Widget buildPlaceholder(double height, {double? width, double radius = 8}) {
      return Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: shimmerColor,
      highlightColor: shimmerHighlight,
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(), // Không cho cuộn khi đang tải
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            // "Xương" cho Card Số dư
            Card(
              elevation: 2,
              child: Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                child: Column(
                  children: [
                    buildPlaceholder(14, width: 100),
                    SizedBox(height: 12),
                    buildPlaceholder(32, width: 200),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // "Xương" cho danh sách giao dịch
            ...List.generate(5, (index) => Card(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                leading: buildPlaceholder(40, width: 40, radius: 20), // Avatar tròn
                title: buildPlaceholder(16, width: 150),
                subtitle: buildPlaceholder(12, width: 100),
                trailing: buildPlaceholder(18, width: 80),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
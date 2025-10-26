import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../models/budget.dart';

class ManagementTab extends StatelessWidget {
  const ManagementTab({super.key});

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context, FirestoreService firestoreService, String userId) async {
    final nameController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm danh mục mới'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Tên danh mục'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                firestoreService.addCategory(userId, nameController.text);
                Navigator.pop(context);
              }
            },
            child: Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddAccountDialog(BuildContext context, FirestoreService firestoreService, String userId) async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm tài khoản mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Tên tài khoản'),
            ),
            TextField(
              controller: balanceController,
              decoration: InputDecoration(labelText: 'Số dư ban đầu'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final balance = double.tryParse(balanceController.text) ?? 0;
              if (nameController.text.isNotEmpty) {
                firestoreService.addAccount(userId, nameController.text, balance);
                Navigator.pop(context);
              }
            },
            child: Text('Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy các dịch vụ và ID người dùng
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUserId;

    // Định dạng tiền tệ
    final oCcy = NumberFormat("#,##0", "vi_VN");

    if (userId == null) {
      return Center(child: Text('Lỗi: Không tìm thấy người dùng.'));
    }

    return ListView(
      padding: EdgeInsets.all(8),
      children: [
      Text(
      'Quản lý',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    ),
    SizedBox(height: 16),

    // --- 1. QUẢN LÝ DANH MỤC (Cốt lõi 2) ---
    _buildSectionTitle(context, 'Quản lý Danh mục'),
    StreamBuilder<List<Category>>(
    stream: firestoreService.getCategoriesStream(userId),
    builder: (context, snapshot) {
    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
    final categories = snapshot.data!;
    return Column(
    children: [
    ...categories.map((cat) => ListTile(
    leading: Icon(Icons.category_outlined),
    title: Text(cat.name),
    trailing: IconButton(
    icon: Icon(Icons.delete_outline, color: Colors.red[300]),
    onPressed: () {
    // (Bạn cần thêm hàm deleteCategory vào firestore_service.dart)
    // firestoreService.deleteCategory(userId, cat.id);
    },
    ),
    )),
    Divider(),
    ListTile(
    leading: Icon(Icons.add, color: Colors.teal),
    title: Text('Thêm danh mục mới'),
    onTap: () {
    _showAddCategoryDialog(context, firestoreService, userId);
    },
    ),
    ],
    );
    },
    ),
    Divider(height: 30),

    // --- 2. QUẢN LÝ TÀI KHOẢN (Quan trọng 1) ---
    _buildSectionTitle(context, 'Quản lý Tài khoản'),
    StreamBuilder<List<Account>>(
    stream: firestoreService.getAccountsStream(userId),
    builder: (context, snapshot) {
    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
    final accounts = snapshot.data!;
    return Column(
    children: [
    ...accounts.map((acc) => ListTile(
    leading: Icon(Icons.account_balance_wallet_outlined),
    title: Text(acc.name),
    subtitle: Text('Số dư ban đầu: ${oCcy.format(acc.initialBalance)} VNĐ'),
    trailing: IconButton(
    icon: Icon(Icons.delete_outline, color: Colors.red[300]),
    onPressed: () {
    // (Bạn cần thêm hàm deleteAccount vào firestore_service.dart)
    // firestoreService.deleteAccount(userId, acc.id);
    },
    ),
    )),
    Divider(),
    ListTile(
    leading: Icon(Icons.add, color: Colors.teal),
    title: Text('Thêm tài khoản mới'),
    onTap: () {
    _showAddAccountDialog(context, firestoreService, userId);
    },
    ),
    ],
    );
    },
    ),
    Divider(height: 30),

    // --- 3. QUẢN LÝ NGÂN SÁCH (Quan trọng 3) ---
    _buildSectionTitle(context, 'Quản lý Ngân sách'),
    StreamBuilder<List<Budget>>(
      stream: firestoreService.getBudgetsStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final budgets = snapshot.data!;
        return Column(
          children: [
            ...budgets.map((budget) => ListTile(
              leading: Icon(Icons.pie_chart_outline),
              // (Để hiển thị Tên danh mục, bạn cần 1 stream khác,
              // ở đây chúng ta hiển thị ID cho đơn giản)
              title: Text('Hạn mức: ${oCcy.format(budget.amountLimit)} VNĐ'),
              subtitle: Text('Danh mục ID: ${budget.categoryId}'),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                onPressed: () {
                  // (Bạn cần thêm hàm deleteBudget vào firestore_service.dart)
                  // firestoreService.deleteBudget(userId, budget.id);
                },
              ),
            )),
            Divider(),
            ListTile(
              leading: Icon(Icons.add, color: Colors.teal),
              title: Text('Thêm ngân sách mới'),
              onTap: () {
                // TODO: Implement add budget dialog
              },
            ),
          ],
        );
      },
    ),
      ],
    );
  }
}
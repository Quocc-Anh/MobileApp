import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    // (Giữ nguyên hàm này)
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm danh mục mới'),
        content: TextField(
          controller: nameController,
          autofocus: true,
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
    // Thêm FormKey để validation
    final _formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm tài khoản mới'),
        // Bọc trong Form
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField( // Dùng TextFormField
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(labelText: 'Tên tài khoản'),
                validator: (value) => (value == null || value.isEmpty) ? 'Không được bỏ trống' : null,
              ),
              TextFormField( // Dùng TextFormField
                controller: balanceController,
                decoration: InputDecoration(labelText: 'Số dư ban đầu'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => (value == null || value.isEmpty) ? 'Không được bỏ trống' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              // Thêm validation
              if (_formKey.currentState!.validate()) {
                final balance = double.tryParse(balanceController.text) ?? 0;
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

  // --- HÀM MỚI: HIỂN THỊ DIALOG THÊM NGÂN SÁCH ---
  Future<void> _showAddBudgetDialog(BuildContext context, FirestoreService service, String userId) async {
    final amountController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    String? _selectedCategoryId;

    // Phải dùng StatefulBuilder vì Dialog cần quản lý state của riêng nó (giá trị dropdown)
    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text('Ngân sách mới'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown để chọn Danh mục
                  StreamBuilder<List<Category>>(
                    stream: service.getCategoriesStream(userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      // Lọc bỏ danh mục "Thu nhập" (nếu có)
                      final categories = snapshot.data!
                          .where((cat) => cat.name.toLowerCase() != 'thu nhập')
                          .toList();
                      return DropdownButtonFormField<String>(
                        // Sửa: Dùng 'value' thay vì 'initialValue' để state hoạt động
                        value: _selectedCategoryId,
                        hint: Text('Chọn danh mục chi tiêu'),
                        items: categories.map((cat) {
                          return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() { // Cập nhật state của Dialog
                            _selectedCategoryId = val;
                          });
                        },
                        validator: (value) =>
                        value == null ? 'Phải chọn danh mục' : null,
                      );
                    },
                  ),
                  // Ô nhập Hạn mức
                  TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(labelText: 'Hạn mức chi tiêu'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Không được bỏ trống' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Hủy'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              ElevatedButton(
                child: Text('Thêm'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final double amount = double.tryParse(amountController.text) ?? 0.0;
                    // Lấy ngày đầu tiên của tháng hiện tại
                    final now = DateTime.now();
                    final firstDayOfMonth = DateTime(now.year, now.month, 1);

                    final newBudget = Budget(
                      id: '', // Firestore sẽ tự tạo
                      categoryId: _selectedCategoryId!,
                      amountLimit: amount,
                      date: Timestamp.fromDate(firstDayOfMonth), // Lưu ngày đầu tháng
                    );

                    service.addBudget(userId, newBudget);
                    Navigator.of(ctx).pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
  // --- KẾT THÚC HÀM MỚI ---

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
            // (Code hiển thị danh mục và nút xóa giữ nguyên)
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
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Xác nhận xóa'),
                          content: Text('Bạn có chắc muốn xóa danh mục "${cat.name}"?'),
                          actions: [
                            TextButton(
                              child: Text('Hủy'),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: Text('Xóa'),
                              onPressed: () {
                                firestoreService.deleteCategory(userId, cat.id);
                                Navigator.of(ctx).pop();
                              },
                            ),
                          ],
                        ),
                      );
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
            // (Code hiển thị tài khoản giữ nguyên)
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
                      // (Bạn có thể thêm hàm deleteAccount vào firestore_service.dart
                      // và kích hoạt nút này tương tự như deleteCategory)
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

        // --- 3. QUẢN LÝ NGÂN SÁCH (ĐÃ SỬA LỖI) ---
        _buildSectionTitle(context, 'Quản lý Ngân sách'),
        // LỒNG 2 STREAMBUILDER: 1 để lấy Danh mục, 2 để lấy Ngân sách
        StreamBuilder<List<Category>>(
            stream: firestoreService.getCategoriesStream(userId),
            builder: (context, catSnapshot) {
              if (!catSnapshot.hasData) return Center(child: CircularProgressIndicator());

              // Tạo Map để tra cứu tên: {'cat_id_1': 'Ăn uống', ...}
              final categoryMap = {for (var cat in catSnapshot.data!) cat.id: cat.name};

              return StreamBuilder<List<Budget>>(
                stream: firestoreService.getBudgetsStream(userId),
                builder: (context, budgetSnapshot) {
                  if (!budgetSnapshot.hasData) return Center(child: CircularProgressIndicator());
                  final budgets = budgetSnapshot.data!;

                  // LỖI CỦA BẠN ĐÃ ĐƯỢC DI CHUYỂN VÀO ĐÚNG CHỖ

                  return Column(
                    children: [
                      ...budgets.map((budget) { // <-- 'budget' được định nghĩa ở đây
                        // Tra cứu tên từ Map
                        final categoryName = categoryMap[budget.categoryId] ?? 'Không rõ'; // <-- Giờ 'categoryMap' và 'budget' đã tồn tại

                        return ListTile(
                          leading: Icon(Icons.pie_chart_outline),
                          title: Text('Hạn mức: ${oCcy.format(budget.amountLimit)} VNĐ'),
                          subtitle: Text(
                            'Danh mục: $categoryName', // Hiển thị tên
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                            onPressed: () {
                              // (Code xóa ngân sách đã kích hoạt)
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Xác nhận xóa'),
                                  content: Text('Bạn có chắc muốn xóa ngân sách này?'),
                                  actions: [
                                    TextButton(
                                      child: Text('Hủy'),
                                      onPressed: () => Navigator.of(ctx).pop(),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: Text('Xóa'),
                                      onPressed: () {
                                        firestoreService.deleteBudget(userId, budget.id);
                                        Navigator.of(ctx).pop();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.add, color: Colors.teal),
                        title: Text('Thêm ngân sách mới'),
                        onTap: () {
                          // (Code thêm ngân sách đã kích hoạt)
                          _showAddBudgetDialog(context, firestoreService, userId);
                        },
                      ),
                    ],
                  );
                },
              );
            }
        ),
      ],
    );
  }
}
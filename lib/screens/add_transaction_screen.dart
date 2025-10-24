import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';


class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  AddTransactionScreenState createState() => AddTransactionScreenState();
}

class AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedAccountId;
  bool _isExpense = true;
  final DateTime _selectedDate = DateTime.now();

  Future<void> _submitData() async {
    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredAmount == null || enteredAmount <= 0 || _selectedCategoryId == null || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng nhập đủ thông tin!')));
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId == null) return;

    final finalAmount = _isExpense ? -enteredAmount : enteredAmount;

    final newTx = MyTransaction(
      id: '', // Firestore sẽ tự tạo ID khi .add()
      categoryId: _selectedCategoryId!,
      accountId: _selectedAccountId!,
      note: _noteController.text,
      amount: finalAmount,
      date: _selectedDate,
    );

    try {
      await firestoreService.addTransaction(userId, newTx);
      if (!mounted) return;
      Navigator.of(context).pop(); // Đóng màn hình
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // (Hàm _selectDate để mở Lịch chọn ngày...)

  @override
  Widget build(BuildContext context) {
    // Lấy ID người dùng và các dịch vụ
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUserId!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Giao dịch mới'),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _submitData)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Số tiền'),
              keyboardType: TextInputType.number,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Thu nhập'),
                Switch(value: _isExpense, onChanged: (val) => setState(() => _isExpense = val)),
                Text('Chi tiêu'),
              ],
            ),

            // --- Dropdown Danh mục (Cốt lõi 2) ---
            StreamBuilder<List<Category>>(
              stream: firestoreService.getCategoriesStream(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  hint: Text('Chọn Danh mục'),
                  items: snapshot.data!.map((cat) {
                    return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                );
              },
            ),

            // --- Dropdown Tài khoản (Quan trọng 1) ---
            StreamBuilder<List<Account>>(
              stream: firestoreService.getAccountsStream(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  hint: Text('Chọn Tài khoản'),
                  items: snapshot.data!.map((acc) {
                    return DropdownMenuItem(value: acc.id, child: Text(acc.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                );
              },
            ),

            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: 'Ghi chú'),
            ),
            // (Thêm nút chọn ngày ở đây)
          ],
        ),
      ),
    );
  }
}
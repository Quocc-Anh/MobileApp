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
  // Đổi tên State cho đúng chuẩn
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

// Đổi tên State cho đúng chuẩn
class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedAccountId;

  // --- THAY ĐỔI 1: Thay thế `bool _isExpense` ---
  // Mặc định là 'Chi tiêu'
  String? _transactionType;

  DateTime _selectedDate = DateTime.now(); // Bỏ final để có thể thay đổi

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

    // --- THAY ĐỔI 2: Cập nhật logic tính toán ---
    // Nếu là 'expense' (Chi tiêu), biến số tiền thành số âm
    final finalAmount = (_transactionType == 'expense') ? -enteredAmount : enteredAmount;

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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

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
              decoration: InputDecoration(
                labelText: 'Số tiền',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16), // Thêm khoảng cách

            // --- THAY ĐỔI 3: Thay thế `Row` và `Switch` bằng `DropdownButtonFormField` ---
            DropdownButtonFormField<String>(
              initialValue: _transactionType,
              hint: Text('Chọn Loại Giao dịch'),
              decoration: InputDecoration(
                labelText: 'Loại giao dịch',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'expense',
                  child: Text('Chi tiêu'),
                ),
                DropdownMenuItem(
                  value: 'income',
                  child: Text('Thu nhập'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _transactionType = val;
                  });
                }
              },
            ),
            // --- KẾT THÚC THAY ĐỔI ---

            SizedBox(height: 16), // Thêm khoảng cách

            // --- Dropdown Danh mục (Cốt lõi 2) ---
            StreamBuilder<List<Category>>(
              stream: firestoreService.getCategoriesStream(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return DropdownButtonFormField<String>(
                  // Bỏ `initialValue` và dùng `value` để widget tự cập nhật
                  initialValue: _selectedCategoryId,
                  hint: Text('Chọn Danh mục'),
                  decoration: InputDecoration( // Thêm style cho nhất quán
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: snapshot.data!.map((cat) {
                    return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                );
              },
            ),

            SizedBox(height: 16), // Thêm khoảng cách

            // --- Dropdown Tài khoản (Quan trọng 1) ---
            StreamBuilder<List<Account>>(
              stream: firestoreService.getAccountsStream(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return DropdownButtonFormField<String>(
                  // Bỏ `initialValue` và dùng `value`
                  initialValue: _selectedAccountId,
                  hint: Text('Chọn Tài khoản'),
                  decoration: InputDecoration( // Thêm style cho nhất quán
                    labelText: 'Tài khoản',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: snapshot.data!.map((acc) {
                    return DropdownMenuItem(value: acc.id, child: Text(acc.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                );
              },
            ),

            SizedBox(height: 16), // Thêm khoảng cách

            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: Icon(Icons.calendar_today),
              label: Text('Chọn ngày: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
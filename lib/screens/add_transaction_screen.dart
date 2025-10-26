import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedAccountId;
  String? _transactionType;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat.yMd('vi_VN').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredAmount == null || enteredAmount <= 0 || _selectedCategoryId == null || _selectedAccountId == null || _transactionType == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vui lòng nhập đủ thông tin!')));
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId == null) return;

    final finalAmount = (_transactionType == 'expense') ? -enteredAmount : enteredAmount;

    final newTx = MyTransaction(
      id: '',
      categoryId: _selectedCategoryId!,
      accountId: _selectedAccountId!,
      note: _noteController.text,
      amount: finalAmount,
      date: _selectedDate,
    );

    try {
      await firestoreService.addTransaction(userId, newTx);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat.yMd('vi_VN').format(_selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUserId!;
    final theme = Theme.of(context);

    // --- BẮT ĐẦU SỬA: Bọc nội dung trong SafeArea và giảm Padding ---
    return SafeArea( // Đảm bảo nội dung không bị che khuất (ví dụ bởi notch)
      child: Padding(
        // Giảm padding tổng thể của sheet
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Để Column co lại theo nội dung
          children: [
            // --- TIÊU ĐỀ SHEET (Tùy chọn) ---
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Giao dịch mới',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            // --- KẾT THÚC TIÊU ĐỀ ---

            // Trường nhập liệu
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Số tiền',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12), // <-- Giảm khoảng cách

            DropdownButtonFormField<String>(
              value: _transactionType,
              hint: Text('Chọn Loại Giao dịch'),
              decoration: InputDecoration(
                labelText: 'Loại giao dịch',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                DropdownMenuItem(value: 'expense', child: Text('Chi tiêu')),
                DropdownMenuItem(value: 'income', child: Text('Thu nhập')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _transactionType = val);
              },
              validator: (value) => value == null ? 'Vui lòng chọn loại' : null,
            ),
            SizedBox(height: 12), // <-- Giảm khoảng cách

            StreamBuilder<List<Category>>(
              stream: firestoreService.getCategoriesStream(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox(height: 60, child: Center(child: CircularProgressIndicator())); // Giữ chỗ
                return DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  hint: Text('Chọn Danh mục'),
                  decoration: InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: snapshot.data!.map((cat) {
                    return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  validator: (value) => value == null ? 'Vui lòng chọn danh mục' : null,
                );
              },
            ),
            SizedBox(height: 12), // <-- Giảm khoảng cách

            StreamBuilder<List<Account>>(
              stream: firestoreService.getAccountsStream(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox(height: 60, child: Center(child: CircularProgressIndicator())); // Giữ chỗ
                return DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  hint: Text('Chọn Tài khoản'),
                  decoration: InputDecoration(
                    labelText: 'Tài khoản',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: snapshot.data!.map((acc) {
                    return DropdownMenuItem(value: acc.id, child: Text(acc.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                  validator: (value) => value == null ? 'Vui lòng chọn tài khoản' : null,
                );
              },
            ),
            SizedBox(height: 12), // <-- Giảm khoảng cách

            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 12), // <-- Giảm khoảng cách

            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Ngày giao dịch',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              onTap: () => _selectDate(context),
            ),
            SizedBox(height: 20), // <-- Khoảng cách lớn hơn chút trước nút Lưu

            // --- NÚT LƯU ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Lưu Giao dịch',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    // --- KẾT THÚC SỬA ---
  }
}
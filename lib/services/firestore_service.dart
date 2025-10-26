import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/budget.dart';

/*
 * ===================================================================
 * DỊCH VỤ FIRESTORE (firestore_service.dart)
 * * Đây là lớp "bộ não" CSDL của bạn.
 * Nó chứa TẤT CẢ logic để Ghi, Đọc, Cập nhật, và Xóa
 * dữ liệu từ Cloud Firestore.
 * * Bằng cách tập trung logic ở đây, các file Giao diện (Screens)
 * của bạn sẽ rất gọn gàng và chỉ cần gọi các hàm như:
 * - firestoreService.addTransaction(...)
 * - firestoreService.getCategoriesStream(...)
 * ===================================================================
*/
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. ĐƯỜNG DẪN HELPER ---
  // Các hàm private này giúp code gọn gàng hơn
  // Chúng trỏ đến các "collection con" của một người dùng cụ thể.

  /// Trỏ đến collection: /users/{userId}/transactions
  CollectionReference _transactionsRef(String userId) {
    return _db.collection('users').doc(userId).collection('transactions');
  }

  /// Trỏ đến collection: /users/{userId}/categories
  CollectionReference _categoriesRef(String userId) {
    return _db.collection('users').doc(userId).collection('categories');
  }

  /// Trỏ đến collection: /users/{userId}/accounts
  CollectionReference _accountsRef(String userId) {
    return _db.collection('users').doc(userId).collection('accounts');
  }

  /// Trỏ đến collection: /users/{userId}/budgets
  CollectionReference _budgetsRef(String userId) {
    return _db.collection('users').doc(userId).collection('budgets');
  }

  // --- 2. TRANSACTIONS (Giao dịch) ---
  // (Chức năng Cốt lõi 1 & 3)

  /// Lấy một Stream (luồng dữ liệu) real-time của tất cả giao dịch.
  /// UI sẽ tự động cập nhật khi có giao dịch mới.
  Stream<List<MyTransaction>> getTransactionsStream(String userId) {
    return _transactionsRef(userId)
        .orderBy('date', descending: true) // Sắp xếp mới nhất lên đầu
        .snapshots() // .snapshots() nghĩa là "lắng nghe real-time"
        .map((snapshot) {
      // Chuyển đổi dữ liệu thô (QuerySnapshot) thành một List<MyTransaction>
      return snapshot.docs.map((doc) {
        return MyTransaction.fromJson(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Thêm một giao dịch mới vào CSDL.
  Future<void> addTransaction(String userId, MyTransaction tx) {
    // Firestore sẽ tự tạo ID khi dùng .add()
    return _transactionsRef(userId).add(tx.toJson());
  }

  // (Bạn có thể tự thêm hàm updateTransaction và deleteTransaction ở đây)

  // --- 3. CATEGORIES (Danh mục) ---
  // (Chức năng Cốt lõi 2)

  /// Lấy Stream real-time của tất cả danh mục.
  Stream<List<Category>> getCategoriesStream(String userId) {
    return _categoriesRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Category.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Thêm một danh mục mới.
  Future<void> addCategory(String userId, String name) {
    return _categoriesRef(userId).add({'name': name});
  }

  // --- PHẦN ĐƯỢC THÊM VÀO ---
  /// Xóa một danh mục dựa trên ID của nó.
  Future<void> deleteCategory(String userId, String categoryId) {
    return _categoriesRef(userId).doc(categoryId).delete();
  }
  // -----------------------------

  // (Bạn có thể tự thêm hàm updateCategory ở đây)


  // --- 4. ACCOUNTS (Tài khoản/Ví) ---
  // (Chức năng Quan trọng 1)

  /// Lấy Stream real-time của tất cả tài khoản.
  Stream<List<Account>> getAccountsStream(String userId) {
    return _accountsRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Account.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Thêm một tài khoản mới.
  Future<void> addAccount(String userId, String name, double initialBalance) {
    return _accountsRef(userId).add({
      'name': name,
      'initialBalance': initialBalance,
    });
  }

  // (Bạn có thể tự thêm hàm updateAccount và deleteAccount ở đây)

  // --- 5. BUDGETS (Ngân sách) ---
  // (Chức năng Quan trọng 3) - ĐÃ THÊM MỚI

  /// Lấy Stream real-time của tất cả ngân sách.
  Stream<List<Budget>> getBudgetsStream(String userId) {
    return _budgetsRef(userId)
        .orderBy('date', descending: true) // Sắp xếp theo tháng
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Budget.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Thêm một ngân sách mới.
  Future<void> addBudget(String userId, Budget budget) {
    // Chúng ta dùng budget.toJson() đã định nghĩa trong model
    return _budgetsRef(userId).add(budget.toJson());
  }

// (Bạn có thể tự thêm hàm updateBudget và deleteBudget ở đây)

}
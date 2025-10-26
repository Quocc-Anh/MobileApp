import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/budget.dart';

/*
 * ===================================================================
 * DỊCH VỤ FIRESTORE (firestore_service.dart)
 * ===================================================================
*/
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. ĐƯỜNG DẪN HELPER ---

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

  Stream<List<MyTransaction>> getTransactionsStream(String userId) {
    return _transactionsRef(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MyTransaction.fromJson(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addTransaction(String userId, MyTransaction tx) {
    return _transactionsRef(userId).add(tx.toJson());
  }

  // --- 3. CATEGORIES (Danh mục) ---

  Stream<List<Category>> getCategoriesStream(String userId) {
    return _categoriesRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Category.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addCategory(String userId, String name) {
    return _categoriesRef(userId).add({'name': name});
  }

  Future<void> deleteCategory(String userId, String categoryId) {
    return _categoriesRef(userId).doc(categoryId).delete();
  }

  // --- 4. ACCOUNTS (Tài khoản/Ví) ---

  Stream<List<Account>> getAccountsStream(String userId) {
    return _accountsRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Account.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addAccount(String userId, String name, double initialBalance) {
    return _accountsRef(userId).add({
      'name': name,
      'initialBalance': initialBalance,
    });
  }

  // --- 5. BUDGETS (Ngân sách) ---

  Stream<List<Budget>> getBudgetsStream(String userId) {
    return _budgetsRef(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Budget.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addBudget(String userId, Budget budget) {
    return _budgetsRef(userId).add(budget.toJson());
  }

  // --- 6. HÀM TẠO DỮ LIỆU MẶC ĐỊNH (PHẦN MỚI THÊM) ---

  /// Hàm public để tạo dữ liệu mặc định (Danh mục, Tài khoản) cho người dùng mới
  Future<void> createDefaultUserData(String userId) async {
    // 1. Tạo các danh mục mặc định
    List<String> defaultCategories = [
      'Học tập',
      'Mua sắm',
      'Ăn uống',
      'Du lịch',
      'Tiết kiệm'
    ];

    // Dùng Batch Write để thêm tất cả 1 lần
    WriteBatch batch = _db.batch();

    CollectionReference categoriesRef = _categoriesRef(userId);

    for (String categoryName in defaultCategories) {
      DocumentReference docRef = categoriesRef.doc();
      batch.set(docRef, {'name': categoryName});
    }

    // 2. Tạo 2 tài khoản mặc định (Tiền mặt, Ngân hàng)
    CollectionReference accountsRef = _accountsRef(userId);
    batch.set(accountsRef.doc(), {'name': 'Tiền mặt', 'initialBalance': 0});
    batch.set(accountsRef.doc(), {'name': 'Ngân hàng', 'initialBalance': 0});

    // 3. Commit (gửi) tất cả thay đổi lên server
    await batch.commit();
  }
}
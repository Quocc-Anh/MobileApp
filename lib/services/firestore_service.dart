import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/budget.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference _transactionsRef(String userId) {
    return _db.collection('users').doc(userId).collection('transactions');
  }

  CollectionReference _categoriesRef(String userId) {
    return _db.collection('users').doc(userId).collection('categories');
  }

  CollectionReference _accountsRef(String userId) {
    return _db.collection('users').doc(userId).collection('accounts');
  }

  CollectionReference _budgetsRef(String userId) {
    return _db.collection('users').doc(userId).collection('budgets');
  }

  Stream<List<MyTransaction>> getTransactionsStream(String userId) {
    return _transactionsRef(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MyTransaction.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addTransaction(String userId, MyTransaction tx) {
    return _transactionsRef(userId).add(tx.toJson());
  }

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

  Stream<List<Account>> getAccountsStream(String userId) {
    return _accountsRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Account.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addAccount(String userId, String name, double initialBalance) {
    return _accountsRef(userId).add({'name': name, 'initialBalance': initialBalance});
  }

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

  Future<void> deleteBudget(String userId, String budgetId) {
    return _budgetsRef(userId).doc(budgetId).delete();
  }

  Future<void> deleteAccount(String userId, String accountId) {
    return _accountsRef(userId).doc(accountId).delete();
  }

  Future<void> createDefaultUserData(String userId) async {
    List<String> defaultCategories = ['Học tập', 'Mua sắm', 'Ăn uống', 'Du lịch', 'Tiết kiệm'];

    WriteBatch batch = _db.batch();

    CollectionReference categoriesRef = _categoriesRef(userId);

    for (String categoryName in defaultCategories) {
      DocumentReference docRef = categoriesRef.doc();
      batch.set(docRef, {'name': categoryName});
    }

    CollectionReference accountsRef = _accountsRef(userId);
    batch.set(accountsRef.doc(), {'name': 'Tiền mặt', 'initialBalance': 0});
    batch.set(accountsRef.doc(), {'name': 'Ngân hàng', 'initialBalance': 0});

    await batch.commit();
  }
}
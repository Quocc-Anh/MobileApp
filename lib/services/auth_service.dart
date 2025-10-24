import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream để theo dõi trạng thái đăng nhập (đã đăng nhập hay chưa)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Lấy ID người dùng hiện tại
  String? get currentUserId => _auth.currentUser?.uid;

  // Đăng nhập
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  // Đăng ký
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
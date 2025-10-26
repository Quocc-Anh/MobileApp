import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- THÊM MỚI 1: Tiêm FirestoreService ---
  final FirestoreService _firestoreService;
  // Hàm khởi tạo để nhận FirestoreService
  AuthService(this._firestoreService);
  // ------------------------------------

  // Stream để theo dõi trạng thái đăng nhập (đã đăng nhập hay chưa)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Lấy ID người dùng hiện tại
  String? get currentUserId => _auth.currentUser?.uid;

  // Đăng nhập (Giữ nguyên cấu trúc của bạn)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      // Ném lỗi ra để UI (LoginScreen) có thể bắt và hiển thị
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  // Đăng ký (Kết hợp logic của bạn và logic tạo dữ liệu)
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      // --- THÊM MỚI 2: Gọi hàm tạo dữ liệu mặc định ---
      // Nếu đăng ký thành công, gọi hàm từ FirestoreService
      if (user != null) {
        await _firestoreService.createDefaultUserData(user.uid);
      }
      // ------------------------------------------

      return user;
    } catch (e) {
      // Ném lỗi ra để UI (LoginScreen) có thể bắt
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  // Đăng xuất (Giữ nguyên)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/auth/auth_wrapper.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';


void main() async {
  // Đảm bảo Flutter sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('vi_VN', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider cho phép chúng ta "cung cấp" nhiều dịch vụ
    // cho toàn bộ ứng dụng.
    return MultiProvider(

      // --- BẮT ĐẦU CẬP NHẬT Ở ĐÂY ---
      providers: [
        // 1. Cung cấp FirestoreService (nó không phụ thuộc gì cả)
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),

        // 2. Dùng ProxyProvider để cung cấp AuthService
        // ProxyProvider sẽ "đọc" FirestoreService (ở trên)
        // và "tiêm" nó vào hàm khởi tạo của AuthService
        ProxyProvider<FirestoreService, AuthService>(
          update: (context, firestoreService, previous) =>
              AuthService(firestoreService),
        ),
      ],
      // --- KẾT THÚC CẬP NHẬT ---

      child: MaterialApp(
        title: 'Quản lý Chi tiêu',
        theme: ThemeData(
          useMaterial3: true, // <-- Bật Material 3
          colorSchemeSeed: Colors.teal, // <-- Chọn màu chủ đạo
          brightness: Brightness.light,
          // Áp dụng font chữ mới cho toàn app
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),
        ),

        darkTheme: ThemeData( // <-- (Tùy chọn) Thêm theme tối
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme.apply(bodyColor: Colors.white),
          ),
        ),
        debugShowCheckedModeBanner: false,
        // AuthWrapper sẽ quyết định hiển thị màn hình Đăng nhập hay Trang chủ
        home: AuthWrapper(),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
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
      providers: [
        // Cung cấp dịch vụ Đăng nhập
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        // Cung cấp dịch vụ Database
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
      ],
      child: MaterialApp(
        title: 'Quản lý Chi tiêu',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.grey[50],
        ),
        debugShowCheckedModeBanner: false,
        // AuthWrapper sẽ quyết định hiển thị màn hình Đăng nhập hay Trang chủ
        home: AuthWrapper(),
      ),
    );
  }
}
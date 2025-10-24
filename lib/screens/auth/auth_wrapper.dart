import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import '../main/home_tabs_screen.dart';
import '../../services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          // Nếu user == null (chưa đăng nhập), hiển thị LoginScreen
          // Nếu user != null (đã đăng nhập), hiển thị HomeTabsScreen
          return user == null ? LoginScreen() : HomeTabsScreen();
        }
        // Đang kiểm tra...
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
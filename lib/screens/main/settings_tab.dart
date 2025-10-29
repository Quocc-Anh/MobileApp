import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final User? user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Tài khoản',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 1,
          child: ListTile(
            leading: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
            title: Text('Email đăng nhập'),
            subtitle: Text(
              user?.email ?? 'Không tìm thấy email',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),


        SizedBox(height: 30),

        Card(
          elevation: 0,
          color: theme.colorScheme.errorContainer,
          child: ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.onErrorContainer),
            title: Text(
              'Đăng xuất',
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              // Hiển thị dialog xác nhận trước khi đăng xuất
              final bool? didConfirm = await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Xác nhận đăng xuất'),
                  content: Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?'),
                  actions: [
                    TextButton(
                      child: Text('Hủy'),
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                    TextButton(
                      child: Text('Đăng xuất'),
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ],
                ),
              );

              // Nếu người dùng xác nhận
              if (didConfirm == true) {
                // Gọi hàm signOut
                await authService.signOut();
                // AuthWrapper sẽ tự động điều hướng về màn hình Đăng nhập
              }
            },
          ),
        ),
      ],
    );
  }
}
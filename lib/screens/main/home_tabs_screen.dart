import 'package:flutter/material.dart';
import 'dashboard_tab.dart';
import 'reports_tab.dart';
import 'management_tab.dart';
import 'settings_tab.dart'; // <-- THÊM IMPORT cho tab Cài đặt mới
import '../add_transaction_screen.dart';

class HomeTabsScreen extends StatefulWidget {
  const HomeTabsScreen({super.key});

  @override
  // Đổi tên State cho đúng chuẩn
  _HomeTabsScreenState createState() => _HomeTabsScreenState();
}

// Đổi tên State cho đúng chuẩn
class _HomeTabsScreenState extends State<HomeTabsScreen> {
  int _selectedIndex = 0; // Tab hiện tại

  // --- THAY ĐỔI 1: Cập nhật danh sách Tab (thêm SettingsTab) ---
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardTab(),   // Tab 0: Tổng quan
    ReportsTab(),     // Tab 1: Báo cáo
    ManagementTab(),  // Tab 2: Quản lý (Tab cũ của bạn)
    SettingsTab(),    // Tab 3: Cài đặt (Tab mới có Đăng xuất)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Không cần authService ở đây nữa vì nút Đăng xuất đã chuyển đi
    // final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Trang chủ'),
        // --- THAY ĐỔI 2: Xóa nút Đăng xuất khỏi AppBar ---
        actions: [],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // Nút (+) để thêm Giao dịch (Giữ nguyên)
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(),
              fullscreenDialog: true, // Mở lên như một cửa sổ mới
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- THAY ĐỔI 3: Cập nhật BottomAppBar để có 4 tab ---
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Nhóm bên trái (2 tab)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBottomNavItem(
                    context,
                    icon: Icons.dashboard,
                    label: 'Tổng quan',
                    index: 0,
                  ),
                  _buildBottomNavItem(
                    context,
                    icon: Icons.pie_chart,
                    label: 'Báo cáo',
                    index: 1,
                  ),
                ],
              ),
              // Nhóm bên phải (2 tab)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBottomNavItem(
                    context,
                    icon: Icons.list_alt, // Icon cho "Quản lý"
                    label: 'Quản lý',
                    index: 2,
                  ),
                  _buildBottomNavItem(
                    context,
                    icon: Icons.settings, // Icon cho "Cài đặt"
                    label: 'Cài đặt',
                    index: 3,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- THAY ĐỔI 4: Thêm hàm Helper để code gọn gàng ---
  // (Hàm này tạo 1 nút điều hướng)
  Widget _buildBottomNavItem(BuildContext context, {required IconData icon, required String label, required int index}) {
    final bool isSelected = _selectedIndex == index;
    // Lấy màu sắc từ theme
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final Color inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return MaterialButton(
      minWidth: 40,
      onPressed: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? activeColor : inactiveColor),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 12, // Tự động thu nhỏ chữ
            ),
          ),
        ],
      ),
    );
  }
}
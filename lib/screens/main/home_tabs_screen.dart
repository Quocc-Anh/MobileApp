import 'package:flutter/material.dart';
import 'dashboard_tab.dart';
import 'reports_tab.dart';
import 'management_tab.dart';
import 'budget_tab.dart'; // Đã import
import 'settings_tab.dart';
import '../add_transaction_screen.dart';

class HomeTabsScreen extends StatefulWidget {
  const HomeTabsScreen({super.key});

  @override
  _HomeTabsScreenState createState() => _HomeTabsScreenState();
}

class _HomeTabsScreenState extends State<HomeTabsScreen> {
  int _selectedIndex = 0; // Tab hiện tại

  // Danh sách các Widget cho từng tab (Đã có 5 tab)
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardTab(),   // Index 0: Tổng quan
    ReportsTab(),     // Index 1: Báo cáo
    BudgetTab(),      // Index 2: Ngân sách
    ManagementTab(),  // Index 3: Quản lý
    SettingsTab(),    // Index 4: Cài đặt
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AAA Money'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline), // Icon Add
            tooltip: 'Thêm giao dịch mới', // Chú thích khi hover
            onPressed: () {
              // --- SỬA LẠI LOGIC: DÙNG showDialog ---
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  // Trả về widget AddTransactionScreen bên trong một Dialog
                  return Dialog(
                    // Bo góc dialog
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    // --- BẮT ĐẦU SỬA ---
                    // Bọc AddTransactionScreen trong SingleChildScrollView và Padding
                    // KHÔNG dùng SizedBox nữa để tránh khoảng trống thừa
                    child: SingleChildScrollView( // Cho phép cuộn nếu cần
                      child: Padding(
                        // Bạn có thể để padding là zero hoặc một giá trị nhỏ
                        padding: EdgeInsets.zero,
                        child: AddTransactionScreen(),
                      ),
                    ),
                    // --- KẾT THÚC SỬA ---
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // FAB và vị trí đã bị xóa

      // BottomAppBar giữ nguyên
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildBottomNavItem(
                context,
                icon: Icons.dashboard_outlined,
                label: 'Tổng quan',
                index: 0,
              ),
              _buildBottomNavItem(
                context,
                icon: Icons.pie_chart_outline,
                label: 'Báo cáo',
                index: 1,
              ),
              _buildBottomNavItem(
                context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Ngân sách',
                index: 2,
              ),
              _buildBottomNavItem(
                context,
                icon: Icons.list_alt_outlined,
                label: 'Quản lý',
                index: 3,
              ),
              _buildBottomNavItem(
                context,
                icon: Icons.settings_outlined,
                label: 'Cài đặt',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm helper _buildBottomNavItem giữ nguyên
  Widget _buildBottomNavItem(BuildContext context, {required IconData icon, required String label, required int index}) {
    final bool isSelected = _selectedIndex == index;
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final Color inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;

    IconData displayIcon = icon;
    if (isSelected) {
      switch(icon) {
        case Icons.dashboard_outlined: displayIcon = Icons.dashboard; break;
        case Icons.pie_chart_outline: displayIcon = Icons.pie_chart; break;
        case Icons.account_balance_wallet_outlined: displayIcon = Icons.account_balance_wallet; break;
        case Icons.list_alt_outlined: displayIcon = Icons.list_alt; break;
        case Icons.settings_outlined: displayIcon = Icons.settings; break;
      }
    }

    return MaterialButton(
      minWidth: 35,
      padding: EdgeInsets.symmetric(horizontal: 4),
      onPressed: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(displayIcon, color: isSelected ? activeColor : inactiveColor, size: 24),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ],
      ),
    );
  }
}
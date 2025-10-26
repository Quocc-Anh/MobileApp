import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart'; // Giữ lại nếu cần ở nơi khác
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
        title: Text('Trang chủ'),
        // --- HOÀN NGUYÊN 1: Xóa actions khỏi AppBar ---
        actions: [],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // --- HOÀN NGUYÊN 2: Thêm lại FAB và vị trí ---
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(),
              fullscreenDialog: true,
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // --- KẾT THÚC HOÀN NGUYÊN 2 ---

      // --- BottomAppBar giữ nguyên bố cục 5 tab với khoảng trống ---
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          // Dùng một Row duy nhất và spaceAround
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Phân bổ đều
            children: <Widget>[
              // Tab 0
              _buildBottomNavItem(
                context,
                icon: Icons.dashboard_outlined,
                label: 'Tổng quan',
                index: 0,
              ),
              // Tab 1
              _buildBottomNavItem(
                context,
                icon: Icons.pie_chart_outline,
                label: 'Báo cáo',
                index: 1,
              ),
              // Khoảng trống cho FAB
              SizedBox(width: 40), // Điều chỉnh chiều rộng nếu cần
              // Tab 2 (Ngân sách)
              _buildBottomNavItem(
                context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Ngân sách',
                index: 2,
              ),
              // Tab 3 (Quản lý)
              _buildBottomNavItem(
                context,
                icon: Icons.list_alt_outlined,
                label: 'Quản lý',
                index: 3,
              ),
              // Tab 4 (Cài đặt)
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
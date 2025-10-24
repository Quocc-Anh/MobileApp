import 'package:flutter/material.dart';
import 'package-provider/provider.dart';
import '../../services/auth_service.dart';
import 'dashboard_tab.dart';
import 'reports_tab.dart';
import 'settings_tab.dart';
import '../add_transaction_screen.dart';

class HomeTabsScreen extends StatefulWidget {
  const HomeTabsScreen({super.key});

  @override
  _HomeTabsScreenState createState() => _HomeTabsScreenState();
}

class _HomeTabsScreenState extends State<HomeTabsScreen> {
  int _selectedIndex = 0; // Tab hiện tại

  // Danh sách các Tab
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardTab(), // Tab 1: Lịch sử (Cốt lõi 3)
    ReportsTab(),   // Tab 2: Báo cáo (Quan trọng 2)
    SettingsTab(),  // Tab 3: Cài đặt (Cốt lõi 2, Quan trọng 1, Quan trọng 3)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Trang chủ'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              // AuthWrapper sẽ tự động xử lý
            },
          )
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // Nút (+) để thêm Giao dịch (Cốt lõi 1)
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
      // Thanh điều hướng dưới cùng
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () => _onItemTapped(0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard, color: _selectedIndex == 0 ? Colors.teal : Colors.grey),
                        Text('Tổng quan', style: TextStyle(color: _selectedIndex == 0 ? Colors.teal : Colors.grey)),
                      ],
                    ),
                  ),
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () => _onItemTapped(1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pie_chart, color: _selectedIndex == 1 ? Colors.teal : Colors.grey),
                        Text('Báo cáo', style: TextStyle(color: _selectedIndex == 1 ? Colors.teal : Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              // Nút bên phải
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MaterialButton(
                    minWidth: 40,
                    onPressed: () => _onItemTapped(2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.settings, color: _selectedIndex == 2 ? Colors.teal : Colors.grey),
                        Text('Cài đặt', style: TextStyle(color: _selectedIndex == 2 ? Colors.teal : Colors.grey)),
                      ],
                    ),
                  ),
                  // Bạn có thể thêm Tab Ngân sách (Budget) ở đây
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
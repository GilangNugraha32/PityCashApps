import 'package:flutter/material.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/view/categories/tambah_categories.dart';
import 'package:pity_cash/view/pemasukan/pemasukan_section.dart';
import 'package:pity_cash/view/categories/categories_section.dart';
import 'package:pity_cash/view/pemasukan/tambah_pemasukan.dart';
import 'package:pity_cash/view/pengeluaran/pengeluaran_section.dart';
import 'package:pity_cash/view/pengeluaran/tambah_pengeluaran.dart';
import 'package:pity_cash/view/profile/profile_section.dart';
import 'package:pity_cash/view/home/home_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  HomeScreen({this.initialIndex = 0});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  String? _token;
  String? _userName;
  Map<String, dynamic>? _userRoles;
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  final List<Widget> _pages = [
    HomeSection(),
    CategoriesSection(),
    PemasukanSection(),
    PengeluaranSection(),
    ProfileSection(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _token = await _prefsService.getToken();
    _userName = await _prefsService.getUserName();

    if (_token == null) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Tambahkan ini untuk mencegah resize
      body: _pages[_selectedIndex],
      floatingActionButton: Container(
        height: 65,
        width: 65,
        child: FittedBox(
          child: FloatingActionButton(
            backgroundColor: Color(0xFFEB8153),
            elevation: 8,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(25.0)),
                ),
                builder: (BuildContext context) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      double modalHeight = constraints.maxHeight * 0.28;
                      double buttonWidth = constraints.maxWidth * 0.45;
                      return Container(
                        height: modalHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(25.0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Handle bar
                            Container(
                              margin: EdgeInsets.only(top: 12, bottom: 8),
                              width: 50.0,
                              height: 4.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFEB8153).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),

                            // Title
                            Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Pilih Aksi Tambah',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEB8153),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            // Divider
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 24.0),
                              child: Divider(
                                color: Color(0xFFEB8153).withOpacity(0.2),
                                thickness: 1.0,
                              ),
                            ),

                            // Action buttons
                            Expanded(
                              child: Padding(
                                padding:
                                    EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                                child: Column(
                                  children: [
                                    // Top row buttons
                                    Expanded(
                                      child: Row(
                                        children: [
                                          // Pemasukan button
                                          Expanded(
                                            child: _buildElevatedActionButton(
                                              width: buttonWidth,
                                              icon: Icons.add_card_sharp,
                                              title: 'Pemasukan',
                                              onTap: () async {
                                                Navigator.pop(context);
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        TambahPemasukan(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          // Pengeluaran button
                                          Expanded(
                                            child: _buildElevatedActionButton(
                                              width: buttonWidth,
                                              icon: Icons
                                                  .add_shopping_cart_outlined,
                                              title: 'Pengeluaran',
                                              onTap: () async {
                                                Navigator.pop(context);
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        TambahPengeluaran(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 12),

                                    // Bottom kategori button
                                    _buildElevatedActionButton(
                                      width: double.infinity,
                                      icon: Icons.add_chart,
                                      title: 'Kategori',
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TambahCategories(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            child: Icon(
              Icons.post_add,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          child: BottomAppBar(
            notchMargin: 8.0,
            shape: CircularNotchedRectangle(),
            child: Container(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildNavItem(
                        0, Icons.home, Icons.home_outlined, 'Home'),
                  ),
                  Expanded(
                    child: _buildNavItem(1, Icons.analytics,
                        Icons.analytics_outlined, 'Category'),
                  ),
                  Expanded(child: SizedBox()),
                  Expanded(
                    child: _buildTransactionNavItem(),
                  ),
                  Expanded(
                    child: _buildNavItem(4, Icons.person,
                        Icons.person_outline_outlined, 'Profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElevatedActionButton({
    required double width,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Color(0xFFFFF4EE),
              border: Border.all(
                color: Color(0xFFEB8153).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Color(0xFFEB8153), size: 24),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEB8153),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData selectedIcon, IconData unselectedIcon, String label,
      {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _onItemTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedIndex == index ? selectedIcon : unselectedIcon,
              color: _selectedIndex == index ? Color(0xFFEB8153) : Colors.grey,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    _selectedIndex == index ? Color(0xFFEB8153) : Colors.grey,
                fontSize: 12,
                fontWeight: _selectedIndex == index
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionNavItem() {
    bool isTransactionSelected = _selectedIndex == 2 || _selectedIndex == 3;

    return PopupMenuButton<int>(
      offset: Offset(0, -120),
      onSelected: (int index) {
        _onItemTapped(index);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isTransactionSelected
                    ? Icons.receipt_long
                    : Icons.receipt_long_outlined,
                color: isTransactionSelected ? Color(0xFFEB8153) : Colors.grey,
              ),
              SizedBox(height: 4),
              Text(
                'Transaction',
                style: TextStyle(
                  color:
                      isTransactionSelected ? Color(0xFFEB8153) : Colors.grey,
                  fontSize: 12,
                  fontWeight: isTransactionSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        PopupMenuItem<int>(
          value: 2,
          child: Text('Pemasukan'),
        ),
        PopupMenuItem<int>(
          value: 3,
          child: Text('Pengeluaran'),
        ),
      ],
    );
  }
}

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
  bool isReader = false;

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
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    var roles = await _prefsService.getRoles();
    if (roles != null && roles['roles'] is List && roles['roles'].isNotEmpty) {
      setState(() {
        isReader = roles['roles'][0]['name'] == 'Reader';
      });
    }
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
      resizeToAvoidBottomInset: false,
      body: _pages[_selectedIndex],
      floatingActionButton: !isReader ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation:
          !isReader ? FloatingActionButtonLocation.centerDocked : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.0),
            topRight: Radius.circular(12.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.0),
            topRight: Radius.circular(12.0),
          ),
          child: BottomAppBar(
            notchMargin: 6.0,
            shape: !isReader ? CircularNotchedRectangle() : null,
            child: Container(
              height: 55,
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
                  if (!isReader) Expanded(child: SizedBox()),
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

  Widget _buildFloatingActionButton() {
    return Container(
      height: 55,
      width: 55,
      child: FittedBox(
        child: FloatingActionButton(
          backgroundColor: Color(0xFFEB8153),
          elevation: 6,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
              ),
              builder: (BuildContext context) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final size = MediaQuery.of(context).size;
                    final modalHeight = size.height * 0.22;
                    final buttonHeight = modalHeight * 0.25;
                    final spacing = size.height * 0.006;

                    return Container(
                      height: modalHeight,
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.03,
                        vertical: size.height * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16.0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: size.width * 0.08,
                            height: 3,
                            margin: EdgeInsets.only(bottom: spacing),
                            decoration: BoxDecoration(
                              color: Color(0xFFEB8153).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Pilih Aksi Tambah',
                            style: TextStyle(
                              fontSize: size.width * 0.038,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEB8153),
                            ),
                          ),
                          SizedBox(height: 12),
                          Divider(
                            color: Color(0xFFEB8153).withOpacity(0.2),
                            thickness: 1,
                            height: spacing * 2.5,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildElevatedActionButton(
                                          width: double.infinity,
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
                                      SizedBox(width: spacing),
                                      Expanded(
                                        child: _buildElevatedActionButton(
                                          width: double.infinity,
                                          icon:
                                              Icons.add_shopping_cart_outlined,
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
                                SizedBox(height: spacing),
                                Expanded(
                                  flex: 2,
                                  child: _buildElevatedActionButton(
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
                                ),
                              ],
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
            size: 28,
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Color(0xFFFFF4EE),
              border: Border.all(
                color: Color(0xFFEB8153).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Color(0xFFEB8153), size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
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
              size: 22,
            ),
            SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color:
                    _selectedIndex == index ? Color(0xFFEB8153) : Colors.grey,
                fontSize: 11,
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
      offset: Offset(0, -100),
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
                size: 22,
              ),
              SizedBox(height: 3),
              Text(
                'Transaction',
                style: TextStyle(
                  color:
                      isTransactionSelected ? Color(0xFFEB8153) : Colors.grey,
                  fontSize: 11,
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

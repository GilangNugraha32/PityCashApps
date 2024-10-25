import 'package:flutter/material.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/view/pemasukan/pemasukan_section.dart';
import 'package:pity_cash/view/categories/categories_section.dart';
import 'package:pity_cash/view/pengeluaran/pengeluaran_section.dart';
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
  late int _selectedIndex; // Track the selected index of the navigation bar
  String? _token;
  String? _userName;
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  final List<Widget> _pages = [
    HomeSection(), // Home section
    CategoriesSection(), // Categories section
    PemasukanSection(),
    PengeluaranSection(), // Activity section
    ProfileSection(), // Profile section
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadUserData(); // Load user data when the screen initializes
  }

  Future<void> _loadUserData() async {
    _token = await _prefsService.getToken(); // Use service to get the token
    _userName = await _prefsService.getUserName(); // Get the username

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
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white10, // Background color of the navigation bar
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0), // Radius for the top-left corner
            topRight: Radius.circular(16.0), // Radius for the top-right corner
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 4,
              offset: Offset(0, -2), // Position of the shadow
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0), // Radius for the top-left corner
            topRight: Radius.circular(16.0), // Radius for the top-right corner
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed, // No animation for tab change
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: _selectedIndex == 0
                    ? Icon(Icons.home) // Filled icon for selected
                    : Icon(Icons.home_outlined), // Outlined icon for unselected
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 1
                    ? Icon(Icons.analytics) // Filled icon for selected
                    : Icon(Icons
                        .analytics_outlined), // Outlined icon for unselected
                label: 'Category',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 2
                    ? Icon(Icons.real_estate_agent) // Ikon baru untuk Pemasukan
                    : Icon(Icons.real_estate_agent_outlined),
                label: 'Inflow',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 3
                    ? Icon(Icons
                        .shopping_cart_checkout) // Ikon baru untuk Pengeluaran
                    : Icon(Icons.shopping_cart_checkout_outlined),
                label: 'Outflow',
              ),
              BottomNavigationBarItem(
                icon: _selectedIndex == 4
                    ? Icon(Icons.person) // Filled icon for selected
                    : Icon(
                        Icons.person_outline), // Outlined icon for unselected
                label: 'Profile',
              ),
            ],
            selectedItemColor:
                Color(0xFFEB8153), // Orange color for the selected item
            unselectedItemColor: Colors.grey, // Color for the unselected items
            backgroundColor:
                Colors.white, // Background color of the navigation bar
            showSelectedLabels: true, // Show label for selected item
            showUnselectedLabels: true, // Show label for unselected items
            selectedLabelStyle:
                TextStyle(fontSize: 12), // Font size for selected label
            unselectedLabelStyle:
                TextStyle(fontSize: 12), // Font size for unselected label
          ),
        ),
      ),
    );
  }
}

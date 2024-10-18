import 'package:flutter/material.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/models/outcomes_model.dart';
import 'package:pity_cash/service/share_preference.dart';

class HomeSection extends StatefulWidget {
  @override
  _HomeSectionState createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  double saldo = 0.0;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isIncomeSelected = true; // Initial state
  String? token; // Token variable
  String? name; // User name variable
  bool isLoggedIn = false; // Track login status

  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    _getSaldo();
    super.initState();
    _checkLoginStatus(); // Check login status on init
  }

  Future<void> _getSaldo() async {
    try {
      final fetchedSaldo =
          await _apiService.fetchSaldo(); // Panggil fungsi fetchSaldo
      setState(() {
        saldo = fetchedSaldo; // Update saldo dengan hasil dari API
        isLoading = false; // Matikan loading setelah saldo berhasil diambil
      });
    } catch (e) {
      print('Failed to load saldo: $e');
      setState(() {
        saldo = 0.0; // Atur saldo ke 0 jika gagal
        isLoading = false; // Matikan loading jika gagal mengambil saldo
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    token = await _prefsService.getToken(); // Retrieve token
    name = await _prefsService.getUserName(); // Retrieve user name
    setState(() {
      isLoggedIn = token != null; // Update login status
    });
  }

  Future<void> _logout(BuildContext context) async {
    await _prefsService.removeToken(); // Remove token
    await _prefsService.removeUser(); // Hapus data user
    setState(() {
      isLoggedIn = false; // Update login status
    });
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _handleSectionClick(bool isIncome) {
    setState(() {
      isIncomeSelected = isIncome;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEB8153), Color(0xFFFF9D6C)],
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isLoggedIn ? 'Hi, $name!' : 'Hi, Guest!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: Text(
                      'Saldo Pity Cash',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 2),
                  Center(
                    child: isLoading
                        ? CircularProgressIndicator() // Show loading indicator while data is being fetched
                        : Text(
                            NumberFormat.currency(
                              locale: 'id_ID', // Format for IDR
                              symbol: 'Rp', // Currency symbol
                              decimalDigits:
                                  0, // Set decimal digits to 0 to remove the cents
                            ).format(saldo), // Display the saldo from the API
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  SizedBox(height: 12),
                  // Custom Toggle button for Income and Expense
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 60),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.all(6),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _handleSectionClick(true),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isIncomeSelected
                                    ? Color(0xFFEB8153)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Center(
                                child: Text(
                                  'Income',
                                  style: TextStyle(
                                    color: isIncomeSelected
                                        ? Colors.white
                                        : Color(0xFFB8B8B8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _handleSectionClick(false),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !isIncomeSelected
                                    ? Color(0xFFEB8153)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Center(
                                child: Text(
                                  'Expense',
                                  style: TextStyle(
                                    color: !isIncomeSelected
                                        ? Colors.white
                                        : Color(0xFFB8B8B8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This month income',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '\$7.000,00',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 16),
                          // Add your chart here
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: Colors.grey[200],
                            ),
                            child: Center(
                              child: Text('Chart goes here'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your recent income',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          ListTile(
                            leading: Icon(Icons.coffee),
                            title: Text('Maju Jaya Coffee'),
                            subtitle: Text('October 4, 2020'),
                            trailing: Text('\$2.000,00'),
                          ),
                          ListTile(
                            leading: Icon(Icons.settings),
                            title: Text('Zeus Motorworks'),
                            subtitle: Text('October 4, 2020'),
                            trailing: Text('\$4.000,00'),
                          ),
                          ListTile(
                            leading: Icon(Icons.design_services),
                            title: Text('Freelance Design'),
                            subtitle: Text('October 4, 2020'),
                            trailing: Text('\$1.000,00'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

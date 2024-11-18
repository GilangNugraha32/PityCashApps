import 'package:flutter/material.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/view/home/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/models/outcomes_model.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'dart:math' show max, min, pi;

class HomeSection extends StatefulWidget {
  @override
  _HomeSectionState createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection>
    with SingleTickerProviderStateMixin {
  double saldo = 0.0;
  double scrollOffset = 0.0;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isIncomeSelected = true;
  String? token;
  String? name;
  bool isLoggedIn = false;

  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final ApiService _apiService = ApiService();

  late AnimationController _animationController;
  late Animation<double> _animation;

  List<Pengeluaran> expenses = []; // Tambahkan baris ini
  List<Pemasukan> incomes = []; // Tambahkan baris ini

  int selectedYear = DateTime.now().year; // Tambahkan baris ini

  bool isBalanceVisible = true; // Tambahkan baris ini

  @override
  void initState() {
    super.initState();
    _getSaldo();
    _getSaldoKeseluruhan();
    _getMinSaldo();
    _checkLoginStatus();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double minSaldo = 0.0;
  double saldoKeseluruhan = 0.0;

  Future<void> _getSaldoKeseluruhan() async {
    try {
      final fetchedSaldoKeseluruhan =
          await _apiService.fetchSaldopPemasukkanKeseluruhan();
      setState(() {
        saldoKeseluruhan = fetchedSaldoKeseluruhan;
      });
    } catch (e) {
      print('Gagal memuat saldo keseluruhan: $e');
      setState(() {
        saldoKeseluruhan = 0.0;
      });
    }
  }

  Future<void> _getMinSaldo() async {
    try {
      final fetchedMinSaldo = await _apiService.fetchPengeluaranSaldoSeluruh();
      setState(() {
        minSaldo = fetchedMinSaldo;
      });
    } catch (e) {
      print('Gagal memuat pengurangan saldo : $e');
      setState(() {
        minSaldo = 0.0;
      });
    }
  }

  Future<void> _getSaldo() async {
    try {
      final fetchedSaldo = await _apiService.fetchSaldo();
      setState(() {
        saldo = fetchedSaldo;
        isLoading = false;
      });
    } catch (e) {
      print('Failed to load saldo: $e');
      setState(() {
        saldo = 0.0;
        isLoading = false;
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    token = await _prefsService.getToken();
    name = await _prefsService.getUserName();
    setState(() {
      isLoggedIn = token != null;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await _prefsService.removeToken();
    await _prefsService.removeUser();
    setState(() {
      isLoggedIn = false;
    });
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _handleSectionClick(bool isIncome) {
    setState(() {
      isIncomeSelected = isIncome;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 10),
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildThisMonthIncomeCard(),
                  SizedBox(height: 10),
                  _buildSaldoCard(),
                  SizedBox(height: 10),
                  _buildRecentTransactions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final screenSize = MediaQuery.of(context).size;
    final double paddingScale = screenSize.width < 360 ? 0.8 : 1.0;
    final double iconScale = screenSize.width < 360 ? 0.8 : 1.0;
    final double fontScale = screenSize.width < 360 ? 0.9 : 1.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          bottom: 12.0 * paddingScale), // Mengurangi padding bawah
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEB8153), Color(0xFFFF9D6C)],
          stops: [0.3, 0.9],
        ),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(30.0),
          bottomLeft: Radius.circular(30.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFEB8153).withOpacity(0.25),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -25,
              bottom: -15,
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: screenSize.width * 0.4 * iconScale,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            // Main content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0 * paddingScale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12 * paddingScale), // Mengurangi spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * paddingScale,
                          vertical: 6 * paddingScale,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person,
                                color: Colors.white.withOpacity(0.9),
                                size: 16 * iconScale),
                            SizedBox(width: 6 * paddingScale),
                            Text(
                              isLoggedIn ? 'Hi, $name' : 'Hi, Guest',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13 * fontScale,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Container(
                      //   padding: EdgeInsets.all(6 * paddingScale),
                      //   decoration: BoxDecoration(
                      //     color: Colors.white.withOpacity(0.2),
                      //     borderRadius: BorderRadius.circular(10),
                      //   ),
                      //   child: Icon(Icons.notifications_outlined,
                      //       color: Colors.white, size: 18 * iconScale),
                      // ),
                    ],
                  ),
                  SizedBox(height: 12 * paddingScale), // Mengurangi spacing
                  Center(
                    child: Text(
                      'Saldo Pity Cash',
                      style: TextStyle(
                        fontSize: 13 * fontScale,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 2 * paddingScale),
                  Center(
                    child: FutureBuilder<double>(
                      future: ApiService().fetchMinimalSaldo(),
                      builder: (context, snapshot) {
                        double minimalSaldo = snapshot.data ?? 0;
                        bool isLowBalance = saldo <= minimalSaldo;
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 10 * paddingScale),
                                Expanded(
                                  child: Text(
                                    isBalanceVisible
                                        ? NumberFormat.currency(
                                            locale: 'id_ID',
                                            symbol: 'Rp',
                                            decimalDigits: 0,
                                          ).format(saldo)
                                        : 'Rp' + _formatHiddenBalance(saldo),
                                    style: TextStyle(
                                      fontSize: 24 * fontScale,
                                      fontWeight: FontWeight.bold,
                                      color: isLowBalance
                                          ? Color(0xFFF54D42)
                                          : Colors.white,
                                      letterSpacing: 1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isBalanceVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 18 * iconScale,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isBalanceVisible = !isBalanceVisible;
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (isLowBalance)
                              Container(
                                margin: EdgeInsets.only(
                                    top: 8 * paddingScale), // Mengurangi margin
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10 * paddingScale,
                                  vertical: 5 * paddingScale,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.yellow.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.yellow.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.yellow[100],
                                      size: 14 * iconScale,
                                    ),
                                    SizedBox(width: 5 * paddingScale),
                                    Text(
                                      'Saldo di bawah batas minimal',
                                      style: TextStyle(
                                        color: Colors.yellow[100],
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11 * fontScale,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(width: 3 * paddingScale),
                                    Text(
                                      '(${NumberFormat.currency(
                                        locale: 'id_ID',
                                        symbol: 'Rp',
                                        decimalDigits: 0,
                                      ).format(minimalSaldo)})',
                                      style: TextStyle(
                                        color: Colors.yellow[100]
                                            ?.withOpacity(0.8),
                                        fontSize: 11 * fontScale,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 4 * paddingScale),
                  _buildIncomeExpenseToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHiddenBalance(double balance) {
    String balanceStr = balance.toStringAsFixed(0);
    List<String> parts = [];
    for (int i = 0; i < balanceStr.length; i += 3) {
      int end = i + 3;
      if (end > balanceStr.length) end = balanceStr.length;
      parts.add('•••');
    }
    return parts.join(',');
  }

  Widget _buildIncomeExpenseToggle() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('Inflow', isIncomeSelected, Icons.arrow_upward),
          _buildToggleOption(
              'Outflow', !isIncomeSelected, Icons.arrow_downward),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _handleSectionClick(text == 'Inflow');
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFEB8153) : Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Color(0xFFB8B8B8),
              ),
              SizedBox(width: 2),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFFB8B8B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThisMonthIncomeCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F8F8)],
          ),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Perbandingan Pemasukan & Pengeluaran',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_animationController.value > 0.5) {
                    _animationController.animateTo(0.4);
                  } else {
                    _animationController.animateTo(1.0);
                  }
                });
              },
              child: Container(
                height: MediaQuery.of(context).size.width * 0.35,
                width: MediaQuery.of(context).size.width * 0.35,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder(
                      duration: Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return CustomPaint(
                          size: Size(MediaQuery.of(context).size.width * 0.35,
                              MediaQuery.of(context).size.width * 0.35),
                          painter: DoubleRadialChartPainter(
                            outerPercentage: (saldoKeseluruhan /
                                    (saldoKeseluruhan + minSaldo)) *
                                100 *
                                value,
                            innerPercentage:
                                (minSaldo / (saldoKeseluruhan + minSaldo)) *
                                    100 *
                                    value,
                            outerColor: Color(0xFF66BB6A),
                            innerColor: Color(0xFFEF5350),
                          ),
                        );
                      },
                    ),
                    AnimatedOpacity(
                      duration: Duration(milliseconds: 300),
                      opacity: _animationController.value,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        width: MediaQuery.of(context).size.width * 0.28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.98),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 2,
                              spreadRadius: 0.3,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pemasukan: ${((saldoKeseluruhan / (saldoKeseluruhan + minSaldo)) * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Color(0xFF66BB6A),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pengeluaran: ${((minSaldo / (saldoKeseluruhan + minSaldo)) * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Color(0xFFEF5350),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            TweenAnimationBuilder(
              duration: Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(
                begin: 0,
                end: saldoKeseluruhan + minSaldo,
              ),
              builder: (context, double value, child) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.4),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Keseluruhan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        isBalanceVisible
                            ? NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp',
                                decimalDigits: 0,
                              ).format(value)
                            : 'Rp' + _formatHiddenBalance(value),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItemEnhanced("Pemasukan",
                              Color(0xFF66BB6A), Icons.arrow_upward),
                          SizedBox(width: 12),
                          _buildLegendItemEnhanced("Pengeluaran",
                              Color(0xFFEF5350), Icons.arrow_downward),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.black87),
          SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItemEnhanced(String label, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7589A2),
          ),
        ),
      ],
    );
  }

  Widget _buildSaldoCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final itemWidth = (cardWidth - 48) / 2;

        return Card(
          elevation: 1.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ringkasan Keuangan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          isBalanceVisible = !isBalanceVisible;
                        });
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFEB8153).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBalanceVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Color(0xFFEB8153),
                              size: 14,
                            ),
                            SizedBox(width: 3),
                            Text(
                              isBalanceVisible ? 'Sembunyikan' : 'Tampilkan',
                              style: TextStyle(
                                color: Color(0xFFEB8153),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSaldoItem(
                      'Pemasukan Keseluruhan',
                      saldoKeseluruhan,
                      Colors.green,
                      Icons.trending_up,
                      itemWidth,
                      isBalanceVisible,
                    ),
                    Container(
                      height: 60,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    _buildSaldoItem(
                      'Pengeluaran Keseluruhan',
                      minSaldo,
                      Colors.red,
                      Icons.trending_down,
                      itemWidth,
                      isBalanceVisible,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaldoItem(String title, double amount, Color color,
      IconData icon, double width, bool isBalanceVisible) {
    return Container(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Icon(
                icon,
                color: color,
                size: 14,
              ),
            ],
          ),
          SizedBox(height: 5),
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: amount),
            duration: Duration(seconds: 1),
            builder: (context, value, child) {
              return Text(
                isBalanceVisible
                    ? NumberFormat.currency(
                            locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
                        .format(value)
                    : 'Rp' + _formatHiddenBalance(value),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerbandinganSaldo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final itemWidth = (cardWidth - 48) / 2;

        return Card(
          elevation: 6.0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perbandingan Pemasukan dan Pengurangan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPerbandinganItem(
                      'Pemasukan Keseluruhan',
                      saldoKeseluruhan,
                      Colors.green,
                      Icons.trending_up,
                      itemWidth,
                    ),
                    Container(
                      height: 60,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    _buildPerbandinganItem(
                      'Pengeluaran Keseluruhan',
                      minSaldo,
                      Colors.red,
                      Icons.trending_down,
                      itemWidth,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerbandinganItem(
      String title, double amount, Color color, IconData icon, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ),
              Icon(icon, color: color, size: 14),
            ],
          ),
          SizedBox(height: 3),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp',
              decimalDigits: 0,
            ).format(amount),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchIncomes(int page) async {
    if (isLoadingMore) return;

    setState(() {
      isLoading = true;
    });

    try {
      print('Mengambil pemasukan untuk halaman: $page');
      final fetchedIncomes = await _apiService.fetchIncomes(page: page);
      print('Pemasukan yang diambil: ${fetchedIncomes.toString()}');

      setState(() {
        if (page == 1) {
          incomes = fetchedIncomes;
        } else {
          incomes.addAll(fetchedIncomes);
        }
      });
    } catch (e) {
      print('Kesalahan saat mengambil pemasukan: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _fetchExpenses(int page) async {
    if (isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final fetchedExpenses = await _apiService.fetchExpenses(
        page: page,
      );

      print('Pengeluaran yang diambil: ${fetchedExpenses.toString()}');

      setState(() {
        if (page == 1) {
          expenses = fetchedExpenses;
        } else {
          expenses.addAll(fetchedExpenses);
        }
      });

      if (fetchedExpenses.isEmpty) {
        setState(() {
          isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Kesalahan saat mengambil pengeluaran: $e');
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Widget _buildRecentTransactions() {
    List<dynamic> recentTransactions = [];

    String _getMonthName(int month) {
      const monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      return monthNames[month - 1];
    }

    if (isIncomeSelected) {
      if (incomes.isNotEmpty) {
        recentTransactions = incomes.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        recentTransactions = recentTransactions.take(4).toList();
      } else {
        _fetchIncomes(1);
      }
    } else {
      if (expenses.isNotEmpty) {
        recentTransactions = expenses.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        recentTransactions = recentTransactions.take(4).toList();
      } else {
        _fetchExpenses(1);
      }
    }

    return Card(
      elevation: 8.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isIncomeSelected
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: Color(0xFFEB8153),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isIncomeSelected ? 'Pemasukan' : 'Pengeluaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  if (!isLoading)
                    TextButton(
                      child: Text(
                        'Selengkapnya....',
                        style: TextStyle(
                          color: Color(0xFFEB8153),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(
                                initialIndex: isIncomeSelected ? 2 : 3),
                          ),
                        );
                      },
                    ),
                ],
              ),
              SizedBox(height: 16),
              if (isLoading)
                Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFEB8153)),
                  ),
                )
              else if (recentTransactions.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 32,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...recentTransactions.map((transaction) {
                  IconData icon;
                  String date;
                  double amount;
                  String name;
                  if (isIncomeSelected) {
                    icon = Icons.attach_money;
                    DateTime parsedDate = DateTime.parse(transaction.date);
                    date =
                        '${parsedDate.day} ${_getMonthName(parsedDate.month)} ${parsedDate.year}';
                    amount = double.parse(transaction.jumlah);
                    name = transaction.name;
                  } else {
                    icon = Icons.money_off;
                    if (transaction.tanggal is DateTime) {
                      date =
                          '${transaction.tanggal.day} ${_getMonthName(transaction.tanggal.month)} ${transaction.tanggal.year}';
                    } else {
                      DateTime parsedDate =
                          DateTime.parse(transaction.tanggal.toString());
                      date =
                          '${parsedDate.day} ${_getMonthName(parsedDate.month)} ${parsedDate.year}';
                    }
                    amount = transaction.jumlah.toDouble();
                    name = transaction.name;
                  }
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: _buildTransactionItem(
                      name,
                      date,
                      amount,
                      icon,
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
      String title, String date, double amount, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Color(0xFFEB8153).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Color(0xFFEB8153), size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      subtitle: Text(date, style: TextStyle(fontSize: 11)),
      trailing: Text(
        NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp',
          decimalDigits: 0,
        ).format(amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFEB8153),
          fontSize: 12,
        ),
      ),
    );
  }
}

class RadialChartPainter extends CustomPainter {
  final double inflow;
  final double outflow;

  RadialChartPainter({required this.inflow, required this.outflow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Gambar background
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    canvas.drawCircle(center, radius - 10, bgPaint);

    // Gambar chart
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // Gambar inflow (hijau)
    paint.color = Color(0xFF66BB6A);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -pi / 2,
      (inflow / 100) * 2 * pi,
      false,
      paint,
    );

    // Gambar outflow (merah)
    paint.color = Color(0xFFEF5350);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      (inflow / 100) * 2 * pi - pi / 2,
      (outflow / 100) * 2 * pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DoubleRadialChartPainter extends CustomPainter {
  final double outerPercentage;
  final double innerPercentage;
  final Color outerColor;
  final Color innerColor;

  DoubleRadialChartPainter({
    required this.outerPercentage,
    required this.innerPercentage,
    required this.outerColor,
    required this.innerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) / 2;
    final innerRadius = outerRadius * 0.6; // Diperkecil dari 0.7 ke 0.6

    // Gambar background abu-abu untuk outer circle
    final bgOuterPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15; // Diperkecil dari 20 ke 15
    canvas.drawCircle(center, outerRadius - 8,
        bgOuterPaint); // Diperkecil offset dari 10 ke 8

    // Gambar background abu-abu untuk inner circle
    final bgInnerPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15; // Diperkecil dari 20 ke 15
    canvas.drawCircle(center, innerRadius - 8,
        bgInnerPaint); // Diperkecil offset dari 10 ke 8

    // Gambar outer circle
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15 // Diperkecil dari 20 ke 15
      ..strokeCap = StrokeCap.round
      ..color = outerColor;

    // Gambar inner circle
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15 // Diperkecil dari 20 ke 15
      ..strokeCap = StrokeCap.round
      ..color = innerColor;

    canvas.drawArc(
      Rect.fromCircle(
          center: center,
          radius: outerRadius - 8), // Diperkecil offset dari 10 ke 8
      -pi / 2,
      (outerPercentage / 100) * 2 * pi,
      false,
      outerPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
          center: center,
          radius: innerRadius - 8), // Diperkecil offset dari 10 ke 8
      -pi / 2,
      (innerPercentage / 100) * 2 * pi,
      false,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

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
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max;

class HomeSection extends StatefulWidget {
  @override
  _HomeSectionState createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection>
    with SingleTickerProviderStateMixin {
  double saldo = 0.0;
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
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildThisMonthIncomeCard(),
                  SizedBox(height: 16),
                  _buildSaldoCard(),
                  SizedBox(height: 16),
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(bottom: 20.0),
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
            color: Colors.orange.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isLoggedIn ? 'Hi, $name' : 'Hi, Guest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.notifications, color: Colors.white, size: 24),
                ],
              ),
              SizedBox(height: 30),
              Center(
                child: Text(
                  'Saldo Pity Cash',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: FutureBuilder<double>(
                  future: ApiService().fetchMinimalSaldo(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(color: Colors.white);
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.white));
                    } else {
                      double minimalSaldo = snapshot.data ?? 0;
                      bool isLowBalance = saldo <= minimalSaldo;
                      return Column(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 40),
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
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: isLowBalance
                                          ? Color(0xFFF54D42)
                                          : Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isBalanceVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isBalanceVisible = !isBalanceVisible;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (isLowBalance)
                            Container(
                              margin: EdgeInsets.only(top: 8),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.yellow.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.yellow,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Saldo di bawah batas minimal',
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '(${NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp',
                                      decimalDigits: 0,
                                    ).format(minimalSaldo)})',
                                    style: TextStyle(
                                      color: Colors.yellow.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 20),
              _buildIncomeExpenseToggle(),
            ],
          ),
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
      margin: EdgeInsets.symmetric(horizontal: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _handleSectionClick(true);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isIncomeSelected ? Color(0xFFEB8153) : Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(
                  child: Text(
                    'Inflow',
                    style: TextStyle(
                      color:
                          isIncomeSelected ? Colors.white : Color(0xFFB8B8B8),
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
              onTap: () {
                _handleSectionClick(false);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !isIncomeSelected ? Color(0xFFEB8153) : Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(
                  child: Text(
                    'Outflow',
                    style: TextStyle(
                      color:
                          !isIncomeSelected ? Colors.white : Color(0xFFB8B8B8),
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
    );
  }

  Widget _buildThisMonthIncomeCard() {
    return Card(
      elevation: 8.0,
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
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grafik Keuangan Pity Cash',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 25),
            Container(
              height: 250,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: max(saldoKeseluruhan, minSaldo) * 1.1,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                              tooltipRoundedRadius: 8,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                String amount = NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp',
                                  decimalDigits: 0,
                                ).format(rod.toY);
                                return BarTooltipItem(
                                  amount,
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                  IconData icon = value == 0
                                      ? Icons.trending_up
                                      : Icons.trending_down;
                                  Color color = value == 0
                                      ? Color(0xFF4CAF50)
                                      : Color(0xFFE57373);
                                  String text =
                                      value == 0 ? 'Pemasukan' : 'Pengeluaran';
                                  return Column(
                                    children: [
                                      Icon(icon, color: color, size: 18),
                                      SizedBox(height: 2),
                                      Text(
                                        text,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                reservedSize: 40,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    NumberFormat.compactCurrency(
                                      locale: 'id_ID',
                                      symbol: '',
                                      decimalDigits: 0,
                                    ).format(value),
                                    style: TextStyle(
                                      color: Color(0xFF7589A2),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                                reservedSize: 40,
                              ),
                            ),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.2),
                                strokeWidth: 0.5,
                                dashArray: [5, 5],
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: saldoKeseluruhan * _animation.value,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF81C784),
                                      Color(0xFF4CAF50)
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  width: 40,
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(8)),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: minSaldo * _animation.value,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFEF9A9A),
                                      Color(0xFFE57373)
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  width: 40,
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'Pemasukan & Pengeluaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7589A2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaldoCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final itemWidth = (cardWidth - 70) /
            2; // Mengurangi padding, jarak antar item, dan pembatas

        return Card(
          elevation: 12.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade100],
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Keuangan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSaldoItem(
                        'Pemasukan Keseluruhan',
                        saldoKeseluruhan,
                        Colors.green,
                        Icons.trending_up,
                        itemWidth,
                      ),
                      Container(
                        height: 80,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      _buildSaldoItem(
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
          ),
        );
      },
    );
  }

  Widget _buildSaldoItem(
      String title, double amount, Color color, IconData icon, double width) {
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Icon(
                icon,
                color: color,
                size: 18,
              ),
            ],
          ),
          SizedBox(height: 8),
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: amount),
            duration: Duration(seconds: 1),
            builder: (context, value, child) {
              return Text(
                NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp',
                  decimalDigits: 0,
                ).format(value),
                style: TextStyle(
                  fontSize: 15,
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
        final itemWidth = (cardWidth - 70) /
            2; // Mengurangi padding, jarak antar item, dan pembatas

        return Card(
          elevation: 12.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade100],
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perbandingan Pemasukan dan Pengurangan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
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
                        height: 80,
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
          ),
        );
      },
    );
  }

  Widget _buildPerbandinganItem(
      String title, double amount, Color color, IconData icon, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
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
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          SizedBox(height: 6),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp',
              decimalDigits: 0,
            ).format(amount),
            style: TextStyle(
              fontSize: 13,
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
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
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
    if (isIncomeSelected) {
      recentTransactions = incomes.take(5).toList();
    } else {
      recentTransactions = expenses.take(5).toList();
    }

    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIncomeSelected
                  ? 'Pemasukan terbaru Anda'
                  : 'Pengeluaran terbaru Anda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEB8153),
              ),
            ),
            SizedBox(height: 12),
            ...recentTransactions.map((transaction) {
              IconData icon;
              String date;
              double amount;
              if (isIncomeSelected) {
                icon = Icons.attach_money;
                date = transaction.date;
                amount = double.parse(transaction.jumlah);
              } else {
                icon = Icons.money_off;
                date = transaction.tanggal.toString();
                amount = transaction.jumlah;
              }
              return _buildTransactionItem(
                transaction.name,
                date,
                amount,
                icon,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
      String title, String date, double amount, IconData icon) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFFEB8153).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Color(0xFFEB8153)),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(date),
      trailing: Text(
        NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp',
          decimalDigits: 0,
        ).format(amount),
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEB8153)),
      ),
    );
  }
}

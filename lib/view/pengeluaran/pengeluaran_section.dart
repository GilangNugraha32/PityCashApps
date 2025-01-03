import 'dart:async';
import 'dart:io';

import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/models/outcomes_model.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/view/home/home.dart';
import 'package:pity_cash/view/pemasukan/tambah_pemasukan.dart';
import 'package:pity_cash/view/pengeluaran/detail_pengeluaran.dart';
import 'package:pity_cash/view/pengeluaran/tambah_pengeluaran.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PengeluaranSection extends StatefulWidget {
  @override
  _PengeluaranSectionState createState() => _PengeluaranSectionState();
}

class _PengeluaranSectionState extends State<PengeluaranSection> {
  List<Pengeluaran> expenses = [];
  List<Pengeluaran> filteredExpenses = [];
  Map<int, List<Pengeluaran>> groupedFilteredExpenses = {};

  DateTimeRange? selectedDateRange;

  double saldo = 0.0;
  bool isLoading = true;
  bool isOutcomeSelected = true;
  String? token;
  String? name;
  bool isLoggedIn = false;
  TextEditingController _searchController = TextEditingController();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final ApiService _apiService = ApiService();

  bool isLoadingMore = false;
  int currentPage = 1;
  bool isBalanceVisible = true;

  Timer? _debouncer;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _getSaldo();
    _checkLoginStatus();
    _fetchExpenses(currentPage);
    _searchController.addListener(_filterExpenses);
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

  Future<void> _fetchExpenses(int page) async {
    if (isLoadingMore || _isRequesting) return;

    setState(() {
      _isRequesting = true;
      isLoadingMore = true;
    });

    try {
      final fetchedExpenses = await _apiService.fetchExpenses(
        page: page,
        dateRange: selectedDateRange,
      );

      if (!mounted) return;

      setState(() {
        if (page == 1) {
          expenses = fetchedExpenses;
        } else {
          expenses.addAll(fetchedExpenses);
        }
        _filterExpenses();
        currentPage++;
      });
    } catch (e) {
      print('Error saat mengambil pengeluaran: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
          _isRequesting = false;
        });
      }
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: selectedDateRange,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFFEB8153),
            accentColor: Color(0xFFEB8153),
            colorScheme: ColorScheme.light(
              primary: Color(0xFFEB8153),
              onPrimary: Colors.white,
              onSurface: Color(0xFFEB8153),
            ),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
        isLoading = true;
      });
      await _fetchExpenses(1); // Reset ke page 1 saat filter tanggal berubah
    }
  }

  void _filterExpenses() {
    if (_debouncer?.isActive ?? false) _debouncer!.cancel();

    _debouncer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        String query = _searchController.text.toLowerCase();
        List<Pengeluaran> dateRangeFilteredExpenses = expenses;

        if (selectedDateRange != null) {
          dateRangeFilteredExpenses = expenses.where((pengeluaran) {
            return pengeluaran.tanggal != null &&
                pengeluaran.tanggal!.isAfter(
                    selectedDateRange!.start.subtract(Duration(days: 1))) &&
                pengeluaran.tanggal!
                    .isBefore(selectedDateRange!.end.add(Duration(days: 1)));
          }).toList();
        }

        filteredExpenses = query.isEmpty
            ? List.from(dateRangeFilteredExpenses)
            : dateRangeFilteredExpenses.where((pengeluaran) {
                return pengeluaran.name.toLowerCase().contains(query) ||
                    DateFormat('dd MMMM yyyy')
                        .format(pengeluaran.tanggal!)
                        .toLowerCase()
                        .contains(query);
              }).toList();

        // Update grouped expenses
        groupedFilteredExpenses = {};
        for (var pengeluaran in filteredExpenses) {
          int parentId = pengeluaran.idParent;
          if (!groupedFilteredExpenses.containsKey(parentId)) {
            groupedFilteredExpenses[parentId] = [];
          }
          groupedFilteredExpenses[parentId]!.add(pengeluaran);
        }
      });
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSectionClick(bool isOutcome) {
    setState(() {
      isOutcomeSelected = isOutcome;
      if (isOutcome) {
        currentPage = 1;
        expenses.clear();
        _fetchExpenses(currentPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<int, List<Pengeluaran>> groupedExpenses = {};
    for (var expense in expenses) {
      if (!groupedExpenses.containsKey(expense.idParent)) {
        groupedExpenses[expense.idParent] = [];
      }
      groupedExpenses[expense.idParent]!.add(expense);
    }
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                _buildOrangeBackgroundSection(),
                SizedBox(height: 8),
                _buildSearchForm(),
                SizedBox(height: 16),
                _buildCategoriesList(groupedFilteredExpenses),
                if (isLoading) Center(child: CircularProgressIndicator())
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrangeBackgroundSection() {
    final screenSize = MediaQuery.of(context).size;
    final double paddingScale = screenSize.width < 360 ? 0.8 : 1.0;
    final double iconScale = screenSize.width < 360 ? 0.8 : 1.0;
    final double fontScale = screenSize.width < 360 ? 0.9 : 1.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(bottom: 16.0 * paddingScale),
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
                Icons.trending_down_rounded,
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
                  SizedBox(height: 16 * paddingScale),
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
                            Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 16 * iconScale,
                            ),
                            SizedBox(width: 6 * paddingScale),
                            Text(
                              'Outflow',
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
                    ],
                  ),
                  SizedBox(height: 8 * paddingScale),
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
                                SizedBox(width: 30 * paddingScale),
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
                                          ? Color(0xFFFFF5F5)
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
                                margin: EdgeInsets.only(top: 10 * paddingScale),
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
                  SizedBox(height: 8 * paddingScale),
                  _buildToggleButton(),
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

  Widget _buildToggleButton() {
    final screenSize = MediaQuery.of(context).size;
    final double iconScale = screenSize.width < 360 ? 0.8 : 1.0;
    final double fontScale = screenSize.width < 360 ? 0.9 : 1.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleOption(
              'Inflow', !isOutcomeSelected, Icons.arrow_downward),
          _buildToggleOption('Outflow', isOutcomeSelected, Icons.arrow_upward),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected, IconData icon) {
    final screenSize = MediaQuery.of(context).size;
    final double iconScale = screenSize.width < 360 ? 0.8 : 1.0;
    final double fontScale = screenSize.width < 360 ? 0.9 : 1.0;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          int initialIndex = text == 'Outflow' ? 3 : 2;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(initialIndex: initialIndex),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFEB8153) : Colors.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Color(0xFFB8B8B8),
                size: 14 * iconScale,
              ),
              SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFFB8B8B8),
                  fontSize: 12 * fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari...',
            hintStyle: TextStyle(fontSize: 12),
            prefixIcon: Icon(Icons.search, size: 18),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
          ),
          onChanged: (value) {
            _filterExpenses();
          },
        ),
      ),
    );
  }

  Widget _buildExpensesList(
      Map<int, List<Pengeluaran>> groupedFilteredExpenses) {
    return RefreshIndicator(
      onRefresh: () async {
        await _refreshExpenses();
      },
      child: LazyLoadScrollView(
        onEndOfPage: () {
          if (!isLoading &&
              !isLoadingMore &&
              groupedFilteredExpenses.isNotEmpty) {
            _fetchExpenses(currentPage);
          }
        },
        child: Stack(
          children: [
            ListView.builder(
              padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom: 100,
              ),
              physics: groupedFilteredExpenses.isEmpty
                  ? NeverScrollableScrollPhysics()
                  : AlwaysScrollableScrollPhysics(),
              itemCount:
                  groupedFilteredExpenses.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == groupedFilteredExpenses.length) {
                  return Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFEB8153)),
                      ),
                    ),
                  );
                }

                int parentId = groupedFilteredExpenses.keys.elementAt(index);
                List<Pengeluaran> groupItems =
                    groupedFilteredExpenses[parentId]!;

                // Filter berdasarkan dateRange jika ada
                if (selectedDateRange != null) {
                  groupItems = groupItems
                      .where((expense) =>
                          expense.tanggal != null &&
                          (expense.tanggal!.isAfter(selectedDateRange!.start) ||
                              expense.tanggal!.isAtSameMomentAs(
                                  selectedDateRange!.start)) &&
                          (expense.tanggal!.isBefore(selectedDateRange!.end) ||
                              expense.tanggal!
                                  .isAtSameMomentAs(selectedDateRange!.end)))
                      .toList();
                } else {
                  // Jika tidak ada dateRange, filter untuk bulan dan tahun saat ini
                  final now = DateTime.now();
                  final firstDayOfMonth = DateTime(now.year, now.month, 1);
                  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

                  groupItems = groupItems
                      .where((expense) =>
                          expense.tanggal != null &&
                          expense.tanggal!.isAfter(
                              firstDayOfMonth.subtract(Duration(days: 1))) &&
                          expense.tanggal!
                              .isBefore(lastDayOfMonth.add(Duration(days: 1))))
                      .toList();
                }

                if (groupItems.isEmpty) {
                  return Container(); // Skip jika tidak ada data
                }

                double totalJumlah =
                    groupItems.fold(0, (sum, item) => sum + item.jumlah);

                return _buildExpenseGroup(groupItems, totalJumlah);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(
      Map<int, List<Pengeluaran>> groupedFilteredExpenses) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDateRangeAndActionButtons(),
            SizedBox(height: 6),
            Expanded(
              child: _buildExpensesList(groupedFilteredExpenses),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeAndActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildDateRangeSelector(),
        ),
        SizedBox(width: 4),
        FutureBuilder<Map<String, dynamic>?>(
          future: SharedPreferencesService().getRoles(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              bool isReader = snapshot.data!['roles'][0]['name'] == 'Reader';
              if (isReader) {
                return Container();
              }
            }
            return _buildActionButtons();
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return GestureDetector(
      onTap: () => _selectDateRange(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFFEB8153).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: Color(0xFFEB8153).withOpacity(0.2), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range,
              color: Color(0xFFEB8153),
              size: 12,
            ),
            SizedBox(width: 3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedDateRange == null
                        ? 'Pilih Tanggal'
                        : '${selectedDateRange!.start.day} ${_getMonthName(selectedDateRange!.start.month)} ${selectedDateRange!.start.year} - ${selectedDateRange!.end.day} ${_getMonthName(selectedDateRange!.end.month)} ${selectedDateRange!.end.year}',
                    style: TextStyle(
                      color: Color(0xFFEB8153),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1),
                  Text(
                    selectedDateRange == null
                        ? 'Data bulan ${DateFormat.MMMM().format(now)} ${now.year}'
                        : 'Rentang tanggal yang dipilih',
                    style: TextStyle(
                      color: Color(0xFFFF9D6C),
                      fontSize: 8,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFEB8153),
              size: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildCircularButton(
          color: Color(0xFF51A6F5),
          icon: Icons.print_outlined,
          onPressed: () {
            _showPrintDialog(context);
          },
        ),
        SizedBox(width: 4),
        _buildCircularButton(
          color: Color(0xFF68CF29),
          icon: Icons.file_upload_outlined,
          onPressed: () {
            _showDragAndDropModal(context);
          },
        ),
      ],
    );
  }

  void _showPrintDialog(BuildContext context) {
    String? selectedFormat;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cetak Laporan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.6,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih format laporan:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedFormat,
                            hint: Text('Pilih format',
                                style: TextStyle(fontSize: 12)),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedFormat = newValue;
                              });
                            },
                            items: <String>['PDF', 'Excel']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    value,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              );
                            }).toList(),
                            icon: Icon(Icons.arrow_drop_down,
                                color: Color(0xFFEB8153), size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            ElevatedButton(
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.red[400],
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size(60, 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Cetak', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFEB8153),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size(60, 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () async {
                if (selectedFormat != null) {
                  try {
                    String filePath;
                    if (selectedFormat == 'PDF') {
                      filePath = await ApiService().exportPdfPengeluaran();
                    } else if (selectedFormat == 'Excel') {
                      filePath = await ApiService().exportExcelPengeluaran();
                    } else {
                      throw Exception('Format tidak valid');
                    }

                    final downloadsDir = await getExternalStorageDirectory();
                    if (downloadsDir != null) {
                      final fileName = filePath.split('/').last;
                      final newPath = '${downloadsDir.path}/Download/$fileName';
                      await File(filePath).copy(newPath);
                      await File(filePath).delete();

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'File berhasil diekspor ke: $newPath',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: EdgeInsets.all(10),
                        ),
                      );
                    } else {
                      throw Exception(
                          'Tidak dapat menemukan direktori Downloads');
                    }
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gagal mengekspor file: $e',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.all(10),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pilih format terlebih dahulu',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.all(10),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDragAndDropModal(BuildContext context) {
    String? selectedFilePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12.0),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Import Data Pengeluaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey, size: 20),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'File Excel yang diunggah',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: _buildDragAndDropZone(
                      context,
                      selectedFilePath,
                      (String? filePath) {
                        setState(() {
                          selectedFilePath = filePath;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 15),
                  TextButton(
                    onPressed: () async {
                      try {
                        String filePath =
                            await ApiService().downloadOutcomeTemplate();
                        Directory? downloadsDirectory =
                            await getExternalStorageDirectory();
                        if (downloadsDirectory != null) {
                          String fileName = 'template_pengeluaran.xlsx';
                          String savePath =
                              '${downloadsDirectory.path}/Download/$fileName';
                          await Directory('${downloadsDirectory.path}/Download')
                              .create(recursive: true);
                          await File(filePath).copy(savePath);
                          await File(filePath).delete();
                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Template berhasil diunduh: $savePath',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: EdgeInsets.all(10),
                              ),
                            );
                          }
                        } else {
                          throw Exception(
                              'Tidak dapat menemukan folder Download');
                        }
                      } catch (e) {
                        print('Error saat mengunduh template: $e');
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Gagal mengunduh template: $e',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: EdgeInsets.all(10),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      'Download Template Excel',
                      style: TextStyle(color: Color(0xFFEB8153), fontSize: 12),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: selectedFilePath != null
                        ? () async {
                            try {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              );

                              final importedData = await ApiService()
                                  .importPengeluaranFromExcel(
                                      selectedFilePath!);

                              Navigator.of(context).pop();
                              Navigator.of(context).pop();

                              if (importedData.isNotEmpty) {
                                _showImportSuccessDialog(context, importedData);
                                await _refreshExpenses();
                              }
                            } catch (e) {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();

                              String errorMessage = e.toString();
                              if (errorMessage.contains('Undefined variable')) {
                                errorMessage =
                                    'Format file Excel tidak sesuai dengan template. Silakan gunakan template yang disediakan.';
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal mengimpor data: $errorMessage',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: EdgeInsets.all(10),
                                ),
                              );
                            }
                          }
                        : null,
                    child: Text('Upload', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFEB8153),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: MediaQuery.of(context).size.width * 0.15,
                      ),
                      minimumSize: Size(double.infinity, 0),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showImportSuccessDialog(
      BuildContext context, List<Map<String, dynamic>> importedData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF5EE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFFEB8153),
                    size: 40,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Import Berhasil!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEB8153),
                  ),
                ),
                SizedBox(height: 16),
                _buildSingleDataCard(importedData[0]),
                SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '+Data pengeluaran lainnya',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Lihat Selengkapnya',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFEB8153),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleDataCard(Map<String, dynamic> data) {
    DateTime createdAt = DateTime.parse(data['created_at']);
    String formattedDate =
        '${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFEB8153).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFFF5EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.description_outlined,
              color: Color(0xFFEB8153),
              size: 18,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Color(0xFFFFF5EE),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              'Rp ${NumberFormat('#.###').format(data['jumlah'] ?? 0)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Color(0xFFEB8153),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllImportedData(
      BuildContext context, List<Map<String, dynamic>> importedData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: size.height * 0.7,
              maxWidth: size.width * 0.85,
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Semua Data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEB8153),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Divider(),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: importedData.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildSingleDataCard(importedData[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragAndDropZone(
    BuildContext context,
    String? selectedFilePath,
    Function(String?) onFileSelected,
  ) {
    return GestureDetector(
      onTap: () => _pickFile(context, onFileSelected),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFEB8153)),
          borderRadius: BorderRadius.circular(6.0),
          color: Colors.grey[200],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined,
                  size: 32, color: Color(0xFFEB8153)),
              SizedBox(height: 8),
              Text(
                selectedFilePath != null
                    ? 'File terpilih: ${selectedFilePath.split('/').last}'
                    : 'Tap to upload, xlsx or xls',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickFile(BuildContext context, Function(String?) onFileSelected) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      onFileSelected(file.path);
    }
  }

  Widget _buildCircularButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300),
      tween: Tween<double>(begin: 1, end: 0.95),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 0.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: CircleBorder(),
                splashColor: color.withOpacity(0.5),
                highlightColor: color.withOpacity(0.3),
                onTap: onPressed,
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshExpenses() async {
    setState(() {
      isLoading = true;
      currentPage = 1;
      groupedFilteredExpenses.clear();
    });
    await _fetchExpenses(currentPage);
  }

  Widget _buildExpenseGroup(List<Pengeluaran> groupItems, double totalJumlah) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: InkWell(
        onTap: () {
          if (groupItems.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPengeluaran(
                  pengeluaranList: groupItems,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpenseGroupHeader(groupItems),
              Divider(color: Colors.grey[300], thickness: 0.5, height: 12),
              _buildExpenseItems(groupItems),
              Divider(color: Colors.grey[300], thickness: 0.5, height: 12),
              _buildExpenseGroupTotal(totalJumlah),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return monthNames[month - 1];
  }

  Widget _buildExpenseGroupHeader(List<Pengeluaran> groupItems) {
    return Text(
      groupItems.isNotEmpty &&
              groupItems.first.parentPengeluaran != null &&
              groupItems.first.tanggal != null
          ? '${groupItems.first.tanggal!.day} ${_getMonthName(groupItems.first.tanggal!.month)} ${groupItems.first.tanggal!.year}'
          : 'Tidak ada tanggal',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildExpenseItems(List<Pengeluaran> groupItems) {
    return Column(
      children: groupItems
          .map((pengeluaran) => _buildExpenseItem(pengeluaran))
          .toList(),
    );
  }

  Widget _buildExpenseItem(Pengeluaran pengeluaran) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Color(0xFFFFF5EE),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.description_outlined,
                color: Color(0xFFEB8153), size: 14),
          ),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pengeluaran.name.isNotEmpty
                      ? pengeluaran.name
                      : 'Tidak ada nama',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF5EE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pengeluaran.category?.name ?? 'Tidak ada kategori',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFFEB8153),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp',
              decimalDigits: 0,
            ).format(pengeluaran.jumlah),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseGroupTotal(double totalJumlah) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Color(0xFFFFF5EE),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calculate_outlined,
                  color: Color(0xFFEB8153), size: 14),
            ),
            SizedBox(width: 6),
            Text(
              'Total: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp',
            decimalDigits: 0,
          ).format(totalJumlah),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

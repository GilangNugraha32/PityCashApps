import 'dart:io';

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
import 'package:pity_cash/view/pemasukan/edit_pemasukan.dart';
import 'package:pity_cash/view/pemasukan/tambah_pemasukan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PemasukanSection extends StatefulWidget {
  @override
  _PemasukanSectionState createState() => _PemasukanSectionState();
}

class _PemasukanSectionState extends State<PemasukanSection> {
  double saldo = 0.0;
  List<Pemasukan> incomes = [];
  List<Pemasukan> filteredIncomes = [];
  DateTimeRange? selectedDateRange;

  bool isIncomeSelected = true;
  String? token;
  String? name;
  bool isLoggedIn = false;
  TextEditingController _searchController = TextEditingController();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final ApiService _apiService = ApiService();

  bool isLoadingMore = false;
  int currentPage = 1;
  bool isLoading = true;
  bool isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _getSaldo();
    _checkLoginStatus();
    _fetchIncomes(currentPage);
    _searchController.addListener(_filterIncomes);
  }

  void _refreshIncomes() {
    setState(() {
      currentPage = 1;
      incomes.clear();
      _fetchIncomes(currentPage);
    });
  }

  void _showDetailDialog(Pemasukan pemasukan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4.0,
                  offset: const Offset(0.0, 2.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Pemasukan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 16),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  '${DateTime.parse(pemasukan.date).day} ${_getMonthName(DateTime.parse(pemasukan.date).month)} ${DateTime.parse(pemasukan.date).year}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Divider(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nama',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3A63),
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            pemasukan.name,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kategori',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3A63),
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(height: 1),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pemasukan.category!.name,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Deskripsi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A63),
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  pemasukan.description,
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jumlah',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A63),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Rp${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(double.tryParse(pemasukan.jumlah) ?? 0)}',
                      style: TextStyle(
                        color: Color(0xFFEB8153),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                FutureBuilder<Map<String, dynamic>?>(
                  future: SharedPreferencesService().getRoles(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      bool isReader =
                          snapshot.data!['roles'][0]['name'] == 'Reader';
                      if (isReader) return Container();
                    }
                    return Column(
                      children: [
                        Container(
                          height: 28, // Mengecilkan tinggi button
                          width: double.infinity,
                          child: OutlinedButton(
                            child: Text('Hapus',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 11)),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showDeleteConfirmationDialog(context, pemasukan);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 0), // Mengurangi padding vertikal
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          height: 28, // Mengecilkan tinggi button
                          width: double.infinity,
                          child: OutlinedButton(
                            child: Text('Edit',
                                style: TextStyle(
                                    color: Color(0xFFF7941E), fontSize: 11)),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _navigateToEditPage(pemasukan);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Color(0xFFF7941E)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 0), // Mengurangi padding vertikal
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToEditPage(Pemasukan pemasukan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPemasukan(pemasukan: pemasukan),
      ),
    ).then((_) => _refreshIncomes());
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, Pemasukan pemasukan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Konfirmasi Hapus',
            style: TextStyle(color: Colors.red),
          ),
          content: Text('Apakah Anda yakin ingin menghapus data ini?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.deleteIncome(pemasukan.idData);

                  // Hapus item dari list lokal
                  setState(() {
                    incomes
                        .removeWhere((item) => item.idData == pemasukan.idData);
                    filteredIncomes
                        .removeWhere((item) => item.idData == pemasukan.idData);
                  });

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Berhasil dihapus!',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.all(10),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // Refresh saldo setelah menghapus
                  _getSaldo();
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus data',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.all(10),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text('Hapus'),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        );
      },
    );
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

  Future<void> _fetchIncomes(int page) async {
    if (isLoadingMore) return;

    setState(() {
      if (page == 1) {
        isLoading = true;
      } else {
        isLoadingMore = true;
      }
    });

    try {
      final fetchedIncomes = await _apiService.fetchIncomes(page: page);

      setState(() {
        if (page == 1) {
          incomes = fetchedIncomes;
        } else {
          incomes.addAll(fetchedIncomes);
        }
        currentPage++;

        if (selectedDateRange != null) {
          _filterIncomesByDateRange();
        } else {
          _filterIncomes();
        }
      });
    } catch (e) {
      print('Error fetching incomes: $e');
      _showErrorSnackbar('Error fetching incomes. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
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
        _filterIncomesByDateRange();
      });
    }
  }

  void _filterIncomesByDateRange() {
    if (selectedDateRange != null) {
      filteredIncomes = incomes.where((pemasukan) {
        final pemasukanDate = DateTime.parse(pemasukan.date);
        return pemasukanDate.isAfter(
                selectedDateRange!.start.subtract(Duration(days: 1))) &&
            pemasukanDate
                .isBefore(selectedDateRange!.end.add(Duration(days: 1)));
      }).toList();
    } else {
      filteredIncomes = List.from(incomes);
    }
  }

  void _filterIncomes() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredIncomes = List.from(incomes);
      } else {
        filteredIncomes = incomes.where((pemasukan) {
          return pemasukan.name.toLowerCase().contains(query) ||
              pemasukan.date.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  void _handleSectionClick(bool isIncome) {
    setState(() {
      isIncomeSelected = isIncome;
      if (isIncome) {
        currentPage = 1;
        incomes.clear();
        _fetchIncomes(currentPage);
      } else {
        // Implement expense fetching if needed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeaderSection(),
          SizedBox(height: 10),
          _buildSearchForm(),
          SizedBox(height: 20),
          _buildIncomesList(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEB8153), Color(0xFFFF9D6C)],
        ),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(25.0),
          bottomLeft: Radius.circular(25.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12.0, 45.0, 12.0, 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            _buildHeaderTopRow(),
            SizedBox(height: 12),
            _buildSaldoSection(),
            SizedBox(height: 10),
            _buildToggleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Inflow',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Icon(
          Icons.notifications,
          color: Colors.white,
          size: 22,
        ),
      ],
    );
  }

  Widget _buildSaldoSection() {
    return Center(
      child: Column(
        children: [
          Text(
            'Saldo Pity Cash',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 4),
          FutureBuilder<double>(
            future: ApiService().fetchMinimalSaldo(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
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
                          SizedBox(width: 35),
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
                                fontSize: 28,
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
                              size: 22,
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
                        margin: EdgeInsets.only(top: 6),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.yellow,
                              size: 14,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Saldo di bawah batas minimal',
                              style: TextStyle(
                                color: Colors.yellow,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(width: 3),
                            Text(
                              '(${NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp',
                                decimalDigits: 0,
                              ).format(minimalSaldo)})',
                              style: TextStyle(
                                color: Colors.yellow.withOpacity(0.8),
                                fontSize: 11,
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
        ],
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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.all(5),
      child: Row(
        children: [
          _buildToggleOption('Inflow', isIncomeSelected),
          _buildToggleOption('Outflow', !isIncomeSelected),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected) {
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
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFEB8153) : Colors.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(0xFFB8B8B8),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Cari...',
            hintStyle: TextStyle(fontSize: 13),
            prefixIcon: Icon(Icons.search, size: 18),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
          onTap: () {
            Future.delayed(Duration(milliseconds: 300), () {
              Scrollable.ensureVisible(
                context,
                alignment: 0.0,
                duration: Duration(milliseconds: 300),
              );
            });
          },
          onChanged: (value) {
            _filterIncomes();
          },
        ),
      ),
    );
  }

  Widget _buildIncomesList() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildDateRangeAndActionButtons(),
            ),
            Expanded(
              child: Stack(
                children: [
                  LazyLoadScrollView(
                    onEndOfPage: () {
                      if (!isLoading && !isLoadingMore) {
                        _fetchIncomes(currentPage);
                      }
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: filteredIncomes.length,
                      itemBuilder: (context, index) {
                        return _buildIncomeListItem(filteredIncomes[index]);
                      },
                    ),
                  ),
                  if (isLoading || isLoadingMore)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(12.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFEB8153)),
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

  Widget _buildIncomeListItem(Pemasukan pemasukan) {
    final date = DateTime.parse(pemasukan.date);
    final formattedDate =
        '${date.day} ${_getMonthName(date.month)} ${date.year}';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showDetailDialog(pemasukan),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Divider(color: Colors.grey[300], height: 1),
              SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(0xFFEB8153).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.monetization_on_outlined,
                      color: Color(0xFFEB8153),
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pemasukan.name,
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pemasukan.category!.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    ' Rp${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(double.tryParse(pemasukan.jumlah) ?? 0)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeAndActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDateRange(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFEB8153).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Color(0xFFEB8153).withOpacity(0.2), width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    color: Color(0xFFEB8153),
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedDateRange == null
                              ? 'Pilih Tanggal'
                              : '${DateFormat.yMMMd().format(selectedDateRange!.start)} - ${DateFormat.yMMMd().format(selectedDateRange!.end)}',
                          style: TextStyle(
                            color: Color(0xFFEB8153),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          selectedDateRange == null
                              ? 'Pilih rentang tanggal sesuai kebutuhan Anda'
                              : 'Rentang tanggal yang dipilih',
                          style: TextStyle(
                            color: Color(0xFFFF9D6C),
                            fontSize: 9,
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
          ),
        ),
        SizedBox(width: 6),
        FutureBuilder<Map<String, dynamic>?>(
          future: SharedPreferencesService().getRoles(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              bool isReader = snapshot.data!['roles'][0]['name'] == 'Reader';
              if (isReader) {
                return Container();
              }
            }
            return Row(
              children: [
                _buildActionButton(Icons.print_outlined, Color(0xFF51A6F5), () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      String? selectedFormat;
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
                              icon: Icon(Icons.close,
                                  color: Colors.grey[400], size: 20),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                        content: StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter setState) {
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
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
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
                                              .map<DropdownMenuItem<String>>(
                                                  (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 6),
                                                child: Text(
                                                  value,
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          icon: Icon(Icons.arrow_drop_down,
                                              color: Color(0xFFEB8153),
                                              size: 20),
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
                              style:
                                  TextStyle(color: Colors.white, fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.red[400],
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
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
                            child:
                                Text('Cetak', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              primary: Color(0xFFEB8153),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
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
                                    filePath =
                                        await ApiService().exportIncomePDF();
                                  } else if (selectedFormat == 'Excel') {
                                    filePath =
                                        await ApiService().exportIncomeExcel();
                                  } else {
                                    throw Exception('Format tidak valid');
                                  }

                                  final downloadsDir =
                                      await getExternalStorageDirectory();
                                  if (downloadsDir != null) {
                                    final fileName = filePath.split('/').last;
                                    final newPath =
                                        '${downloadsDir.path}/Download/$fileName';
                                    await File(filePath).copy(newPath);
                                    await File(filePath).delete();

                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'File berhasil diekspor ke: $newPath',
                                            style: TextStyle(fontSize: 11)),
                                        behavior: SnackBarBehavior.floating,
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
                                      content: Text('Gagal mengekspor file: $e',
                                          style: TextStyle(fontSize: 11)),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Pilih format terlebih dahulu',
                                        style: TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                }),
                SizedBox(width: 4),
                _buildActionButton(
                    Icons.file_upload_outlined, Color(0xFF68CF29), () {
                  _showDragAndDropModal(context);
                }),
              ],
            );
          },
        ),
      ],
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
                        'Import Data Pemasukan',
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'File Excel yang diunggah',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
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
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        try {
                          String filePath =
                              await ApiService().downloadIncomeTemplate();
                          Directory? downloadsDirectory =
                              await getExternalStorageDirectory();
                          if (downloadsDirectory != null) {
                            String fileName = 'template_pemasukan.xlsx';
                            String savePath =
                                '${downloadsDirectory.path}/Download/$fileName';
                            await Directory(
                                    '${downloadsDirectory.path}/Download')
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
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: EdgeInsets.all(8),
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                margin: EdgeInsets.all(8),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        'Download Template Excel',
                        style:
                            TextStyle(color: Color(0xFFEB8153), fontSize: 12),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: selectedFilePath != null
                        ? () async {
                            try {
                              List<Map<String, dynamic>> importedData =
                                  await ApiService()
                                      .importIncomeFromExcel(selectedFilePath!);
                              Navigator.of(context).pop();
                              _showImportedDataDialog(context, importedData);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Data pemasukan berhasil diimpor',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: EdgeInsets.all(8),
                                ),
                              );
                              _refreshIncomes();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal mengimpor data pemasukan: $e',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: EdgeInsets.all(8),
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

  void _showImportedDataDialog(
      BuildContext context, List<Map<String, dynamic>> importedIncome) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Column(
            children: [
              Text(
                'Data Pemasukan Berhasil di Import',
                style: TextStyle(
                  color: Color(0xFFEB8153),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Divider(
                color: Color(0xFFEB8153),
                thickness: 1,
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: importedIncome.length,
              itemBuilder: (context, index) {
                final data = importedIncome[index];
                return Card(
                  elevation: 0,
                  margin: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Color(0xFFEB8153), width: 1),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFFFFF5EE),
                          radius: 20,
                          child: Text(
                            data['Nama'][0],
                            style: TextStyle(
                              color: Color(0xFFEB8153),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['Nama'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFFEB8153),
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Tanggal: ${data['Tanggal']}',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Jumlah: ${data['Jumlah']}',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Kode Kategori: ${data['Kode Kategori']}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text(
                'Tutup',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFEB8153),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateRangeIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFEB8153),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 3.0,
              spreadRadius: 0.5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          Icons.calendar_today,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, Color color, VoidCallback onPressed) {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

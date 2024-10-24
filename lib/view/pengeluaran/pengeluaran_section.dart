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
import 'package:pity_cash/view/pemasukan/detail_pemasukan.dart';
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
    if (isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      print(
          'Mengambil pengeluaran untuk halaman: $page dengan rentang tanggal: $selectedDateRange');

      final fetchedExpenses = await _apiService.fetchExpenses(
        page: page,
        dateRange: selectedDateRange,
      );

      print('Pengeluaran yang diambil: ${fetchedExpenses.toString()}');

      setState(() {
        if (page == 1) {
          expenses = fetchedExpenses;
        } else {
          expenses.addAll(fetchedExpenses);
        }

        _filterExpenses();
        currentPage++;
      });

      // Periksa apakah masih ada data yang bisa dimuat
      if (fetchedExpenses.isEmpty) {
        setState(() {
          isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error saat mengambil pengeluaran: $e');
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
      });
      _filterExpenses();
    }
  }

  void _filterExpenses() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      List<Pengeluaran> dateRangeFilteredExpenses = expenses;
      if (selectedDateRange != null) {
        dateRangeFilteredExpenses = expenses.where((pengeluaran) {
          return pengeluaran.tanggal != null &&
              (pengeluaran.tanggal!.isAfter(selectedDateRange!.start) ||
                  pengeluaran.tanggal!
                      .isAtSameMomentAs(selectedDateRange!.start)) &&
              (pengeluaran.tanggal!.isBefore(selectedDateRange!.end) ||
                  pengeluaran.tanggal!
                      .isAtSameMomentAs(selectedDateRange!.end));
        }).toList();
      }

      if (query.isEmpty) {
        filteredExpenses = List.from(dateRangeFilteredExpenses);
      } else {
        filteredExpenses = dateRangeFilteredExpenses.where((pengeluaran) {
          bool matchesName = pengeluaran.name.toLowerCase().contains(query);
          bool matchesDate = DateFormat('dd MMMM yyyy')
              .format(pengeluaran.tanggal!)
              .toLowerCase()
              .contains(query);

          return matchesName || matchesDate;
        }).toList();
      }

      groupedFilteredExpenses = {};
      for (var pengeluaran in filteredExpenses) {
        int parentId = pengeluaran.idParent;
        if (!groupedFilteredExpenses.containsKey(parentId)) {
          groupedFilteredExpenses[parentId] = [];
        }
        groupedFilteredExpenses[parentId]!.add(pengeluaran);
      }
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
      } else {
        // Implement income fetching if needed
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
      body: Stack(
        children: [
          Column(
            children: [
              _buildOrangeBackgroundSection(),
              SizedBox(height: 10),
              _buildSearchForm(),
              SizedBox(height: 20),
              _buildCategoriesList(groupedFilteredExpenses),
            ],
          ),
          if (isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahPengeluaran(),
            ),
          );
        },
        backgroundColor: Colors.orange,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildOrangeBackgroundSection() {
    return Container(
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
            _buildHeaderRow(),
            SizedBox(height: 30),
            _buildSaldoSection(),
            SizedBox(height: 12),
            _buildToggleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Outflow',
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
    );
  }

  Widget _buildSaldoSection() {
    return Center(
      child: Column(
        children: [
          Text(
            'Saldo Pity Cash',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 10),
          FutureBuilder<double>(
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
      margin: EdgeInsets.symmetric(horizontal: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(6),
      child: Row(
        children: [
          _buildToggleOption('Inflow', !isOutcomeSelected),
          _buildToggleOption('Outflow', isOutcomeSelected),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleSectionClick(text == 'Outflow'),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFEB8153) : Colors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(0xFFB8B8B8),
                fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari...',
            prefixIcon: Icon(Icons.search),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            _filterExpenses();
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesList(
      Map<int, List<Pengeluaran>> groupedFilteredExpenses) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDateRangeAndActionButtons(),
            SizedBox(height: 10),
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
        SizedBox(width: 8),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return GestureDetector(
      onTap: () => _selectDateRange(context),
      child: AbsorbPointer(
        child: TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: selectedDateRange == null
                ? 'Pilih Tanggal'
                : '${DateFormat.yMMMd().format(selectedDateRange!.start)} - ${DateFormat.yMMMd().format(selectedDateRange!.end)}',
            hintStyle: TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEB8153),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4.0,
                      spreadRadius: 1.0,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(24.0),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
          ),
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
        SizedBox(width: 8),
        _buildCircularButton(
          color: Color(0xFF68CF29),
          icon: Icons.arrow_circle_down_sharp,
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
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            'Cetak Laporan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFEB8153),
              fontSize: 22,
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih format laporan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                            hint: Text('Pilih format'),
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
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    value,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              );
                            }).toList(),
                            dropdownColor: Colors.white,
                            elevation: 8,
                            style: TextStyle(color: Colors.black, fontSize: 16),
                            icon: Icon(Icons.arrow_drop_down,
                                color: Color(0xFFEB8153)),
                            menuMaxHeight: 300,
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
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Cetak', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFEB8153),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                            content:
                                Text('File berhasil diekspor ke: $newPath')),
                      );
                    } else {
                      throw Exception(
                          'Tidak dapat menemukan direktori Downloads');
                    }
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal mengekspor file: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pilih format terlebih dahulu',
                          style: TextStyle(fontSize: 16)),
                      backgroundColor: Colors.red,
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
          top: Radius.circular(16.0),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'File Excel yang diunggah',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 10),
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
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
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
                                        'Template berhasil diunduh: $savePath')),
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
                                  content:
                                      Text('Gagal mengunduh template: $e')),
                            );
                          }
                        }
                      },
                      child: Text(
                        'Download Template Excel',
                        style: TextStyle(color: Color(0xFFEB8153)),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: selectedFilePath != null
                        ? () async {
                            try {
                              List<Map<String, dynamic>> importedData =
                                  await ApiService().importPengeluaranFromExcel(
                                      selectedFilePath!);
                              Navigator.of(context).pop();
                              _showImportedDataDialog(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Data pengeluaran berhasil diimpor')),
                              );
                              _refreshExpenses();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Gagal mengimpor data pemasukan: $e')),
                              );
                            }
                          }
                        : null,
                    child: Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFEB8153),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: MediaQuery.of(context).size.width * 0.2,
                      ),
                      minimumSize: Size(double.infinity, 0),
                    ),
                  ),
                  SizedBox(height: 10),
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
        height: 175,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFEB8153)),
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.grey[200],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined,
                  size: 40, color: Color(0xFFEB8153)),
              SizedBox(height: 10),
              Text(
                selectedFilePath != null
                    ? 'File terpilih: ${selectedFilePath.split('/').last}'
                    : 'Tap to upload, xlsx or xls',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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

  void _importFile(BuildContext context, String filePath) async {
    try {
      await ApiService().importIncomeFromExcel(filePath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data pemasukan berhasil diimpor')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengimpor data pemasukan: $e')),
      );
    }
  }

  Widget _buildCircularButton({
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300),
      tween: Tween<double>(begin: 1, end: 0.95),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
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
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
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
          if (!isLoading && !isLoadingMore) {
            _fetchExpenses(currentPage);
          }
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: groupedFilteredExpenses.length,
          itemBuilder: (context, groupIndex) {
            int parentId = groupedFilteredExpenses.keys.elementAt(groupIndex);
            List<Pengeluaran> groupItems = groupedFilteredExpenses[parentId]!;
            double totalJumlah =
                groupItems.fold(0, (sum, item) => sum + item.jumlah);

            return _buildExpenseGroup(groupItems, totalJumlah);
          },
        ),
      ),
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
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
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
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpenseGroupHeader(groupItems),
              Divider(color: Colors.grey[300], thickness: 0.5, height: 15),
              _buildExpenseItems(groupItems),
              Divider(color: Colors.grey[300], thickness: 0.5, height: 15),
              _buildExpenseGroupTotal(totalJumlah),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseGroupHeader(List<Pengeluaran> groupItems) {
    return Text(
      groupItems.isNotEmpty &&
              groupItems.first.parentPengeluaran != null &&
              groupItems.first.tanggal != null
          ? DateFormat('dd MMMM yyyy').format(groupItems.first.tanggal!)
          : 'Tidak ada tanggal',
      style: TextStyle(
        fontSize: 14,
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
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFFF5EE),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.description_outlined,
                color: Color(0xFFEB8153), size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pengeluaran.name.isNotEmpty
                      ? pengeluaran.name
                      : 'Tidak ada nama',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF5EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pengeluaran.category?.name ?? 'Tidak ada kategori',
                    style: TextStyle(
                      fontSize: 12,
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
              fontSize: 16,
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
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFFFF5EE),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calculate_outlined,
                  color: Color(0xFFEB8153), size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'Total: ',
              style: TextStyle(
                fontSize: 16,
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  void _showImportedDataDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF5EE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Color(0xFFEB8153),
                    size: 50,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Impor Berhasil!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEB8153),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Data pengeluaran telah berhasil diimpor ke dalam sistem.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 25),
                TextButton(
                  child: Text(
                    'Tutup',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFFEB8153),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
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

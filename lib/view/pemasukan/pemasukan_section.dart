import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/view/pemasukan/detail_pemasukan.dart';
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

  void _navigateToDetail(Pemasukan pemasukan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPemasukan(
          pemasukan: pemasukan,
          onDelete: _refreshIncomes,
        ),
      ),
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
      isLoading = true;
    });

    try {
      print('Fetching incomes for page: $page');
      final fetchedIncomes = await _apiService.fetchIncomes(page: page);
      print('Fetched incomes: ${fetchedIncomes.toString()}');

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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeaderSection(),
              SizedBox(height: 10),
              _buildSearchForm(),
              SizedBox(height: 20),
              _buildIncomesList(),
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
              builder: (context) => TambahPemasukan(),
            ),
          );
        },
        backgroundColor: Color(0xFFE51A6F5),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeaderSection() {
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
            _buildHeaderTopRow(),
            SizedBox(height: 30),
            _buildSaldoSection(),
            SizedBox(height: 12),
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
          'Incomes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
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
    return Column(
      children: [
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
              ? CircularProgressIndicator()
              : Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp',
                    decimalDigits: 0,
                  ).format(saldo),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
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
          _buildToggleOption('Income', isIncomeSelected),
          _buildToggleOption('Expense', !isIncomeSelected),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleSectionClick(text == 'Income'),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildDateRangeAndActionButtons(),
            ),
            Expanded(
              child: LazyLoadScrollView(
                onEndOfPage: () {
                  if (!isLoading && !isLoadingMore) {
                    _fetchIncomes(currentPage);
                  }
                },
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredIncomes.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredIncomes.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFEB8153)),
                          ),
                        ),
                      );
                    }
                    return _buildIncomeListItem(filteredIncomes[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeListItem(Pemasukan pemasukan) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _navigateToDetail(pemasukan),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd MMMM yyyy')
                    .format(DateTime.parse(pemasukan.date)),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Divider(color: Colors.grey[300], height: 1),
              SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFFEB8153).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.monetization_on_outlined,
                        color: Color(0xFFEB8153)),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pemasukan.name,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[
                                50], // Warna latar belakang hijau sangat muda
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pemasukan.category!.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors
                                  .green[400], // Warna teks hijau lebih terang
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+ Rp${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(double.tryParse(pemasukan.jumlah) ?? 0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEB8153),
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
                  prefixIcon: _buildDateRangeIcon(),
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
          ),
        ),
        SizedBox(width: 8),
        _buildActionButton(Icons.print_outlined, Color(0xFF51A6F5), () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              String? selectedFormat;
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
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Container(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 16),
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
                actions: <Widget>[
                  ElevatedButton(
                    child: Text(
                      'Batal',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (selectedFormat != null) {
                        try {
                          String filePath;
                          if (selectedFormat == 'PDF') {
                            filePath = await ApiService().exportIncomePDF();
                          } else if (selectedFormat == 'Excel') {
                            filePath = await ApiService().exportIncomeExcel();
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
                                      'File berhasil diekspor ke: $newPath')),
                            );
                          } else {
                            throw Exception(
                                'Tidak dapat menemukan direktori Downloads');
                          }
                        } catch (e) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Gagal mengekspor file: $e')),
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
        }),
        SizedBox(width: 8),
        _buildActionButton(Icons.arrow_circle_down_sharp, Color(0xFF68CF29),
            () {
          _showDragAndDropModal(context);
        }),
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
                        'Import Data Pemasukan',
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
                        ? () {
                            _importFile(context, selectedFilePath!);
                            Navigator.of(context).pop();
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
      _refreshIncomes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengimpor data pemasukan: $e')),
      );
    }
  }

  Widget _buildDateRangeIcon() {
    return Padding(
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
        child: Icon(
          Icons.calendar_today,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 50,
      height: 50,
      child: CircleAvatar(
        backgroundColor: color,
        child: IconButton(
          icon: Icon(icon),
          color: Colors.white,
          iconSize: 28,
          onPressed: onPressed,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

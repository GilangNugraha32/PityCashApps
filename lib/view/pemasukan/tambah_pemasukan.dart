import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/models/category_model.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/view/home/home.dart';

class TambahPemasukan extends StatefulWidget {
  @override
  _TambahPemasukanState createState() => _TambahPemasukanState();
}

class _TambahPemasukanState extends State<TambahPemasukan> {
  bool showPrefix = false;
  int _selectedIndex = 0;

  DateTime? selectedDate;
  List<Category> categories = [];
  Category? selectedCategory;

  // Instantiate the controllers
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
    jumlahController.addListener(() {
      setState(() {
        showPrefix = jumlahController.text.isNotEmpty;
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> fetchCategories() async {
    try {
      ApiService apiService = ApiService();
      List<Category> allCategories = await apiService.fetchCategories();
      categories = allCategories
          .where((category) => category.jenisKategori == 1)
          .toList();
      setState(() {});
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void submit() async {
    try {
      if (nameController.text.isEmpty) {
        _showSnackbar('Nama tidak boleh kosong', isError: true);
        return;
      }

      if (descriptionController.text.isEmpty) {
        _showSnackbar('Deskripsi tidak boleh kosong', isError: true);
        return;
      }

      if (selectedDate == null) {
        _showSnackbar('Tanggal tidak boleh kosong', isError: true);
        return;
      }

      String jumlahText = jumlahController.text
          .replaceAll('Rp', '')
          .replaceAll('.', '')
          .replaceAll(',', '');
      double? jumlah = double.tryParse(jumlahText);

      if (jumlah == null) {
        _showSnackbar('Jumlah harus berupa angka', isError: true);
        return;
      }

      if (selectedCategory == null) {
        _showSnackbar('Kategori tidak boleh kosong', isError: true);
        return;
      }

      ApiService apiService = ApiService();
      await apiService.createPemasukan(
        context,
        name: nameController.text,
        description: descriptionController.text,
        date: selectedDate?.toIso8601String() ?? '',
        jumlah: jumlah.toString(),
        jenisKategori: selectedCategory?.id ?? 0,
      );

      _showSnackbar('Pemasukan berhasil ditambahkan', isError: false);

      nameController.clear();
      descriptionController.clear();
      jumlahController.clear();
      setState(() {
        selectedDate = null;
        selectedCategory = null;
      });

      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.pop(context, true);
        // Refresh halaman PengeluaranSection dengan mempertahankan bottom navigation bar
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialIndex: 3),
          ),
        );
      });
    } catch (e) {
      print('Error: $e');
      _showSnackbar('Gagal menambahkan pemasukan', isError: true);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.25,
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFFEB8153),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFEB8153).withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -30,
                      bottom: -20,
                      child: Icon(
                        Icons.trending_up_rounded,
                        size: MediaQuery.of(context).size.width * 0.45,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      top: 20,
                      child: Icon(
                        Icons.attach_money_rounded,
                        size: MediaQuery.of(context).size.width * 0.25,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Tambah Pemasukan',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 3,
                                          color: Colors.black.withOpacity(0.2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    width: 50,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
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
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputFields(),
                          SizedBox(height: 20),
                          _buildActionButtons(),
                        ],
                      ),
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

  Widget _buildHeader() {
    return Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        // Nama Pemasukan
        _buildLabel('Nama Pemasukan'),
        SizedBox(height: 2),
        Container(
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: TextField(
            controller: nameController,
            style: TextStyle(fontSize: 11),
            decoration: InputDecoration(
              hintText: 'Masukkan nama pemasukan',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
              ),
              suffixIcon: Icon(
                Icons.description_outlined,
                color: Color(0xFFEB8153),
                size: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 15,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),

        // Deskripsi
        _buildLabel('Deskripsi'),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: TextField(
            controller: descriptionController,
            maxLines: 2,
            style: TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Masukkan deskripsi pemasukan',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
              prefixIcon: Icon(
                Icons.notes,
                color: Color(0xFFEB8153),
                size: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        SizedBox(height: 12),

        // Kategori
        _buildLabel('Kategori'),
        SizedBox(height: 4),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) => _buildCategoryModal(),
            );
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insert_chart_outlined_outlined,
                  color: Color(0xFFEB8153),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedCategory?.name ?? 'Pilih kategori',
                    style: TextStyle(
                      fontSize: 12,
                      color: selectedCategory != null
                          ? Colors.black
                          : Colors.grey[400],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFFEB8153),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),

        // Tanggal
        _buildLabel('Tanggal'),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _selectDate(context),
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                suffixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(
                    Icons.calendar_today,
                    color: Color(0xFFEB8153),
                    size: 14,
                  ),
                ),
                hintText: selectedDate == null
                    ? 'Pilih Tanggal'
                    : '${selectedDate!.day.toString().padLeft(2, '0')} ${_getMonthName(selectedDate!.month)} ${selectedDate!.year}',
                hintStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),

        // Jumlah
        _buildLabel('Jumlah'),
        SizedBox(height: 2),
        Container(
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: jumlahController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandSeparatorInputFormatter(),
                  ],
                  style: TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Icon(
                        Icons.money,
                        color: Color(0xFFEB8153),
                        size: 16,
                      ),
                    ),
                    suffixText: 'IDR',
                    suffixStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                    hintText: 'Masukkan jumlah',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      String currentText = jumlahController.text
                          .replaceAll(RegExp(r'[^0-9]'), '');
                      int currentValue = int.tryParse(currentText) ?? 0;
                      int newValue = currentValue + 1;
                      String formattedValue = NumberFormat('#,###')
                          .format(newValue)
                          .replaceAll(',', '.');
                      jumlahController.text = formattedValue;
                    },
                    child: Icon(Icons.arrow_drop_up,
                        color: Color(0xFFEB8153), size: 14),
                  ),
                  InkWell(
                    onTap: () {
                      String currentText = jumlahController.text
                          .replaceAll(RegExp(r'[^0-9]'), '');
                      int currentValue = int.tryParse(currentText) ?? 0;
                      if (currentValue > 0) {
                        int newValue = currentValue - 1;
                        String formattedValue = NumberFormat('#,###')
                            .format(newValue)
                            .replaceAll(',', '.');
                        jumlahController.text = formattedValue;
                      }
                    },
                    child: Icon(Icons.arrow_drop_down,
                        color: Color(0xFFEB8153), size: 14),
                  ),
                ],
              ),
              SizedBox(width: 6),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryModal() {
    TextEditingController searchController = TextEditingController();
    TextEditingController categoryController = TextEditingController();
    categoryController.text = selectedCategory?.name ?? '';

    ValueNotifier<List<Category>> filteredCategories =
        ValueNotifier<List<Category>>(categories);

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
          height: MediaQuery.of(context).size.height *
              0.6, // Mengurangi tinggi modal
          padding: EdgeInsets.symmetric(
              horizontal: 16, vertical: 12), // Mengurangi padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32, // Mengurangi lebar handle bar
                  height: 3, // Mengurangi tinggi handle bar
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
              Text(
                'Pilih Kategori',
                style: TextStyle(
                  fontSize: 16, // Mengurangi ukuran font judul
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari kategori...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xFFEB8153),
                      size: 18,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    filteredCategories.value = categories
                        .where((category) => category.name
                            .toLowerCase()
                            .contains(value.toLowerCase()))
                        .toList();
                  },
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Kategori Pemasukan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Expanded(
                child: ValueListenableBuilder<List<Category>>(
                  valueListenable: filteredCategories,
                  builder: (context, categories, child) {
                    if (categories.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 36,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Tidak ada kategori yang ditemukan',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return ListTile(
                          dense: true, // Membuat list tile lebih compact
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selectedCategory == category
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: Radio<Category>(
                            value: category,
                            groupValue: selectedCategory,
                            onChanged: (Category? value) {
                              setState(() {
                                selectedCategory = value;
                                categoryController.text = value?.name ?? '';
                              });
                              this.setState(() {});
                              Navigator.pop(context);
                            },
                            activeColor: Color(0xFFEB8153),
                          ),
                          onTap: () {
                            setState(() {
                              selectedCategory = category;
                              categoryController.text = category.name;
                            });
                            this.setState(() {});
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildJumlahTextField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[200],
      ),
      child: TextField(
        controller: jumlahController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          ThousandSeparatorInputFormatter(),
        ],
        style: TextStyle(fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEB8153),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3.0,
                    spreadRadius: 0.5,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Icon(
                  Icons.money,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          hintText: 'Masukkan jumlah dalam bentuk Rp',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
          prefixText: showPrefix ? 'Rp' : null,
          prefixStyle: TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 12,
          ),
        ),
        onChanged: (value) {},
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

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () {
        _selectDate(context);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey[200],
        ),
        child: TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: selectedDate == null
                ? 'Pilih Tanggal'
                : '${selectedDate!.day.toString().padLeft(2, '0')} ${_getMonthName(selectedDate!.month)} ${selectedDate!.year}',
            hintStyle: TextStyle(
              color: Colors.black87,
              fontSize: 13,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: Container(
                height: 36,
                width: 36,
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
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFEB8153),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                primary: Color(0xFFEB8153),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            dialogBackgroundColor: Colors.white,
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          child: Container(
            child: child,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            primary: Color(0xFFDA0000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size(60, 28),
          ),
          child: Text('Batal', style: TextStyle(fontSize: 11)),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            submit();
          },
          style: ElevatedButton.styleFrom(
            primary: Color(0xFFE85C0D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size(60, 28),
          ),
          child: Text('Simpan', style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Bersihkan listener saat widget dihancurkan
    jumlahController.dispose();
    super.dispose();
  }
}

class ThousandSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      // Return Rp0 when there's no input
      return TextEditingValue(
        text: 'Rp0',
        selection: TextSelection.collapsed(offset: 3),
      );
    }

    // Format the text with thousand separators and Rp prefix
    String formattedText =
        'Rp' + NumberFormat('#,##0', 'id_ID').format(int.parse(newText));

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

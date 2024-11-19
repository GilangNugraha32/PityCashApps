import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/models/category_model.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/view/pemasukan/tambah_pemasukan.dart';

class EditPemasukan extends StatefulWidget {
  final Pemasukan pemasukan;

  EditPemasukan({required this.pemasukan});

  @override
  _EditPemasukanState createState() => _EditPemasukanState();
}

class _EditPemasukanState extends State<EditPemasukan> {
  int _selectedIndex = 0;

  DateTime? selectedDate;
  List<Category> categories = [];
  Category? selectedCategory;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();

  String formatCurrency(double amount) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatCurrency.format(amount);
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
    nameController.text = widget.pemasukan.name;
    descriptionController.text = widget.pemasukan.description;
    selectedDate = DateTime.parse(widget.pemasukan.date);
    jumlahController.text =
        formatCurrency(double.tryParse(widget.pemasukan.jumlah) ?? 0.0);
    selectedCategory = widget.pemasukan.category;

    // Add listener to jumlahController
    jumlahController.addListener(() {
      String text = jumlahController.text;
      if (!text.startsWith('Rp') && text.isNotEmpty) {
        jumlahController.value = jumlahController.value.copyWith(
          text: 'Rp$text',
          selection: TextSelection.collapsed(offset: text.length + 2),
        );
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    jumlahController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil kategori: ${e.toString()}')),
      );
    }
  }

  void submit() async {
    if (nameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        jumlahController.text.isEmpty ||
        selectedCategory == null ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Harap lengkapi semua field.',
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
      return;
    }

    String formattedAmount = jumlahController.text
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    double? jumlahValue = double.tryParse(formattedAmount);
    if (jumlahValue == null || jumlahValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jumlah harus berupa angka yang valid dan positif.',
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
      return;
    }

    try {
      ApiService apiService = ApiService();
      await apiService.updateIncomes(
        widget.pemasukan.idData,
        nameController.text,
        descriptionController.text,
        selectedDate?.toIso8601String() ?? '',
        jumlahValue.toString(),
        selectedCategory!.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pemasukan berhasil diubah',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );

      nameController.clear();
      descriptionController.clear();
      jumlahController.clear();
      setState(() {
        selectedDate = null;
        selectedCategory = null;
      });

      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.pop(context, true);
      });
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengubah pemasukan: ${e.toString()}',
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
                                    'Edit Pemasukan',
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
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
    categoryController.text = selectedCategory?.name ?? '';

    ValueNotifier<List<Category>> filteredCategories =
        ValueNotifier<List<Category>>([]);

    // Fungsi untuk mengurutkan kategori
    void sortCategories(String searchQuery) {
      List<Category> sorted = [...categories];

      // Filter berdasarkan pencarian jika ada
      if (searchQuery.isNotEmpty) {
        sorted = sorted
            .where((category) =>
                category.name.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }

      // Jika ada kategori yang dipilih, pindahkan ke atas
      if (selectedCategory != null) {
        sorted.removeWhere((c) => c.id == selectedCategory!.id);
        if (searchQuery.isEmpty ||
            selectedCategory!.name
                .toLowerCase()
                .contains(searchQuery.toLowerCase())) {
          sorted.insert(0, selectedCategory!);
        }
      }

      filteredCategories.value = sorted;
    }

    // Inisialisasi awal
    sortCategories('');

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
              Text(
                'Edit Kategori',
                style: TextStyle(
                  fontSize: 16,
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
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) {
                      sortCategories(searchController.text);
                    }
                  },
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
                      sortCategories(value);
                    },
                    onSubmitted: (value) {
                      FocusScope.of(context).unfocus();
                    },
                    textInputAction: TextInputAction.search,
                  ),
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
                        bool isSelected = selectedCategory?.id == category.id;

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Color(0xFFEB8153)
                                  : Colors.black87,
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            dialogBackgroundColor: Colors.white,
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
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
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return TextEditingValue(
          text: 'Rp0',
          selection: TextSelection.fromPosition(TextPosition(offset: 2)));
    }

    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return TextEditingValue(
          text: 'Rp0',
          selection: TextSelection.fromPosition(TextPosition(offset: 2)));
    }

    int value = int.parse(newText);
    String formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

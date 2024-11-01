import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/models/category_model.dart';
import 'package:pity_cash/service/share_preference.dart';

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
            decoration: BoxDecoration(
              color: Color(0xFFEB8153),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24.0),
                bottomRight: Radius.circular(24.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 24),
                  Text(
                    'Edit Pemasukan',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputFields(),
                        SizedBox(height: 30),
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
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Icon(
            Icons.notifications,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        // Nama Pemasukan
        _buildLabel('Nama Pemasukan'),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: TextField(
            controller: nameController,
            style: TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Masukkan nama pemasukan',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              suffixIcon: Icon(
                Icons.description_outlined,
                color: Color(0xFFEB8153),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        SizedBox(height: 20),

        // Deskripsi
        _buildLabel('Deskripsi'),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: TextField(
            controller: descriptionController,
            maxLines: 3,
            style: TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Masukkan deskripsi pemasukan',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.notes,
                color: Color(0xFFEB8153),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        SizedBox(height: 20),

        // Kategori
        _buildLabel('Kategori'),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: TypeAheadFormField<Category>(
            textFieldConfiguration: TextFieldConfiguration(
              controller:
                  TextEditingController(text: selectedCategory?.name ?? ''),
              style: TextStyle(fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: Container(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(0xFFEB8153).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.insert_chart_outlined_outlined,
                    color: Color(0xFFEB8153),
                    size: 20,
                  ),
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFFEB8153),
                ),
                hintText: 'Cari atau pilih kategori',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            suggestionsCallback: (pattern) async {
              return categories.where((category) =>
                  category.name.toLowerCase().contains(pattern.toLowerCase()));
            },
            itemBuilder: (context, Category suggestion) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    suggestion.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selectedCategory == suggestion
                          ? FontWeight.normal
                          : FontWeight.normal,
                    ),
                  ),
                  leading: Radio<Category>(
                    value: suggestion,
                    groupValue: selectedCategory,
                    onChanged: (Category? value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                    activeColor: Color(0xFFEB8153),
                  ),
                  tileColor: selectedCategory == suggestion
                      ? Color(0xFFEB8153).withOpacity(0.1)
                      : null,
                ),
              );
            },
            onSuggestionSelected: (Category suggestion) {
              setState(() {
                selectedCategory = suggestion;
              });
            },
            noItemsFoundBuilder: (context) => Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tidak ada kategori ditemukan',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 20),

        // Tanggal
        _buildLabel('Tanggal'),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Icon(
                    Icons.calendar_today,
                    color: Color(0xFFEB8153),
                    size: 20,
                  ),
                ),
                hintText: selectedDate == null
                    ? 'Pilih Tanggal'
                    : '${selectedDate!.day.toString().padLeft(2, '0')} ${_getMonthName(selectedDate!.month)} ${selectedDate!.year}',
                hintStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),

        // Jumlah
        _buildLabel('Jumlah'),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
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
                    CurrencyInputFormatter(),
                  ],
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Icon(
                        Icons.money,
                        color: Color(0xFFEB8153),
                        size: 20,
                      ),
                    ),
                    suffixText: 'IDR',
                    suffixStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    hintText: 'Masukkan jumlah',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
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
                    child: Icon(Icons.arrow_drop_up, color: Color(0xFFEB8153)),
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
                    child:
                        Icon(Icons.arrow_drop_down, color: Color(0xFFEB8153)),
                  ),
                ],
              ),
              SizedBox(width: 8),
            ],
          ),
        ),
      ],
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
        fontSize: 14,
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
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
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
            primary: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Batal',
            style: TextStyle(color: Colors.white),
          ),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            try {
              submit();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            primary: Color(0xFFE85C0D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Simpan',
            style: TextStyle(color: Colors.white),
          ),
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

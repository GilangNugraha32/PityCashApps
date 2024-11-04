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
            decoration: BoxDecoration(
              color: Color(0xFFEB8153),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(24.0),
                bottomLeft: Radius.circular(24.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 24),
                  Text(
                    'Tambah Pemasukan',
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
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
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
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => _buildCategoryModal(),
            );
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                Icon(
                  Icons.insert_chart_outlined_outlined,
                  color: Color(0xFFEB8153),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedCategory?.name ?? 'Pilih kategori',
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedCategory != null
                          ? Colors.black
                          : Colors.grey[400],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFFEB8153),
                ),
              ],
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
                    ThousandSeparatorInputFormatter(),
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

  Widget _buildCategoryModal() {
    TextEditingController searchController = TextEditingController();
    TextEditingController categoryController = TextEditingController();
    categoryController.text = selectedCategory?.name ?? '';

    ValueNotifier<List<Category>> filteredCategories =
        ValueNotifier<List<Category>>(categories);

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                'Pilih Kategori',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 25),

              // Search Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari kategori...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xFFEB8153),
                      size: 22,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              SizedBox(height: 24),

              // Category Header
              Row(
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Kategori Pemasukan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Category List
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
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada kategori yang ditemukan',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
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
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 15,
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

  Widget _buildJumlahTextField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200], // Same as buildTextField
      ),
      child: TextField(
        controller: jumlahController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, // Allow only digits
          ThousandSeparatorInputFormatter(), // Add your custom formatter
        ],
        style: TextStyle(fontSize: 14), // Text size same as buildTextField
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              height: 48, // Adjust height according to other TextFields
              width: 48, // Adjust width to be circular
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEB8153), // Circle background color
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26, // Shadow color
                    blurRadius: 4.0, // Blur radius
                    spreadRadius: 1.0, // Shadow spread radius
                    offset: Offset(0, 2), // Shadow position
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.money,
                  color: Colors.white, // Change icon color to white
                ),
              ),
            ),
          ),
          hintText: 'Masukkan jumlah dalam bentuk Rp', // Hint text
          hintStyle: TextStyle(color: Colors.grey),
          prefixText:
              showPrefix ? 'Rp' : null, // Show 'Rp' only if there's input
          prefixStyle: TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 15, // Vertical space same as buildTextField
          ),
        ),
        onChanged: (value) {
          // Update state if needed, but normally not required here
        },
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
          borderRadius: BorderRadius.circular(20),
          color: Colors
              .grey[200], // Menggunakan warna yang sama dengan buildTextField
        ),
        child: TextField(
          enabled: false, // Disable text editing, only allow date picker
          decoration: InputDecoration(
            hintText: selectedDate == null
                ? 'Pilih Tanggal'
                : '${selectedDate!.day.toString().padLeft(2, '0')} ${_getMonthName(selectedDate!.month)} ${selectedDate!.year}',
            hintStyle: TextStyle(
              color: Colors.black87,
              fontSize: 15, // Ukuran text diperkecil
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                  right: 8.0), // Jarak antara ikon dan teks
              child: Container(
                height: 48, // Sesuaikan tinggi sesuai dengan TextField
                width: 48, // Sesuaikan lebar agar berbentuk lingkaran
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEB8153), // Latar belakang lingkaran
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26, // Warna bayangan
                      blurRadius: 4.0, // Blur radius
                      spreadRadius: 1.0, // Radius penyebaran bayangan
                      offset: Offset(0, 5), // Posisi bayangan
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
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              vertical: 15, // Jarak vertikal dalam TextField
            ),
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
              primary: Color(0xFFEB8153), // Header background
              onPrimary: Colors.white, // Header text
              onSurface: Colors.black87, // Calendar text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                primary: Color(0xFFEB8153), // Button text color
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12), // Radius untuk button
                ),
              ),
            ),
            dialogBackgroundColor: Colors.white,
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Radius untuk dialog
              ),
            ),
          ),
          child: Container(
            child: child,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
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
            Navigator.pop(context); // Add action for Cancel button
          },
          style: ElevatedButton.styleFrom(
            primary: Color(0xFFDA0000), // Color for "Cancel"
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Set radius to 8
            ),
          ),
          child: Text('Batal'),
        ),
        SizedBox(width: 16), // Add spacing between buttons

        ElevatedButton(
          onPressed: () {
            submit();
          },
          style: ElevatedButton.styleFrom(
            primary: Color(0xFFE85C0D), // Updated color for "Simpan"
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Set radius to 8
            ),
          ),
          child: Text('Simpan'),
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

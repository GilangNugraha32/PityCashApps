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

  // Instantiate the controllers
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();

  String formatCurrency(double amount) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'id_ID');
    return formatCurrency
        .format(amount)
        .replaceAll('Rp', 'Rp.'); // Ensure 'Rp.' is shown correctly
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
    nameController.text = widget.pemasukan.name;
    descriptionController.text = widget.pemasukan.description;

    // Set the selected date to the date of the pemasukan
    selectedDate =
        DateTime.parse(widget.pemasukan.date); // Set to pemasukan date
    jumlahController.text =
        formatCurrency(double.tryParse(widget.pemasukan.jumlah) ?? 0.0);
    selectedCategory = widget.pemasukan.category;
  }

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

      // Filter categories to display only those with jenis_kategori 1 (pemasukan)
      categories = allCategories
          .where((category) => category.jenisKategori == 1)
          .toList();

      setState(() {}); // Update UI with fetched categories
    } catch (e) {
      print('Error fetching categories: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil kategori: ${e.toString()}')),
      );
    }
  }

  void submit() async {
    // Validate input fields
    if (nameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        jumlahController.text.isEmpty ||
        selectedCategory == null ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap lengkapi semua field.')),
      );
      return;
    }

    // Prepare jumlahValue for parsing and storage
    String formattedAmount = jumlahController.text
        .replaceAll('Rp. ', '') // Remove 'Rp. ' prefix
        .replaceAll('Rp', '') // Remove 'Rp' prefix if it exists without dot
        .replaceAll('.', '') // Remove dots (for thousands)
        .replaceAll(',', '.'); // Replace comma with a dot for decimal point

    double? jumlahValue =
        double.tryParse(formattedAmount); // Try parsing the formatted amount
    if (jumlahValue == null || jumlahValue <= 0) {
      // Ensure it's a valid number and greater than zero
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Jumlah harus berupa angka yang valid dan positif.')),
      );
      return;
    }

    try {
      ApiService apiService = ApiService();

      // Call the updateIncomes method with the correct parameters
      await apiService.updateIncomes(
        widget.pemasukan.idData, // Pass the ID of the income entry
        nameController.text, // Name
        descriptionController.text, // Description
        selectedDate?.toIso8601String() ?? '', // Date
        jumlahValue.toString(), // Convert jumlahValue to String
        selectedCategory!.id, // Use category ID directly
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pemasukan berhasil diubah')),
      );

      // Clear fields after submission
      nameController.clear();
      descriptionController.clear();
      jumlahController.clear();
      setState(() {
        selectedDate = null;
        selectedCategory = null; // Resetting selected category
      });

      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.pop(context); // Go back after a delay
      });
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah pemasukan: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFFEB8153),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(90.0),
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
          // Main Content
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(90.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: SingleChildScrollView(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    color: Colors.grey[350],
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
        SizedBox(height: 10),
        _buildLabel('Nama Pemasukan'),
        SizedBox(height: 10),
        _buildTextField(
          icon: Icons.mode_edit_outlined,
          controller: nameController,
          hintText: 'Masukkan nama pemasukan',
        ),
        SizedBox(height: 15),
        _buildLabel('Deskripsi'),
        SizedBox(height: 10),
        _buildTextField(
          icon: Icons.format_align_left,
          controller: descriptionController,
          hintText: 'Masukkan Deskripsi',
        ),
        SizedBox(height: 15),
        _buildLabel('Tanggal'),
        SizedBox(height: 10),
        _buildDateField(), // Use the updated date field
        SizedBox(height: 15),
        _buildLabel('Jumlah:'),
        SizedBox(height: 10),
        _buildJumlahTextField(),
        SizedBox(height: 15),
        _buildLabel('Kategori:'),
        SizedBox(height: 10),
        _buildCategoryDropdown(),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 14), // Ukuran teks di dalam TextField
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding:
                const EdgeInsets.only(right: 8.0), // Jarak antara ikon dan teks
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
                  icon,
                  color: Colors.white, // Ubah warna ikon menjadi putih
                ),
              ),
            ),
          ),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 15, // Jarak vertikal dalam TextField
          ),
        ),
      ),
    );
  }

  Widget _buildJumlahTextField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200], // Sama dengan buildTextField
      ),
      child: TextField(
        controller: jumlahController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          ThousandSeparatorInputFormatter()
        ], // Tambahkan formatter di sini
        style: TextStyle(
            fontSize: 14), // Ukuran teks yang sama dengan buildTextField
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              height: 48, // Sesuaikan tinggi sesuai dengan TextField lainnya
              width: 48, // Sesuaikan lebar agar berbentuk lingkaran
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEB8153), // Latar belakang lingkaran
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26, // Warna bayangan
                    blurRadius: 4.0, // Blur radius
                    spreadRadius: 1.0, // Radius penyebaran bayangan
                    offset: Offset(0, 2), // Posisi bayangan
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.money,
                  color: Colors.white, // Ubah warna ikon menjadi putih
                ),
              ),
            ),
          ),
          hintText: 'Masukkan jumlah dalam bentuk Rp', // Hint text yang diminta
          hintStyle: TextStyle(color: Colors.grey),
          // Tampilkan 'Rp.' hanya jika ada input
          prefixStyle: TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 15, // Jarak vertikal yang sama dengan buildTextField
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200], // Warna latar belakang yang konsisten
      ),
      child: TypeAheadFormField<Category>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: TextEditingController(text: selectedCategory?.name ?? ''),
          decoration: InputDecoration(
            hintText: 'Pilih kategori',
            hintStyle: TextStyle(color: Colors.grey), // Gaya hint text
            border: InputBorder.none, // Tidak ada border
            prefixIcon: Padding(
              padding: const EdgeInsets.only(right: 8.0),
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
                    Icons.category,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down, // Ikon panah ke bawah
              color: Colors.grey,
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 12, // Jarak isi
            ),
          ),
        ),
        suggestionsCallback: (pattern) async {
          // Mengembalikan daftar kategori yang sesuai dengan input pengguna
          return categories.where((category) =>
              category.name.toLowerCase().contains(pattern.toLowerCase()));
        },
        itemBuilder: (context, Category suggestion) {
          return Column(
            children: [
              ListTile(
                title: Text(
                  suggestion.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // Buat teks tebal
                    fontSize: 14, // Ukuran teks lebih kecil
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.grey), // Divider antar item
            ],
          );
        },
        onSuggestionSelected: (Category suggestion) {
          setState(() {
            selectedCategory = suggestion; // Menetapkan kategori yang dipilih
          });
        },
        noItemsFoundBuilder: (context) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Tidak ada kategori ditemukan.',
            style: TextStyle(color: Colors.red),
          ),
        ),
        suggestionsBoxDecoration: SuggestionsBoxDecoration(
          color: Colors.white, // Warna latar dropdown
          borderRadius: BorderRadius.circular(12), // Radius dropdown
          elevation: 4, // Shadow untuk dropdown
        ),
      ),
    );
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
                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
            hintStyle: TextStyle(color: Colors.black87),
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
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Action for Cancel button
          },
          style: ElevatedButton.styleFrom(
            primary: Colors.red, // Color for "Cancel"
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Set radius to 8
            ),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.white), // Set text color
          ),
        ),
        SizedBox(width: 16), // Add spacing between buttons

        ElevatedButton(
          onPressed: () {
            // Consider adding error handling for the submit action
            try {
              submit(); // Call the submit function
            } catch (e) {
              // Handle the error, e.g., show a SnackBar or dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            primary: Colors.orange, // Updated color for "Simpan"
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Set radius to 8
            ),
          ),
          child: Text(
            'Simpan',
            style: TextStyle(color: Colors.white), // Set text color
          ),
        ),
      ],
    );
  }
}

class ThousandSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Menghapus semua karakter non-digit
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return TextEditingValue();
    }

    // Menggunakan intl package untuk format dengan pemisah ribuan
    String formattedText =
        NumberFormat('#,##0', 'id_ID').format(int.parse(newText));

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

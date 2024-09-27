import 'dart:io'; // Necessary for File
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Import for file_picker package
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/models/category_model.dart';
import 'package:pity_cash/service/share_preference.dart';

class TambahPengeluaran extends StatefulWidget {
  @override
  _TambahPengeluaranState createState() => _TambahPengeluaranState();
}

class _TambahPengeluaranState extends State<TambahPengeluaran> {
  bool showPrefix = false;
  int _selectedIndex = 0;
  List<Widget> forms = [];

  // Instantiate the controllers
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController nominalController = TextEditingController();
  final TextEditingController jumlahSatuanController = TextEditingController();
  final TextEditingController dllController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();

  DateTime? selectedDate;
  List<Category> categories = [];
  Category? selectedCategory;
  FilePickerResult? selectedImage;

  @override
  void initState() {
    super.initState();
    forms.add(_buildPengeluaranForm(isLast: true));
    fetchCategories();
    nominalController.addListener(() {
      setState(() {
        // Tampilkan 'Rp.' hanya jika ada teks yang diinput
        showPrefix = nominalController.text.isNotEmpty;
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

      // Filter kategori untuk menampilkan hanya yang memiliki jenis_kategori 1 (pemasukan)
      categories = allCategories
          .where((category) => category.jenisKategori == 2)
          .toList();

      setState(() {});
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void submit() async {
    try {
      // Validasi input
      if (nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nama tidak boleh kosong')),
        );
        return; // Keluar jika nama kosong
      }

      if (descriptionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deskripsi tidak boleh kosong')),
        );
        return; // Keluar jika deskripsi kosong
      }

      if (selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tanggal tidak boleh kosong')),
        );
        return; // Keluar jika tanggal kosong
      }

      // Menghapus prefix "Rp. " dan pemisah ribuan (titik atau koma) sebelum parsing
      String jumlahText = nominalController.text
          .replaceAll('Rp. ', '')
          .replaceAll('.', '')
          .replaceAll(',', '');
      double? jumlah = double.tryParse(jumlahText); // Parsing menjadi double

      if (jumlah == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jumlah harus berupa angka')),
        );
        return; // Keluar jika jumlah tidak valid
      }

      if (selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kategori tidak boleh kosong')),
        );
        return; // Keluar jika kategori kosong
      }

      ApiService apiService = ApiService();
      await apiService.createPemasukan(
        context,
        name: nameController.text,
        description: descriptionController.text,
        date: selectedDate?.toIso8601String() ?? '',
        jumlah: jumlah.toString(), // Menggunakan nilai jumlah yang valid
        jenisKategori: selectedCategory?.id ?? 0,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pengeluaran berhasil ditambahkan')),
      );

      // Clear fields after submission
      nameController.clear();
      descriptionController.clear();
      nominalController.clear();
      setState(() {
        selectedDate = null;
        selectedCategory = null;
      });

      // Navigate back to the previous screen with a delay
      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.pop(context);
      });
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan pemasukan')),
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
                bottomLeft: Radius.circular(90.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 24),
                  Text(
                    'Tambah Pengeluaran',
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

          // Expanded for the scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(90.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Elemen Tanggal di luar Card tetapi di dalam Container Putih
                      SizedBox(height: 15),
                      _buildDateField(), // Field tanggal

                      // Menampilkan semua form yang ada
                      SizedBox(height: 20),
                      Column(children: forms),
                      SizedBox(height: 20), // Menambahkan jarak setelah form
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            // Tambahkan form baru dengan action button
            forms.add(_buildPengeluaranForm(isLast: true));

            // Log message to indicate a new form has been added
            print(
                'Form baru berhasil ditambahkan! Total form: ${forms.length}');

            // Display a snackbar to inform the user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Form baru berhasil ditambahkan!'),
                duration: Duration(seconds: 2),
              ),
            );
          });
        },
        backgroundColor: Color(0xFFEB8153), // Warna tombol
        child: Icon(Icons.add), // Ikon +
      ),
    );
  }

  Widget _buildPengeluaranForm({bool isLast = false}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      color: Colors.grey[350],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tambahkan setiap input field yang diinginkan di sini
            _buildInputFields(), // Ganti ini dengan field yang sebenarnya
            SizedBox(height: 20),
            if (isLast) // Action buttons only appear on the last form
              _buildActionButtons(),
          ],
        ),
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
        _buildLabel('Nama Pengeluaran'),
        SizedBox(height: 10),
        _buildTextField(
          icon: Icons.attach_money,
          controller: nameController,
          hintText: 'Masukkan nama pengeluaran',
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
        _buildLabel('Nominal'),
        SizedBox(height: 10),
        _buildNominalTextField(),
        SizedBox(height: 15),

        // Field Jumlah Satuan
        _buildLabel('Jumlah Satuan'),
        SizedBox(height: 10),
        _buildJumlahSatuanTextField(),
        SizedBox(height: 15),

        // Field Dll
        _buildLabel('Biaya Tambahan (DLL)'),
        SizedBox(height: 10),
        _buildDllTextField(),
        SizedBox(height: 15),

        // Field Jumlah (Auto-calculated)
        _buildLabel('Jumlah'),
        SizedBox(height: 10),
        _buildJumlahField(),
        SizedBox(height: 15),
        _buildLabel('Kategori:'),
        SizedBox(height: 10),
        _buildCategoryDropdown(),
        // Field for image input
        SizedBox(height: 15),
        _buildLabel('Pilih Gambar:'),
        SizedBox(height: 10),
        _buildImagePicker(),
      ],
    );
  }

// TextField for "Nominal"
  Widget _buildNominalTextField() {
    return _buildCustomTextField(
      controller: nominalController,
      hintText: 'Masukkan jumlah dalam bentuk Rp',
      icon: Icons.money,
      inputFormatters: [ThousandSeparatorInputFormatter()],
      prefixText: showPrefix ? 'Rp. ' : null,
    );
  }

// TextField for "Jumlah Satuan"
  Widget _buildJumlahSatuanTextField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
      ),
      child: TextField(
        controller: jumlahSatuanController,
        keyboardType: TextInputType.number, // Allow only numbers
        style: TextStyle(fontSize: 14),
        onChanged: (value) {
          _calculateTotal(value); // Recalculate total whenever this changes
        },
        decoration: InputDecoration(
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
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.format_list_numbered, // Icon for the field
                  color: Colors.white,
                ),
              ),
            ),
          ),
          hintText: 'Masukkan jumlah satuan',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

// TextField for "Dll" (Biaya Tambahan)
  Widget _buildDllTextField() {
    return _buildCustomTextField(
      controller: dllController,
      hintText: 'Masukkan biaya tambahan (DLL)',
      icon: Icons.attach_money,
      inputFormatters: [ThousandSeparatorInputFormatter()], // Format as needed
      onChanged: _calculateTotal, // Recalculate total whenever this changes
    );
  }

// Field for "Jumlah" (Auto-calculated)
  Widget _buildJumlahField() {
    return _buildCustomTextField(
      controller: jumlahController,
      hintText: 'Jumlah total akan dihitung otomatis',
      readOnly: true,
      icon: Icons.receipt,
      inputFormatters: [ThousandSeparatorInputFormatter()], // Format as needed
    );
  }

// Helper function for creating custom text fields
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    TextInputType keyboardType =
        TextInputType.number, // Restrict to number input
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters ??
            [FilteringTextInputFormatter.digitsOnly], // Only allow digits
        style: TextStyle(fontSize: 14),
        onChanged: (value) {
          if (onChanged != null) onChanged(value);
        },
        decoration: InputDecoration(
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
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
          // Adjusted to show the prefix text only when the field is focused
          prefixText: controller.text.isEmpty
              ? null
              : (prefixText ??
                  'Rp. '), // Show prefix when the text is not empty
          prefixStyle: TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }

// Function to calculate the total
  // Function to calculate the total
  void _calculateTotal(String value) {
    // Remove the "Rp. " prefix and commas for calculations
    double nominal = double.tryParse(nominalController.text
            .replaceAll('Rp. ', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')) ??
        0;
    int satuan = int.tryParse(jumlahSatuanController.text) ?? 0;
    double dll = double.tryParse(dllController.text
            .replaceAll('Rp. ', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')) ??
        0;

    // Calculate the total
    double total = (nominal * satuan) + dll;

    setState(() {
      // Format the total as "Rp. 62.222"
      jumlahController.text = _formatCurrency(total);
    });
  }

// Helper function to format currency
  String _formatCurrency(double amount) {
    // Use the number format to display in the desired format
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]}.',
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

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickImage, // Trigger image picking on tap
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey[200],
            ),
            height: 60, // Height of the image picker area (same as date field)
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height:
                        40, // Adjust height to match the date field icon size
                    width: 40, // Adjust width to match the date field icon size
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEB8153), // Background color
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26, // Shadow color
                          blurRadius: 4.0, // Blur radius
                          spreadRadius: 1.0, // Shadow spread radius
                          offset: Offset(0, 5), // Shadow position
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.image,
                      color: Colors.white, // Icon color
                      size:
                          24, // Icon size (adjusted to match the date field icon size)
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedImage != null
                        ? 'Pilih gambar: ${selectedImage!.files.first.name}' // Accessing the first file name
                        : 'Pilih gambar dari Galeri',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
            height:
                10), // Space between the image picker and the selected image display
        if (selectedImage != null &&
            selectedImage!
                .files.isNotEmpty) // Ensure there is at least one file
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              File(selectedImage!
                  .files.first.path!), // Use path safely with null check
              height: 200, // Height for the displayed image
              width: double.infinity, // Full width
              fit: BoxFit
                  .cover, // Cover the space while maintaining aspect ratio
            ),
          ),
      ],
    );
  }

// Function to pick an image using FilePicker
  Future<void> _pickImage() async {
    try {
      selectedImage = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple:
            false, // Set to true if you want to allow multiple selections
      );

      if (selectedImage != null) {
        setState(() {
          // Trigger a rebuild to update the UI
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
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
          return ListTile(
            title: Text(suggestion.name),
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
            hintStyle: TextStyle(color: Colors.grey),
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
            Navigator.pop(context); // Add action for Cancel button
          },
          style: ElevatedButton.styleFrom(
            primary: Color(0xFFDA0000), // Color for "Cancel"
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Set radius to 8
            ),
          ),
          child: Text('Cancel'),
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
    nominalController.dispose();
    super.dispose();
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

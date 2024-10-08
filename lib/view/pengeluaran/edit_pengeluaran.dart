import 'dart:io'; // Necessary for File
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Import for file_picker package
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pity_cash/models/outcomes_model.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/models/category_model.dart';
import 'package:pity_cash/service/share_preference.dart';

class EditPengeluaran extends StatefulWidget {
  final List<Pengeluaran> pengeluaranList;
  final Pengeluaran? pengeluaran; // List of Pengeluaran

  EditPengeluaran({required this.pengeluaranList, this.pengeluaran});

  @override
  _EditPengeluaranState createState() => _EditPengeluaranState();
}

class _EditPengeluaranState extends State<EditPengeluaran> {
  List<PengeluaranForm> forms = [];
  final ScrollController _scrollController = ScrollController();
  DateTime? selectedDate; // Initialize selectedDate to hold the selected date

  @override
  void initState() {
    super.initState();

    // Initialize the selected date from the first pengeluaran in the list if available
    if (widget.pengeluaranList.isNotEmpty) {
      selectedDate =
          widget.pengeluaranList.first.tanggal; // Use the first item's date
    }

    // Initialize forms based on pengeluaranList
    print("Pengeluaran List: ${widget.pengeluaranList}"); // Debugging line
    for (var pengeluaran in widget.pengeluaranList) {
      forms.add(PengeluaranForm(
        onRemove: () => _removeForm(forms.length - 1),
        pengeluaran: pengeluaran, // Pass existing data for pre-filling
        isLast: pengeluaran == widget.pengeluaranList.last,
        selectedDate: selectedDate, // Pass the selected date to the form
      ));
    }
    print("Forms Initialized: ${forms.length}"); // Debugging line
  }

  void _removeForm(int index) {
    setState(() {
      forms.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Form berhasil dihapus!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _addForm() {
    setState(() {
      forms.add(PengeluaranForm(
        onRemove: () => _removeForm(forms.length - 1),
        isLast: true, // New form is always last
        selectedDate: selectedDate, // Pass the selected date to the new form
      ));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form baru berhasil ditambahkan!'),
          duration: Duration(seconds: 1),
        ),
      );
    });
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
                    'Edit Pengeluaran',
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
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15),
                    _buildDateField(), // Call _buildDateField here
                    SizedBox(height: 15),
                    Column(
                      children: List.generate(forms.length, (index) {
                        return forms[index]; // Use the pre-filled forms
                      }),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addForm, // Call function to add form
        backgroundColor: Color(0xFFEB8153),
        child: Icon(Icons.add),
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

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () {
        _selectDate(context); // Method to open date picker
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[200], // Background color for the date field
        ),
        child: TextField(
          enabled: false, // Disable text editing, only allow date picker
          decoration: InputDecoration(
            hintText: selectedDate == null
                ? 'Pilih Tanggal' // Placeholder text when no date is selected
                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}', // Display selected date
            hintStyle: TextStyle(color: Colors.black87),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                height: 48, // Height for the circular icon container
                width: 48, // Width for the circular icon container
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(
                      0xFFEB8153), // Background color of the circular icon
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26, // Shadow color
                      blurRadius: 4.0, // Blur radius
                      spreadRadius: 1.0, // Spread radius
                      offset: Offset(0, 5), // Position of the shadow
                    ),
                  ],
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              vertical: 15, // Vertical padding in TextField
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
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked; // Update selectedDate state
      });
    }
  }
}

class PengeluaranForm extends StatefulWidget {
  final VoidCallback onRemove;
  final DateTime? selectedDate; // Callback untuk menghapus form
  final bool isLast;
  final Pengeluaran? pengeluaran;
  // Ensure this is defined

  // Constructor
  PengeluaranForm({
    required this.onRemove,
    this.isLast = false,
    this.selectedDate,
    this.pengeluaran,
  });

  @override
  _PengeluaranFormState createState() => _PengeluaranFormState();
}

class _PengeluaranFormState extends State<PengeluaranForm> {
  bool showPrefix = false;

  // Instantiate the controllers
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
    fetchCategories();

    // Initialize fields with pengeluaran data if available
    if (widget.pengeluaran != null) {
      nameController.text = widget.pengeluaran!.name;
      descriptionController.text = widget.pengeluaran!.description;
      nominalController.text = widget.pengeluaran!.nominal.toString();
      jumlahSatuanController.text = widget.pengeluaran!.jumlahSatuan.toString();
      dllController.text = widget.pengeluaran!.dll.toString();
      selectedDate = widget.pengeluaran!.tanggal;

      // Set selectedCategory based on pengeluaran
      selectedCategory = widget.pengeluaran!
          .category; // Ensure 'category' is part of your Pengeluaran model
    } else {
      selectedDate = widget.selectedDate;
    }

    nominalController.addListener(() {
      setState(() {
        showPrefix = nominalController.text.isNotEmpty;
      });
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

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    nominalController.dispose();
    jumlahSatuanController.dispose();
    dllController.dispose();
    jumlahController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      color: Colors.grey[350],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(selectedDate != null
                ? 'Tanggal: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                : 'No Date Selected'),
            _buildInputFields(),
            SizedBox(height: 20),
            if (widget.isLast) _buildActionButtons(),
          ],
        ),
      ),
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
      readOnly: true, // Keep it read-only as per your requirement
      icon: Icons.receipt,
      inputFormatters: [
        ThousandSeparatorInputFormatter()
      ], // Format with thousand separators
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
    // Get previous total value before calculation
    String previousTotal = jumlahController.text;

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

    // Check if all necessary fields have values
    if (nominal > 0 && satuan > 0) {
      // Calculate the total
      double total = (nominal * satuan) + dll;

      setState(() {
        // Format the total as "Rp. 62.222"
        jumlahController.text = _formatCurrency(total);
      });
    } else {
      // Retain previous total if any field is empty
      setState(() {
        jumlahController.text = previousTotal; // Keep the previous value
      });
    }
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
            height: 60, // Height of the image picker area
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
                      size: 24, // Icon size
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedImage != null
                        ? 'Pilih gambar: ${selectedImage!.files.first.name}' // Display the selected image name
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
        // Only display the image if it's selected
        if (selectedImage != null && selectedImage!.files.isNotEmpty)
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

      // Update the state only if an image is selected
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
        color: Colors.grey[200],
      ),
      child: TypeAheadFormField<Category>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: TextEditingController(text: selectedCategory?.name ?? ''),
          decoration: InputDecoration(
            hintText: 'Pilih kategori',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
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
                  child: Icon(Icons.category, color: Colors.white),
                ),
              ),
            ),
            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          ),
        ),
        suggestionsCallback: (pattern) async {
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
            selectedCategory = suggestion;
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
          onPressed:
              widget.onRemove, // Panggil onRemove untuk menghapus form ini
          style: ElevatedButton.styleFrom(
            primary: Color(0xFFDA0000), // Warna untuk "Cancel"
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Set radius to 8
            ),
          ),
          child: Text('Cancel'),
        ),
        SizedBox(width: 16), // Tambahkan jarak antar tombol

        ElevatedButton(
          onPressed: () {
            // Logika untuk menyimpan data form
            // Misalnya: submit();
          },
          style: ElevatedButton.styleFrom(
            primary: Color(0xFFE85C0D), // Warna untuk "Simpan"
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Set radius to 8
            ),
          ),
          child: Text('Simpan'),
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

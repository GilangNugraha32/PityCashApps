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
import 'dart:convert';

import 'package:pity_cash/view/home/home.dart';

class TambahPengeluaran extends StatefulWidget {
  @override
  _TambahPengeluaranState createState() => _TambahPengeluaranState();
}

class _TambahPengeluaranState extends State<TambahPengeluaran> {
  final List<GlobalKey<_PengeluaranFormState>> formKeys = [];
  final ScrollController _scrollController = ScrollController();
  DateTime? selectedDate;
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _addForm(); // Add the first form immediately upon init
    fetchCategories();
  }

  void _addForm() {
    setState(() {
      final formKey = GlobalKey<_PengeluaranFormState>();
      formKeys.add(formKey);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _handleSubmit() async {
    List<Map<String, dynamic>> allFormData = [];
    List<File?> selectedImages = [];

    for (var key in formKeys) {
      var data = key.currentState?.getFormData();
      if (data != null && data.isNotEmpty) {
        allFormData.add(data);

        if (key.currentState?.selectedImage != null &&
            key.currentState!.selectedImage!.files.isNotEmpty) {
          String? imagePath = key.currentState!.selectedImage!.files.first.path;
          if (imagePath != null) {
            selectedImages.add(File(imagePath));
          } else {
            selectedImages.add(null);
          }
        } else {
          selectedImages.add(null);
        }
      }
    }

    print('Mengirim data: $allFormData');

    if (allFormData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada data untuk dikirim')),
      );
      return;
    }

    List<String> names = [];
    List<String> descriptions = [];
    List<int> jumlahs = [];
    List<int> jumlahSatuans = [];
    List<double> nominals = [];
    List<double> dls = [];
    List<int> categoryIds = [];
    List<File> images = [];

    String parentDate =
        DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now());

    for (var entry in allFormData) {
      Map<String, dynamic> parentPengeluaran = entry['parentPengeluaran'];
      List<Map<String, dynamic>> pengeluaranItems = entry['pengeluaran'];

      for (var item in pengeluaranItems) {
        names.add(item['name']);
        descriptions.add(item['description']);
        jumlahs.add(int.parse(item['jumlah']));
        jumlahSatuans.add(int.parse(item['jumlah_satuan']));
        nominals.add(double.parse(item['nominal']));
        dls.add(double.parse(item['dll']));
        categoryIds.add(int.parse(item['id']));

        if (item['image'] != null) {
          images.add(item['image'] as File);
        }
      }
    }

    try {
      await ApiService().createPengeluaran(
        names,
        descriptions,
        [parentDate],
        jumlahs,
        jumlahSatuans,
        nominals,
        dls,
        categoryIds,
        images.isNotEmpty
            ? images
            : selectedImages
                .where((image) => image != null)
                .map((image) => image!)
                .toList(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil ditambahkan!',
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

      // Refresh halaman sebelumnya dan kembali
      Navigator.pop(context, true);
      // Refresh halaman PengeluaranSection dengan mempertahankan bottom navigation bar
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(initialIndex: 3),
        ),
      );
    } catch (error) {
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menambahkan data',
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

  void _removeForm(int index) {
    setState(() {
      if (formKeys.length > 1) {
        formKeys.removeAt(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Form berhasil dihapus!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Minimal satu form harus ada!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> fetchCategories() async {
    try {
      ApiService apiService = ApiService();
      List<Category> allCategories = await apiService.fetchCategories();
      setState(() {
        categories = allCategories
            .where((category) => category.jenisKategori == 2)
            .toList();
      });
    } catch (e) {
      print('Error fetching categories: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat kategori')),
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
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
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
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15),
                    _buildDateField(),
                    SizedBox(height: 20),
                    Column(
                      children: List.generate(formKeys.length, (index) {
                        return PengeluaranForm(
                          key: formKeys[index],
                          onRemove: () => _removeForm(index),
                          onSubmit:
                              (List<Map<String, dynamic>> pengeluaranList) {
                            print(
                                'Submitted data for form $index: $pengeluaranList');
                          },
                          isLast: index == formKeys.length - 1,
                          selectedDate: selectedDate,
                          categories: categories,
                          isFirst: index == 0,
                          onDateChanged: (DateTime newDate) {
                            setState(() {
                              selectedDate = newDate;
                              for (var key in formKeys) {
                                (key.currentState as _PengeluaranFormState)
                                    .updateDate(newDate);
                              }
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _addForm,
                          style: ElevatedButton.styleFrom(
                            primary: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('+ Tambah Pengeluaran'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Color(0xFFDA0000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Batal'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            primary: Color(0xFFE85C0D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Simpan'),
                        ),
                      ],
                    ),
                  ],
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

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () {
        _selectDate(context);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[200],
        ),
        child: Row(
          children: [
            // Icon container
            Padding(
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
            ),
            // TextField
            Expanded(
              // This will make the TextField take the remaining width
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: selectedDate == null
                      ? 'Pilih Tanggal'
                      : DateFormat('dd/MM/yyyy').format(selectedDate!),
                  hintStyle: TextStyle(color: Colors.black87),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
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
        selectedDate = picked;
        // Update date for all forms
        for (var key in formKeys) {
          (key.currentState as _PengeluaranFormState).updateDate(picked);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Tanggal diperbarui: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class PengeluaranForm extends StatefulWidget {
  final VoidCallback onRemove;
  final DateTime? selectedDate;
  final bool isLast;

  final bool isFirst;
  final Function(List<Map<String, dynamic>>) onSubmit;
  final Function(DateTime) onDateChanged;
  FilePickerResult? selectedImage; // Store the selected image here

  PengeluaranForm({
    required this.onRemove,
    required this.onSubmit,
    required this.onDateChanged,
    this.selectedDate,
    this.isLast = false,
    this.isFirst = false,
    Key? key,
    required List<Category> categories,
  }) : super(key: key);
  @override
  _PengeluaranFormState createState() => _PengeluaranFormState();
}

class _PengeluaranFormState extends State<PengeluaranForm> {
  final List<GlobalKey<_PengeluaranFormState>> formKeys = [];
  bool showPrefix = false;
  int _selectedIndex = 0;

  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final List<TextEditingController> nameControllers = [];
  final List<TextEditingController> descriptionControllers = [];
  final List<TextEditingController> nominalControllers = [];
  final List<TextEditingController> jumlahSatuanControllers = [];
  final List<TextEditingController> dllControllers = [];
  final List<TextEditingController> jumlahControllers = [];
  final List<DateTime> selectedDates = [];

  DateTime? selectedDate;
  List<Category> categories = [];
  Category? selectedCategory;
  FilePickerResult? selectedImage;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    addPengeluaranField();
    selectedDate = widget.selectedDate ?? DateTime.now();
  }

  void addPengeluaranField() {
    setState(() {
      nameControllers.add(TextEditingController());
      descriptionControllers.add(TextEditingController());
      nominalControllers.add(TextEditingController());
      jumlahSatuanControllers.add(TextEditingController());
      dllControllers.add(TextEditingController());
      jumlahControllers.add(TextEditingController());
      selectedDates.add(selectedDate ?? DateTime.now());
    });
  }

  void updateDate(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
      for (int i = 0; i < selectedDates.length; i++) {
        selectedDates[i] = newDate;
      }
    });
  }

  Map<String, dynamic> getFormData() {
    // Prepare the data for submission
    List<String> names =
        nameControllers.map((controller) => controller.text).toList();
    List<String> descriptions =
        descriptionControllers.map((controller) => controller.text).toList();

    // Convert nominal, dll, and jumlah values to integers after removing non-digit characters
    List<int> nominals = nominalControllers.map((controller) {
      String text = controller.text
          .replaceAll(RegExp(r'[^0-9]'), ''); // Remove non-digit characters
      return int.tryParse(text) ?? 0; // Convert to int
    }).toList();

    List<int> jumlahSatuan = jumlahSatuanControllers.map((controller) {
      String text = controller.text
          .replaceAll(RegExp(r'[^0-9]'), ''); // Remove non-digit characters
      return int.tryParse(text) ?? 1; // Default to 1 if parsing fails
    }).toList();

    List<int> dll = dllControllers.map((controller) {
      String text = controller.text
          .replaceAll(RegExp(r'[^0-9]'), ''); // Remove non-digit characters
      return int.tryParse(text) ?? 0; // Convert to int
    }).toList();

    List<int> jumlah = jumlahControllers.map((controller) {
      String text = controller.text
          .replaceAll(RegExp(r'[^0-9]'), ''); // Remove non-digit characters
      return int.tryParse(text) ?? 0; // Convert to int
    }).toList();

    String date =
        DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now());

    int? category = selectedCategory?.id;

    // Check for errors before submitting
    if (names.isEmpty ||
        descriptions.isEmpty ||
        nominals.isEmpty ||
        jumlahSatuan.isEmpty ||
        dll.isEmpty ||
        jumlah.isEmpty ||
        category == null) {
      throw Exception("All fields must be filled out before submission.");
    }

    // Create parent pengeluaran data
    Map<String, dynamic> parentPengeluaran = {
      'tanggal': date,
      'updated_at': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };

    // Create list of pengeluaran items
    List<Map<String, dynamic>> pengeluaranItems = [];
    for (int i = 0; i < names.length; i++) {
      Map<String, dynamic> item = {
        'name': names[i],
        'description': descriptions[i],
        'jumlah_satuan': jumlahSatuan[i].toString(),
        'nominal': nominals[i].toString(),
        'dll': dll[i].toString(),
        'jumlah': jumlah[i].toString(),
        'id': category.toString(),
        'updated_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      if (selectedImage != null && selectedImage!.files.isNotEmpty) {
        item['image'] = File(selectedImage!.files.first.path!);
      }

      pengeluaranItems.add(item);
    }

    // Return complete form data structure
    return {
      'parentPengeluaran': parentPengeluaran,
      'pengeluaran': pengeluaranItems,
    };
  }

  Future<void> fetchCategories() async {
    try {
      ApiService apiService = ApiService();
      List<Category> allCategories = await apiService.fetchCategories();
      categories = allCategories
          .where((category) => category.jenisKategori == 2)
          .toList();
      setState(() {});
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  // Add any additional methods and widgets as necessary

  void _clearInputFields() {
    for (var controller in nameControllers) {
      controller.clear();
    }
    for (var controller in descriptionControllers) {
      controller.clear();
    }
    for (var controller in jumlahControllers) {
      controller.clear();
    }
    for (var controller in nominalControllers) {
      controller.clear();
    }
    for (var controller in dllControllers) {
      controller.clear();
    }
    setState(() {
      selectedCategory = null;
    });
  }

  @override
  void dispose() {
    for (var controller in nameControllers) {
      controller.dispose();
    }
    for (var controller in descriptionControllers) {
      controller.dispose();
    }
    for (var controller in nominalControllers) {
      controller.dispose();
    }
    for (var controller in jumlahSatuanControllers) {
      controller.dispose();
    }
    for (var controller in dllControllers) {
      controller.dispose();
    }
    for (var controller in jumlahControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(height: 10),
            _buildInputFields(),
            SizedBox(height: 20),
            Divider(
              thickness: 1,
              color: Colors.grey,
            ),
            // Only show action buttons for the second form and onwards
            if (!widget.isFirst) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Nama Pengeluaran'),
        SizedBox(
          height: 10,
        ),
        _buildTextField(
          icon: Icons.attach_money,
          controller: nameControllers.last,
          hintText: 'Masukkan nama pengeluaran',
        ),
        SizedBox(
          height: 10,
        ),
        _buildLabel('Deskripsi'),
        SizedBox(
          height: 10,
        ),
        _buildTextField(
          icon: Icons.format_align_left,
          controller: descriptionControllers.last,
          hintText: 'Masukkan Deskripsi',
        ),
        SizedBox(
          height: 10,
        ),
        _buildLabel('Nominal'),
        SizedBox(
          height: 10,
        ),
        _buildNominalTextField(),
        SizedBox(
          height: 10,
        ),
        _buildLabel('Jumlah Satuan'),
        SizedBox(
          height: 10,
        ),
        _buildJumlahSatuanTextField(),
        SizedBox(
          height: 10,
        ),
        _buildLabel('Biaya Tambahan (DLL)'),
        SizedBox(
          height: 10,
        ),
        _buildDllTextField(),
        SizedBox(
          height: 10,
        ),
        _buildLabel('Jumlah'),
        SizedBox(
          height: 10,
        ),
        _buildJumlahField(),
        SizedBox(
          height: 10,
        ),
        _buildLabel('Kategori:'),
        SizedBox(
          height: 10,
        ),
        _buildCategoryDropdown(),
        SizedBox(
          height: 10,
        ),
        if (widget.isLast) _buildLabel('Pilih Gambar:'),
        SizedBox(
          height: 10,
        ),
        if (widget.isLast) _buildImagePicker(),
      ],
    );
  }

// TextField for "Nominal"
  Widget _buildNominalTextField() {
    return _buildCustomTextField(
      controller: nominalControllers.last,
      hintText: 'Masukkan jumlah',
      icon: Icons.money,
      inputFormatters: [ThousandSeparatorInputFormatter()],
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
        controller: jumlahSatuanControllers.last,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 14),
        onChanged: (value) {
          _calculateTotal(value);
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
                  Icons.format_list_numbered,
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
      controller: dllControllers.last,
      hintText: 'Masukkan biaya tambahan (DLL)',
      icon: Icons.attach_money,
      inputFormatters: [ThousandSeparatorInputFormatter()],
      onChanged: _calculateTotal,
    );
  }

// Field for "Jumlah" (Auto-calculated)
  Widget _buildJumlahField() {
    return _buildCustomTextField(
      controller: jumlahControllers.last,
      hintText: 'Jumlah total akan dihitung otomatis',
      readOnly: true,
      icon: Icons.receipt,
      inputFormatters: [ThousandSeparatorInputFormatter()],
    );
  }

// Helper function for creating custom text fields
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
    TextInputType keyboardType = TextInputType.number,
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
        inputFormatters:
            inputFormatters ?? [FilteringTextInputFormatter.digitsOnly],
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
  void _calculateTotal(String value) {
    double nominal = double.tryParse(
            nominalControllers.last.text.replaceAll(RegExp(r'[^\d]'), '')) ??
        0;
    int satuan = int.tryParse(jumlahSatuanControllers.last.text) ?? 0;
    double dll = double.tryParse(
            dllControllers.last.text.replaceAll(RegExp(r'[^\d]'), '')) ??
        0;

    double total = (nominal * satuan) + dll;

    setState(() {
      jumlahControllers.last.text = _formatCurrency(total);
    });
  }

// Helper function to format currency
  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        selectedImage = result; // Save the selected image
      });
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
          return Column(
            children: [
              ListTile(
                title: Text(
                  suggestion.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // Buat teks tebal
                    fontSize: 15, // Ukuran teks lebih kecil
                  ),
                ),
              ),
              Divider(height: 0.25, color: Colors.grey), // Divider antar item
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: widget.onRemove,
          style: ElevatedButton.styleFrom(
            primary: Color(0xFFDA0000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Hapus Form'),
        ),
        SizedBox(width: 16),
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
        'Rp' + NumberFormat('#,##0', 'id_ID').format(int.parse(newText));

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

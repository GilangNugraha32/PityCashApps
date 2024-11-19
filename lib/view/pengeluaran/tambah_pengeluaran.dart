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

  void _removeForm(int index) {
    setState(() {
      if (formKeys.length > 1) {
        formKeys.removeAt(index);
      }
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
          // Header Section with Orange Background
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.16,
            decoration: BoxDecoration(
              color: Color(0xFFEB8153),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFEB8153).withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(25.0),
                bottomLeft: Radius.circular(25.0),
              ),
            ),
            child: Stack(
              fit: StackFit.loose,
              children: [
                // Background pattern dengan ukuran relatif
                Positioned(
                  right: -MediaQuery.of(context).size.width * 0.05,
                  bottom: -MediaQuery.of(context).size.width * 0.05,
                  child: Icon(
                    Icons.trending_down_rounded,
                    size: MediaQuery.of(context).size.width * 0.35,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
                Positioned(
                  left: -MediaQuery.of(context).size.width * 0.05,
                  top: MediaQuery.of(context).size.width * 0.05,
                  child: Icon(
                    Icons.money_off_rounded,
                    size: MediaQuery.of(context).size.width * 0.2,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                // Content dengan padding yang responsif
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.04,
                      vertical: MediaQuery.of(context).size.height * 0.01,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 35,
                              minHeight: 35,
                            ),
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        Flexible(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tambah Pengeluaran',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                        color: Colors.black.withOpacity(0.2),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 2),
                                Container(
                                  width: 40,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
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
              ],
            ),
          ),

          SizedBox(height: 20), // Jarak antara background orange dan putih

          // White Background Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Column(
                children: [
                  // Fixed Date Field
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildDateField(),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: List.generate(formKeys.length, (index) {
                                return Column(
                                  children: [
                                    PengeluaranForm(
                                      key: formKeys[index],
                                      onRemove: () => _removeForm(index),
                                      onSubmit: (List<Map<String, dynamic>>
                                          pengeluaranList) {
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
                                            (key.currentState
                                                    as _PengeluaranFormState)
                                                .updateDate(newDate);
                                          }
                                        });
                                      },
                                    ),
                                    SizedBox(
                                        height:
                                            16), // Menambahkan jarak 16 pixel antar form
                                  ],
                                );
                              }),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Color(0xFFEB8153),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color(0xFFEB8153).withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _addForm,
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: Color(0xFFEB8153),
                                      size: 16,
                                    ),
                                    label: Text(
                                      'Tambah Form Pengeluaran',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFEB8153),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 60,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Total Form:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${formKeys.length} Data Pengeluaran',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 6),
                        SizedBox(
                          width: 80,
                          height: 34,
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            child: Text(
                              'Simpan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: Color(0xFFE85C0D),
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              elevation: 0.5,
                            ),
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
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
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

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () {
        _selectDate(context);
      },
      child: Container(
        height: 35, // Mengurangi tinggi container
        margin: EdgeInsets.symmetric(
            horizontal: 4, vertical: 4), // Mengurangi margin vertical
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8), // Mengurangi radius
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.all(6), // Mengurangi padding
              child: Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFFEB8153),
                size: 16, // Mengurangi ukuran icon
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 8), // Mengurangi padding horizontal
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.grey[300]!,
                    width: 0.5, // Mengurangi ketebalan border
                  ),
                ),
              ),
              child: Text(
                selectedDate == null
                    ? 'Pilih Tanggal'
                    : '${selectedDate!.day} ${_getMonthName(selectedDate!.month)} ${selectedDate!.year}',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 12, // Mengurangi ukuran font
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2, // Mengurangi letter spacing
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

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

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

    // DLL (biaya tambahan) defaultnya 0 jika tidak diisi
    List<int> dll = dllControllers.map((controller) {
      String text = controller.text
          .replaceAll(RegExp(r'[^0-9]'), ''); // Remove non-digit characters
      return int.tryParse(text) ?? 0; // Default to 0 if empty or invalid
    }).toList();

    List<int> jumlah = jumlahControllers.map((controller) {
      String text = controller.text
          .replaceAll(RegExp(r'[^0-9]'), ''); // Remove non-digit characters
      return int.tryParse(text) ?? 0; // Convert to int
    }).toList();

    String date =
        DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now());

    int? category = selectedCategory?.id;

    // Check for empty fields and build error message
    List<String> emptyFields = [];

    if (names.any((name) => name.isEmpty)) {
      emptyFields.add('Nama');
    }
    if (descriptions.any((desc) => desc.isEmpty)) {
      emptyFields.add('Deskripsi');
    }
    if (nominals.any((nominal) => nominal == 0)) {
      emptyFields.add('Nominal');
    }
    if (jumlahSatuan.any((js) => js == 0)) {
      emptyFields.add('Jumlah Satuan');
    }
    if (jumlah.any((j) => j == 0)) {
      emptyFields.add('Jumlah');
    }
    if (category == null) {
      emptyFields.add('Kategori');
    }

    if (emptyFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Field berikut belum diisi: ${emptyFields.join(", ")}',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.yellow[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );

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
        'dll': dll[i].toString(), // DLL akan bernilai 0 jika field kosong
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
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(height: 6),
            _buildInputFields(),
            SizedBox(height: 12),
            Divider(
              thickness: 1,
              color: Colors.grey,
            ),
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
        // Nama Pengeluaran Section
        _buildLabel('Nama Pengeluaran'),
        SizedBox(height: 4),
        _buildTextField(
          icon: Icons.sticky_note_2_outlined,
          controller: nameControllers.last,
          hintText: 'Masukkan nama pengeluaran',
        ),
        SizedBox(height: 12),

        // Deskripsi Section
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
            controller: descriptionControllers.last,
            maxLines: 4,
            style: TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Masukkan deskripsi pengeluaran',
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

        // Nominal & Jumlah Satuan Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Nominal'),
                SizedBox(height: 4),
                _buildNominalTextField(),
              ],
            ),
            SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Jumlah Satuan'),
                SizedBox(height: 4),
                _buildJumlahSatuanTextField(),
              ],
            ),
          ],
        ),
        SizedBox(height: 12),

        // Biaya Tambahan Section
        _buildLabel('Biaya Tambahan (DLL)'),
        SizedBox(height: 4),
        _buildDllTextField(),
        SizedBox(height: 12),

        // Total Jumlah Section
        _buildLabel('Jumlah'),
        SizedBox(height: 4),
        _buildJumlahField(),
        SizedBox(height: 12),

        // Kategori Section
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

        // Image Picker Section (Only for last form)
        // if (widget.isLast) ...[
        _buildLabel('Pilih Gambar (Opsional)'),
        SizedBox(height: 4),
        _buildImagePicker(),
        // ],
      ],
    );
  }

  Widget _buildCategoryModal() {
    categoryController.text = selectedCategory?.name ?? '';

    ValueNotifier<List<Category>> filteredCategories =
        ValueNotifier<List<Category>>(categories);

    // Filter awal sesuai dengan isi _searchController
    if (_searchController.text.isNotEmpty) {
      filteredCategories.value = categories
          .where((category) => category.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    }

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
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) {
                      // Ketika kehilangan fokus, nilai tetap dipertahankan dan filter diupdate
                      setState(() {
                        filteredCategories.value = categories
                            .where((category) => category.name
                                .toLowerCase()
                                .contains(_searchController.text.toLowerCase()))
                            .toList();
                      });
                    }
                  },
                  child: TextField(
                    controller: _searchController,
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
                      setState(() {
                        filteredCategories.value = categories
                            .where((category) => category.name
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      });
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
                    'Kategori Pengeluaran',
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

// TextField for "Nominal"
  Widget _buildNominalTextField() {
    return Container(
      width: double.infinity,
      height: 40,
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
              controller: nominalControllers.last,
              keyboardType: TextInputType.number,
              textAlignVertical: TextAlignVertical.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandSeparatorInputFormatter(),
              ],
              style: TextStyle(fontSize: 12),
              onChanged: (value) {
                if (value.isEmpty) {
                  nominalControllers.last.text = "0";
                  nominalControllers.last.selection =
                      TextSelection.fromPosition(
                    TextPosition(offset: nominalControllers.last.text.length),
                  );
                }
                _calculateTotal('');
              },
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Icon(
                    Icons.money,
                    color: Color(0xFFEB8153),
                    size: 16,
                  ),
                ),
                suffixText: 'IDR',
                suffixStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                hintText: 'Masukkan jumlah',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                isDense: true,
                alignLabelWithHint: true,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  String currentText = nominalControllers.last.text.isEmpty
                      ? "0"
                      : nominalControllers.last.text
                          .replaceAll(RegExp(r'[^0-9]'), '');
                  int currentValue = int.tryParse(currentText) ?? 0;
                  int newValue = currentValue + 1;
                  String formattedValue = NumberFormat('#,###')
                      .format(newValue)
                      .replaceAll(',', '.');
                  nominalControllers.last.text = formattedValue;
                  _calculateTotal('');
                },
                child: Icon(Icons.arrow_drop_up,
                    color: Color(0xFFEB8153), size: 16),
              ),
              InkWell(
                onTap: () {
                  String currentText = nominalControllers.last.text.isEmpty
                      ? "0"
                      : nominalControllers.last.text
                          .replaceAll(RegExp(r'[^0-9]'), '');
                  int currentValue = int.tryParse(currentText) ?? 0;
                  if (currentValue > 0) {
                    int newValue = currentValue - 1;
                    String formattedValue = NumberFormat('#,###')
                        .format(newValue)
                        .replaceAll(',', '.');
                    nominalControllers.last.text = formattedValue;
                    _calculateTotal('');
                  }
                },
                child: Icon(Icons.arrow_drop_down,
                    color: Color(0xFFEB8153), size: 16),
              ),
            ],
          ),
          SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildJumlahSatuanTextField() {
    return Container(
      width: double.infinity,
      height: 40,
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
              controller: jumlahSatuanControllers.last,
              keyboardType: TextInputType.number,
              textAlignVertical: TextAlignVertical.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: TextStyle(fontSize: 12),
              onChanged: (value) {
                if (value.isEmpty) {
                  // Ketika field kosong, set nilai ke "0"
                  jumlahSatuanControllers.last.text = "0";
                  jumlahSatuanControllers.last.selection =
                      TextSelection.fromPosition(
                    TextPosition(
                        offset: jumlahSatuanControllers.last.text.length),
                  );
                } else if (value == "0") {
                  // Ketika nilai "0" dimasukkan, kosongkan field
                  jumlahSatuanControllers.last.clear();
                } else if (value.startsWith('0') && value.length > 1) {
                  // Hapus leading zeros
                  jumlahSatuanControllers.last.text =
                      value.replaceFirst(RegExp(r'^0+'), '');
                  jumlahSatuanControllers.last.selection =
                      TextSelection.fromPosition(
                    TextPosition(
                        offset: jumlahSatuanControllers.last.text.length),
                  );
                }
                _calculateTotal('');
              },
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Icon(
                    Icons.format_list_numbered,
                    color: Color(0xFFEB8153),
                    size: 16,
                  ),
                ),
                hintText: 'Masukkan jumlah satuan',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                isDense: true,
                alignLabelWithHint: true,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  String currentText = jumlahSatuanControllers.last.text.isEmpty
                      ? "0"
                      : jumlahSatuanControllers.last.text;
                  int currentValue = int.tryParse(currentText) ?? 0;
                  int newValue = currentValue + 1;
                  jumlahSatuanControllers.last.text = newValue.toString();
                  _calculateTotal('');
                },
                child: Icon(Icons.arrow_drop_up,
                    color: Color(0xFFEB8153), size: 16),
              ),
              InkWell(
                onTap: () {
                  String currentText = jumlahSatuanControllers.last.text.isEmpty
                      ? "0"
                      : jumlahSatuanControllers.last.text;
                  int currentValue = int.tryParse(currentText) ?? 0;
                  if (currentValue > 0) {
                    int newValue = currentValue - 1;
                    if (newValue == 0) {
                      jumlahSatuanControllers.last.clear();
                    } else {
                      jumlahSatuanControllers.last.text = newValue.toString();
                    }
                    _calculateTotal('');
                  }
                },
                child: Icon(Icons.arrow_drop_down,
                    color: Color(0xFFEB8153), size: 16),
              ),
            ],
          ),
          SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildDllTextField() {
    return Container(
      width: double.infinity,
      height: 40,
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
              controller: dllControllers.last,
              keyboardType: TextInputType.number,
              textAlignVertical: TextAlignVertical.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandSeparatorInputFormatter(),
              ],
              style: TextStyle(fontSize: 12),
              onChanged: (value) {
                if (value.isEmpty) {
                  dllControllers.last.text = "0";
                  dllControllers.last.selection = TextSelection.fromPosition(
                    TextPosition(offset: dllControllers.last.text.length),
                  );
                }
                _calculateTotal('');
              },
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Icon(
                    Icons.attach_money,
                    color: Color(0xFFEB8153),
                    size: 16,
                  ),
                ),
                suffixText: 'IDR',
                suffixStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                hintText: 'Masukkan biaya tambahan (DLL)',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                isDense: true,
                alignLabelWithHint: true,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  String currentText = dllControllers.last.text.isEmpty
                      ? "0"
                      : dllControllers.last.text
                          .replaceAll(RegExp(r'[^0-9]'), '');
                  int currentValue = int.tryParse(currentText) ?? 0;
                  int newValue = currentValue + 1;
                  String formattedValue = NumberFormat('#,###')
                      .format(newValue)
                      .replaceAll(',', '.');
                  dllControllers.last.text = formattedValue;
                  _calculateTotal('');
                },
                child: Icon(Icons.arrow_drop_up,
                    color: Color(0xFFEB8153), size: 16),
              ),
              InkWell(
                onTap: () {
                  String currentText = dllControllers.last.text.isEmpty
                      ? "0"
                      : dllControllers.last.text
                          .replaceAll(RegExp(r'[^0-9]'), '');
                  int currentValue = int.tryParse(currentText) ?? 0;
                  if (currentValue > 0) {
                    int newValue = currentValue - 1;
                    String formattedValue = NumberFormat('#,###')
                        .format(newValue)
                        .replaceAll(',', '.');
                    dllControllers.last.text = formattedValue;
                    _calculateTotal('');
                  }
                },
                child: Icon(Icons.arrow_drop_down,
                    color: Color(0xFFEB8153), size: 16),
              ),
            ],
          ),
          SizedBox(width: 6),
        ],
      ),
    );
  }

// Field for "Jumlah" (Auto-calculated)
  Widget _buildJumlahField() {
    return Container(
      width: double.infinity,
      height: 40,
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
              controller: jumlahControllers.last,
              readOnly: true,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(fontSize: 12),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Icon(
                    Icons.receipt,
                    color: Color(0xFFEB8153),
                    size: 16,
                  ),
                ),
                suffixText: 'IDR',
                suffixStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
                hintText: 'Jumlah total akan dihitung otomatis',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                isDense: true,
                alignLabelWithHint: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Function to calculate the total
  void _calculateTotal(String value) {
    double nominal = double.tryParse(nominalControllers.last.text.isEmpty
            ? "0"
            : nominalControllers.last.text.replaceAll(RegExp(r'[^\d]'), '')) ??
        0;
    int satuan = int.tryParse(jumlahSatuanControllers.last.text.isEmpty
            ? "0"
            : jumlahSatuanControllers.last.text) ??
        0;
    double dll = double.tryParse(dllControllers.last.text.isEmpty
            ? "0"
            : dllControllers.last.text.replaceAll(RegExp(r'[^\d]'), '')) ??
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
        fontSize: 12,
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
      height: 40,
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
              controller: controller,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(fontSize: 12),
              decoration: InputDecoration(
                suffixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Icon(
                    icon,
                    color: Color(0xFFEB8153),
                    size: 16,
                  ),
                ),
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                isDense: true,
                alignLabelWithHint: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
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
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFFEB8153).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      color: Color(0xFFEB8153),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedImage != null
                          ? selectedImage!.files.first.name
                          : 'Cari atau pilih gambar...',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selectedImage != null && selectedImage!.files.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(selectedImage!.files.first.path!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: TextField(
          enabled: false,
          style: TextStyle(fontSize: 10),
          decoration: InputDecoration(
            hintText: selectedDate == null
                ? 'Pilih Tanggal'
                : '${selectedDate!.day.toString().padLeft(2, '0')} ${_getMonthName(selectedDate!.month)} ${selectedDate!.year}',
            hintStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(
                Icons.calendar_today,
                color: Color(0xFFEB8153),
                size: 16,
              ),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
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
              primary: Color(0xFFEB8153),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                primary: Color(0xFFEB8153),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            dialogBackgroundColor: Colors.white,
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
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

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: widget.onRemove,
          style: ElevatedButton.styleFrom(
            primary: Color(0xFFDA0000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            minimumSize: Size(80, 30),
          ),
          child: Text(
            'Hapus Form',
            style: TextStyle(fontSize: 10),
          ),
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

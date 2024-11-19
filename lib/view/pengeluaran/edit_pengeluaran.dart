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
import 'package:pity_cash/view/home/home.dart';
import 'package:pity_cash/view/pemasukan/tambah_pemasukan.dart';
import 'package:pity_cash/view/pengeluaran/pengeluaran_section.dart';

class EditPengeluaran extends StatefulWidget {
  final List<Pengeluaran> pengeluaranList;
  final Pengeluaran? pengeluaran;

  EditPengeluaran({required this.pengeluaranList, this.pengeluaran});

  @override
  _EditPengeluaranState createState() => _EditPengeluaranState();
}

class _EditPengeluaranState extends State<EditPengeluaran> {
  List<PengeluaranForm> forms = [];
  final List<GlobalKey<_PengeluaranFormState>> formKeys = [];
  final ScrollController _scrollController = ScrollController();
  DateTime? selectedDate;
  List<Category> categories = [];
  final TextEditingController _dateController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.pengeluaranList.isNotEmpty) {
      selectedDate = widget.pengeluaranList.isNotEmpty
          ? widget.pengeluaranList.first.tanggal
          : DateTime.now();

      _dateController.text = DateFormat('dd MMMM yyyy').format(selectedDate!);
    }

    for (var pengeluaran in widget.pengeluaranList) {
      GlobalKey<_PengeluaranFormState> formKey =
          GlobalKey<_PengeluaranFormState>();
      formKeys.add(formKey);
      forms.add(PengeluaranForm(
        key: formKey,
        onRemove: () => _removeForm(formKeys.length - 1),
        onSubmit: (List<Map<String, dynamic>> pengeluaranList) {
          print('Submitted data for form: $pengeluaranList');
        },
        pengeluaran: pengeluaran,
        isLast: pengeluaran == widget.pengeluaranList.last,
        selectedDate: selectedDate,
        categories: [],
      ));
    }
  }

  void _handleSubmit() async {
    List<Map<String, dynamic>> allFormData = [];
    List<File?> selectedImages = [];

    // Validasi dan kumpulkan data dari semua form
    for (var key in formKeys) {
      var data = key.currentState?.getFormData();
      if (data != null && data.isNotEmpty) {
        allFormData.add(data);

        // Cek apakah ada gambar yang dipilih
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

    // Siapkan data untuk API request
    List<String> names = [];
    List<String> descriptions = [];
    List<int> jumlahs = [];
    List<int> jumlahSatuans = [];
    List<double> nominals = [];
    List<double> dls = [];
    List<int> categoryIds = [];
    List<int> dataIds = [];
    List<String> tanggalList = [];
    List<File?> images =
        List.filled(allFormData.length, null); // Initialize dengan null

    // Dapatkan parent ID dari pengeluaran pertama
    int parentId = widget.pengeluaranList.isNotEmpty
        ? widget.pengeluaranList.first.idParent
        : 0;

    // Format data sesuai dengan response yang diharapkan
    for (int i = 0; i < allFormData.length; i++) {
      var entry = allFormData[i];
      dataIds.add(entry['id_data'] ?? 0);
      names.add(entry['name']);
      descriptions.add(entry['description'] ?? '');
      jumlahs.add(entry['jumlah']);
      jumlahSatuans.add(entry['jumlah_satuan']);
      nominals.add(entry['nominal']);
      dls.add(entry['dll']);
      categoryIds.add(entry['category']);

      // Format tanggal sesuai dengan response "YYYY-MM-DD"
      String tanggal = entry['tanggal'] ?? DateTime.now().toIso8601String();
      try {
        DateTime parsedDate = DateTime.parse(tanggal);
        String formattedDate =
            "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
        tanggalList.add(formattedDate);
        print('Tanggal terformat dari form: $formattedDate');
      } catch (e) {
        print('Error saat parsing tanggal: $tanggal. Error: $e');
      }

      // Hanya update gambar jika ada perubahan
      if (selectedImages[i] != null) {
        images[i] = selectedImages[i];
      }
    }

    try {
      // Kirim request ke API dengan gambar yang sudah difilter
      await ApiService().editPengeluaran(
        parentId,
        tanggalList,
        dataIds,
        names,
        descriptions,
        jumlahs,
        jumlahSatuans,
        nominals,
        dls,
        categoryIds,
        images.whereType<File>().toList(), // Hanya kirim gambar yang tidak null
      );

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data berhasil diperbarui!',
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

      // Refresh halaman dan navigasi
      Navigator.pop(context, true);
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
            'Terjadi kesalahan saat memperbarui data: ${error.toString()}',
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
        forms.removeAt(
            index); // Also remove the corresponding form from the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Form Baru ditambahkan berhasil dihapus!',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(10),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Minimal satu form harus ada!',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    });
  }

  void _addForm() {
    setState(() {
      // Create a new GlobalKey for the new form
      final newFormKey = GlobalKey<_PengeluaranFormState>();
      formKeys.add(newFormKey); // Add the new key to the list
      forms.add(PengeluaranForm(
        key: newFormKey, // Assign the new key to the form
        onRemove: () => _removeForm(forms.length - 1),
        onSubmit: (data) {
          // Handle form submission here if needed
        },
        selectedDate: selectedDate,
        categories: categories, // Pass categories to the new form
        isLast: true, // New form is always last
      ));

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Form baru berhasil ditambahkan!',
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
        SnackBar(
          content: Text(
            'Gagal memuat kategori: $e',
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
                                  'Edit Pengeluaran',
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
                            ListView.separated(
                              padding: EdgeInsets.symmetric(vertical: 1),
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: forms.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                return forms[index];
                              },
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

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () {
        _selectDate(context);
      },
      child: Container(
        height: 35,
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFFEB8153),
                size: 16,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
              ),
              child: Text(
                selectedDate == null
                    ? 'Pilih Tanggal'
                    : '${selectedDate!.day} ${_getMonthName(selectedDate!.month)} ${selectedDate!.year}',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
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

  Future<void> _selectDate(BuildContext context) async {
    // Fungsi ini tidak lagi diperlukan karena field tanggal sekarang readonly
  }
}

class PengeluaranForm extends StatefulWidget {
  final VoidCallback onRemove;
  final Function(List<Map<String, dynamic>>) onSubmit;
  final bool isLast;
  final DateTime? selectedDate;
  final Pengeluaran? pengeluaran;
  final bool isFirst;
  final List<Category> categories;

  const PengeluaranForm({
    Key? key,
    required this.onRemove,
    required this.onSubmit,
    this.isLast = false,
    this.selectedDate,
    this.pengeluaran,
    this.isFirst = false,
    required this.categories,
  }) : super(key: key);
  @override
  _PengeluaranFormState createState() => _PengeluaranFormState();
}

class _PengeluaranFormState extends State<PengeluaranForm> {
  bool showPrefix = false;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController nominalController = TextEditingController();
  final TextEditingController jumlahSatuanController = TextEditingController();
  final TextEditingController dllController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();
  DateTime? selectedDate;
  Category? selectedCategory;
  FilePickerResult? selectedImage;
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();

    if (widget.pengeluaran != null) {
      nameController.text = widget.pengeluaran!.name;
      descriptionController.text = widget.pengeluaran!.description;
      nominalController.text = _formatCurrency(widget.pengeluaran!.nominal);
      jumlahSatuanController.text = widget.pengeluaran!.jumlahSatuan.toString();
      dllController.text = _formatCurrency(widget.pengeluaran!.dll);
      selectedDate = widget.pengeluaran!.tanggal;
      selectedCategory = widget.pengeluaran!.category;
    } else {
      selectedDate = widget.selectedDate;
    }
    _calculateTotal();

    nominalController.addListener(_calculateTotal);
    jumlahSatuanController.addListener(_calculateTotal);
    dllController.addListener(_calculateTotal);

    nominalController.addListener(() {
      setState(() {
        showPrefix = nominalController.text.isNotEmpty;
      });
    });
  }

  void updateDate(DateTime? newDate) {
    setState(() {
      selectedDate = newDate;
    });
  }

  bool validateForm() {
    if (nameController.text.isEmpty) {
      print("Validation Error: Name is empty.");
      return false;
    }

    if (nominalController.text.isEmpty ||
        _parseCurrency(nominalController.text) <= 0) {
      print("Validation Error: Nominal is invalid.");
      return false;
    }

    if (jumlahSatuanController.text.isEmpty ||
        _parseInteger(jumlahSatuanController.text) <= 0) {
      print("Validation Error: Jumlah Satuan is invalid.");
      return false;
    }

    if (selectedCategory == null) {
      print("Validation Error: Category is not selected.");
      return false;
    }

    if (selectedDate == null) {
      print("Validation Error: Date is not selected.");
      return false;
    }

    return true;
  }

  Map<String, dynamic> getFormData() {
    if (!validateForm()) {
      print("Form validation failed.");
      return {};
    }

    String name = nameController.text;
    String description =
        descriptionController.text.isNotEmpty ? descriptionController.text : '';
    int jumlahSatuan = _parseInteger(jumlahSatuanController.text);
    double nominal = _parseCurrency(nominalController.text);
    int jumlah =
        _parseInteger(jumlahController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    double dll = _parseCurrency(dllController.text);

    Map<String, dynamic> formData = {
      'id_data': widget.pengeluaran?.id ?? 0,
      'name': name,
      'description': description,
      'nominal': nominal,
      'jumlah_satuan': jumlahSatuan,
      'jumlah': jumlah,
      'dll': dll,
      'category': selectedCategory?.id,
      'tanggal': selectedDate?.toIso8601String(),
    };

    // Tambahkan data gambar jika ada
    if (selectedImage != null && selectedImage!.files.isNotEmpty) {
      String? imagePath = selectedImage!.files.first.path;
      if (imagePath != null) {
        formData['image'] = File(imagePath);
      }
    }

    print('Form data gathered: $formData');
    return formData;
  }

  double _parseCurrency(String input) {
    String cleanedInput = input.replaceAll('Rp', '').replaceAll('.', '').trim();
    try {
      return double.parse(cleanedInput);
    } catch (e) {
      print("Error parsing currency from '$input': $e");
      return 0.0;
    }
  }

  int _parseInteger(String input) {
    String cleanedInput = input.replaceAll('.', '').trim();
    try {
      return int.parse(cleanedInput);
    } catch (e) {
      print("Error parsing integer from '$input': $e");
      return 0;
    }
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

  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        colorScheme: ColorScheme.light(
          primary: Color(0xFFEB8153),
        ),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        width: screenWidth * 0.95, // Lebih kecil dari screen width
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ExpansionTile(
            title: Text(
              'Edit Pengeluaran',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            collapsedBackgroundColor: Color(0xFFEB8153).withOpacity(0.1),
            backgroundColor: Colors.white,
            initiallyExpanded: true,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInputFields(),
                    SizedBox(height: 12),
                    if (widget.pengeluaran == null && widget.isLast)
                      _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
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
          controller: nameController,
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
            controller: descriptionController,
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

        _buildLabel('Pilih Gambar (Opsional)'),
        SizedBox(height: 4),
        _buildImagePicker(),
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
              controller: jumlahSatuanController,
              keyboardType: TextInputType.number,
              textAlignVertical: TextAlignVertical.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: TextStyle(fontSize: 12),
              onChanged: (value) {
                if (value.isEmpty) {
                  jumlahSatuanController.text = "0";
                  jumlahSatuanController.selection = TextSelection.fromPosition(
                    TextPosition(offset: jumlahSatuanController.text.length),
                  );
                }
                _calculateTotal();
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
                  String currentText = jumlahSatuanController.text.isEmpty
                      ? "0"
                      : jumlahSatuanController.text;
                  int currentValue = int.tryParse(currentText) ?? 0;
                  int newValue = currentValue + 1;
                  jumlahSatuanController.text = newValue.toString();
                  _calculateTotal();
                },
                child: Icon(Icons.arrow_drop_up,
                    color: Color(0xFFEB8153), size: 16),
              ),
              InkWell(
                onTap: () {
                  String currentText = jumlahSatuanController.text.isEmpty
                      ? "0"
                      : jumlahSatuanController.text;
                  int currentValue = int.tryParse(currentText) ?? 0;
                  if (currentValue > 0) {
                    int newValue = currentValue - 1;
                    jumlahSatuanController.text = newValue.toString();
                    _calculateTotal();
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
              controller: jumlahController,
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

  void _calculateTotal() {
    double nominal = _parseCurrency(nominalController.text);
    int satuan = int.tryParse(jumlahSatuanController.text) ?? 0;
    double dll = _parseCurrency(dllController.text);

    if (nominal > 0 && satuan > 0) {
      double total = (nominal * satuan) + dll;
      setState(() {
        jumlahController.text = _formatCurrency(total);
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
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
              controller: dllController,
              keyboardType: TextInputType.number,
              textAlignVertical: TextAlignVertical.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandSeparatorInputFormatter(),
              ],
              style: TextStyle(fontSize: 12),
              onChanged: (value) {
                if (value.isEmpty) {
                  dllController.text = "0";
                  dllController.selection = TextSelection.fromPosition(
                    TextPosition(offset: dllController.text.length),
                  );
                }
                _calculateTotal();
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
                  String currentText = dllController.text.isEmpty
                      ? "0"
                      : dllController.text.replaceAll(RegExp(r'[^0-9]'), '');
                  int currentValue = int.tryParse(currentText) ?? 0;
                  int newValue = currentValue + 1;
                  String formattedValue = NumberFormat('#,###')
                      .format(newValue)
                      .replaceAll(',', '.');
                  dllController.text = formattedValue;
                  _calculateTotal();
                },
                child: Icon(Icons.arrow_drop_up,
                    color: Color(0xFFEB8153), size: 16),
              ),
              InkWell(
                onTap: () {
                  String currentText = dllController.text.isEmpty
                      ? "0"
                      : dllController.text.replaceAll(RegExp(r'[^0-9]'), '');
                  int currentValue = int.tryParse(currentText) ?? 0;
                  if (currentValue > 0) {
                    int newValue = currentValue - 1;
                    String formattedValue = NumberFormat('#,###')
                        .format(newValue)
                        .replaceAll(',', '.');
                    dllController.text = formattedValue;
                    _calculateTotal();
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
              controller: nominalController,
              keyboardType: TextInputType.number,
              textAlignVertical: TextAlignVertical.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandSeparatorInputFormatter(),
              ],
              style: TextStyle(fontSize: 12),
              onChanged: (value) {
                if (value.isEmpty) {
                  nominalController.text = "0";
                  nominalController.selection = TextSelection.fromPosition(
                    TextPosition(offset: nominalController.text.length),
                  );
                }
                _calculateTotal();
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
                  String currentText = nominalController.text.isEmpty
                      ? "0"
                      : nominalController.text
                          .replaceAll(RegExp(r'[^0-9]'), '');
                  int currentValue = int.tryParse(currentText) ?? 0;
                  int newValue = currentValue + 1;
                  String formattedValue = NumberFormat('#,###')
                      .format(newValue)
                      .replaceAll(',', '.');
                  nominalController.text = formattedValue;
                  _calculateTotal();
                },
                child: Icon(Icons.arrow_drop_up,
                    color: Color(0xFFEB8153), size: 16),
              ),
              InkWell(
                onTap: () {
                  String currentText = nominalController.text.isEmpty
                      ? "0"
                      : nominalController.text
                          .replaceAll(RegExp(r'[^0-9]'), '');
                  int currentValue = int.tryParse(currentText) ?? 0;
                  if (currentValue > 0) {
                    int newValue = currentValue - 1;
                    String formattedValue = NumberFormat('#,###')
                        .format(newValue)
                        .replaceAll(',', '.');
                    nominalController.text = formattedValue;
                    _calculateTotal();
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

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool readOnly = false,
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
        style: TextStyle(fontSize: 14),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: _buildPrefixIcon(icon),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildPrefixIcon(IconData icon) {
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
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
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

  Future<void> _pickImage() async {
    try {
      selectedImage = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (selectedImage != null) {
        setState(() {});
      }
    } catch (e) {
      print('Error picking image: $e');
    }
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          enabled: false,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Pilih Tanggal',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEB8153),
              ),
              child: Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 20,
              ),
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: Color(0xFFEB8153),
              size: 30,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 16,
            ),
          ),
          controller: TextEditingController(
            text: selectedDate == null
                ? ''
                : DateFormat('d MMMM yyyy', 'id_ID').format(selectedDate!),
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
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size(80, 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            'Hapus Form',
            style: TextStyle(fontSize: 12),
          ),
        ),
        SizedBox(width: 16),
      ],
    );
  }
}

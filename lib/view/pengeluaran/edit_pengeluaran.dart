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
    List<File> images = [];

    // Dapatkan parent ID dari pengeluaran pertama
    int parentId = widget.pengeluaranList.isNotEmpty
        ? widget.pengeluaranList.first.idParent
        : 0;

    // Format data sesuai dengan response yang diharapkan
    for (var entry in allFormData) {
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

      // Tambahkan gambar jika ada
      if (entry['image'] != null && entry['image'] is File) {
        images.add(entry['image'] as File);
      }
    }

    try {
      // Siapkan list gambar final
      List<File> finalImages = [];
      finalImages.addAll(images);
      finalImages.addAll(selectedImages
          .where((image) => image != null)
          .map((image) => image!));

      // Kirim request ke API
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
        finalImages,
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
          // Header Section
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

          SizedBox(height: 20), // Jarak antara orange dan putih

          // White background container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          _buildDateField(),
                          SizedBox(height: 5),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: forms.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 5),
                            itemBuilder: (context, index) {
                              return forms[index];
                            },
                          ),
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: _addForm,
                              icon: Icon(Icons.add),
                              label: Text('Tambah Pengeluaran'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
      ),
      child: TextField(
        readOnly: true,
        enabled: false,
        decoration: InputDecoration(
          hintText: selectedDate == null
              ? 'Pilih Tanggal'
              : '${selectedDate!.day} ${_getMonthName(selectedDate!.month)} ${selectedDate!.year}',
          hintStyle: TextStyle(color: Colors.black87),
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
              child: Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 15,
          ),
        ),
        onTap: null,
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
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        width: screenWidth * 2, // Double the screen width
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ExpansionTile(
            title: Text(
              'Edit Pengeluaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            collapsedBackgroundColor: Color(0xFFEB8153).withOpacity(0.1),
            backgroundColor: Colors.white,
            initiallyExpanded: true,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInputFields(),
                    SizedBox(height: 20),
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
    bool isLastForm = widget.isLast;

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
        SizedBox(height: 20),
        _buildLabel('Deskripsi'),
        SizedBox(height: 10),
        _buildTextField(
          icon: Icons.format_align_left,
          controller: descriptionController,
          hintText: 'Masukkan Deskripsi',
          maxLines: 5,
          isDescription: true,
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Nominal'),
                  SizedBox(height: 10),
                  _buildNominalTextField(),
                ],
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Jumlah Satuan'),
                  SizedBox(height: 10),
                  _buildJumlahSatuanTextField(),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Biaya Tambahan (DLL)'),
                  SizedBox(height: 10),
                  _buildDllTextField(),
                ],
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Jumlah'),
                  SizedBox(height: 10),
                  _buildJumlahField(),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        _buildLabel('Kategori:'),
        SizedBox(height: 10),
        _buildCategoryDropdown(),
        SizedBox(height: 10),
        if (widget.isLast) _buildLabel('Pilih Gambar:'),
        SizedBox(
          height: 10,
        ),
        if (widget.isLast) _buildImagePicker(),
      ],
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    int? maxLines,
    bool isDescription = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 14),
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.only(
                right: 8.0,
                top: isDescription ? 12.0 : 0,
                left: isDescription ? 12.0 : 0),
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
          contentPadding: EdgeInsets.symmetric(
            vertical: 15,
            horizontal: isDescription ? 15 : 0,
          ),
        ),
      ),
    );
  }

  Widget _buildJumlahSatuanTextField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
      ),
      child: TextField(
        controller: jumlahSatuanController,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 14),
        onChanged: (value) {
          _calculateTotal();
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

  Widget _buildJumlahField() {
    return _buildCustomTextField(
      controller: jumlahController,
      hintText: 'Jumlah total akan dihitung otomatis',
      readOnly: true,
      icon: Icons.receipt,
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
    return _buildCustomTextField(
      controller: dllController,
      hintText: 'Masukkan biaya tambahan (DLL)',
      icon: Icons.attach_money,
      onChanged: (value) {
        String numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
        double amount = double.tryParse(numericValue) ?? 0;
        dllController.value = TextEditingValue(
          text: _formatCurrency(amount),
          selection:
              TextSelection.collapsed(offset: _formatCurrency(amount).length),
        );
        _calculateTotal();
      },
    );
  }

  Widget _buildNominalTextField() {
    return _buildCustomTextField(
      controller: nominalController,
      hintText: 'Masukkan jumlah',
      icon: Icons.money,
      onChanged: (value) {
        String numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
        double amount = double.tryParse(numericValue) ?? 0;
        nominalController.value = TextEditingValue(
          text: _formatCurrency(amount),
          selection:
              TextSelection.collapsed(offset: _formatCurrency(amount).length),
        );
        _calculateTotal();
      },
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
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey[200],
            ),
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 40,
                    width: 40,
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
                      Icons.image,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedImage != null
                        ? 'Pilih gambar: ${selectedImage!.files.first.name}'
                        : 'Pilih gambar dari Galeri',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10),
        if (selectedImage != null && selectedImage!.files.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              File(selectedImage!.files.first.path!),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
      ],
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

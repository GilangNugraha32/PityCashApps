import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pity_cash/models/category_model.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/view/categories/edit_categories.dart';
import 'package:pity_cash/view/categories/tambah_categories.dart';

class CategoriesSection extends StatefulWidget {
  @override
  _CategoriesSectionState createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  final ApiService apiService = ApiService();
  List<Category> categories = []; // List of all categories
  List<Category> filteredCategories = []; // List of filtered categories
  int currentPage = 1;
  bool isLoadingMore = false;
  String? token; // Token variable
  String? name; // User name variable
  bool isLoggedIn = false;
  bool isFetching = false; // Guard variable to prevent multiple fetch requests
  bool hasMoreCategories =
      true; // To track if there are more categories to load

  // Track login status

  final SharedPreferencesService _prefsService = SharedPreferencesService();

  // Controller untuk pencarian
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    filteredCategories = List.from(categories);
    _fetchCategories(currentPage);
    _checkLoginStatus();

    // Menambahkan listener untuk pencarian realtime
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    token = await _prefsService.getToken(); // Retrieve token
    name = await _prefsService.getUserName(); // Retrieve user name
    setState(() {
      isLoggedIn = token != null; // Update login status
    });
  }

  void _onSearchChanged() {
    _filterCategories(_searchController.text);
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCategories = List.from(categories);
      } else {
        filteredCategories = categories.where((category) {
          final nameLower = category.name.toLowerCase();
          final queryLower = query.toLowerCase();
          final jenisKategori =
              category.jenisKategori == 1 ? 'pemasukan' : 'pengeluaran';
          return nameLower.contains(queryLower) ||
              jenisKategori.contains(queryLower);
        }).toList();
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    await _prefsService.removeToken(); // Remove token
    await _prefsService.removeUser(); // Hapus data user
    setState(() {
      isLoggedIn = false; // Update login status
    });
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _fetchCategories(int page) async {
    if (isFetching || !hasMoreCategories)
      return; // Exit if already fetching or no more categories

    setState(() {
      isFetching = true; // Set fetching state to true
      isLoadingMore = true; // Show loading indicator when fetching more
    });

    try {
      // Fetch categories from the server based on the current page
      List<Category> newCategories =
          await ApiService().fetchCategories(page: page);

      if (newCategories.isEmpty) {
        setState(() {
          hasMoreCategories = false; // No more categories to load
        });
      } else {
        // Append only new categories to the filtered list
        setState(() {
          // Filter out duplicates before adding
          newCategories.forEach((category) {
            if (!categories.any(
                (existingCategory) => existingCategory.id == category.id)) {
              categories.add(category);
            }
          });
          _filterCategories(_searchController.text); // Reapply current filter
          currentPage++; // Increment the page for the next load
        });
      }
    } catch (e) {
      // Handle errors if any
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat kategori',
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

    setState(() {
      isFetching = false; // Reset fetching state
      isLoadingMore = false; // Stop showing the loading indicator
    });
  }

  Future<void> _refreshCategoryList() async {
    setState(() {
      currentPage = 1; // Reset to the first page
      categories.clear(); // Clear the existing list
      filteredCategories.clear();
      hasMoreCategories = true; // Reset this for refreshing
      isFetching = false; // Reset fetching state
    });

    // Fetch the first set of categories again
    await _fetchCategories(currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Fixed orange background section
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEB8153), Color(0xFFFF9D6C)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kategori',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    Center(
                      child: Text(
                        'Pilih Kategori',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau jenis kategori...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
              SizedBox(height: 45), // Space between sections

              // Categories List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Buttons in the upper right corner
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0, top: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionButton(
                              Icons.print_outlined,
                              Color(0xFF51A6F5),
                              () {
                                _showExportPDFDialog(context);
                              },
                            ),
                            SizedBox(width: 5),
                            _buildActionButton(
                              Icons.file_download_outlined,
                              Color(0xFF68CF29),
                              () {
                                _showDragAndDropModal(context);
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: LazyLoadScrollView(
                          onEndOfPage: () {
                            _fetchCategories(currentPage);
                          },
                          child: RefreshIndicator(
                            onRefresh: _refreshCategoryList,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: filteredCategories.length +
                                  (isLoadingMore ? 1 : 0),
                              separatorBuilder: (context, index) => Divider(
                                color: Colors.grey[300],
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                if (index == filteredCategories.length) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFEB8153)),
                                    ),
                                  );
                                }
                                final category = filteredCategories[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  leading: Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: category.jenisKategori == 1
                                          ? Color(0xFFE6F7FF)
                                          : Color(0xFFFFE6E6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      category.jenisKategori == 1
                                          ? Icons.trending_up
                                          : Icons.trending_down,
                                      color: category.jenisKategori == 1
                                          ? Colors.blue
                                          : Colors.red,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    category.jenisKategori == 1
                                        ? 'Pemasukan'
                                        : 'Pengeluaran',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: category.jenisKategori == 1
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  trailing: Icon(Icons.chevron_right,
                                      color: Color(0xFFEB8153)),
                                  onTap: () {
                                    _showDetailsModal(context, category.id);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300),
      tween: Tween<double>(begin: 1, end: 0.95),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: color, width: 0.5), // Garis pembatas yang lebih tipis
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: CircleBorder(),
                splashColor: color.withOpacity(0.5),
                highlightColor: color.withOpacity(0.3),
                onTap: onPressed,
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showExportPDFDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Cetak Kategori',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Apakah Anda yakin ingin mengekspor daftar kategori ke PDF?',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Container(
                      width: 120,
                      height: 40,
                      child: ElevatedButton(
                        child: Text(
                          'Batal',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 40,
                      child: ElevatedButton(
                        child: Text('Cetak'),
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFFEB8153),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            final pdfPath =
                                await ApiService().exportCategoryPDF();
                            final downloadsDir =
                                await getExternalStorageDirectory();
                            if (downloadsDir != null) {
                              final fileName = pdfPath.split('/').last;
                              final newPath =
                                  '${downloadsDir.path}/Download/$fileName';
                              await File(pdfPath).copy(newPath);
                              await File(pdfPath).delete();
                              Navigator.of(context)
                                  .pop(); // Menutup dialog setelah berhasil
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'PDF berhasil diekspor ke: $newPath',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
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
                              throw Exception(
                                  'Tidak dapat menemukan direktori Downloads');
                            }
                          } catch (e) {
                            Navigator.of(context)
                                .pop(); // Menutup dialog jika terjadi kesalahan
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gagal mengekspor PDF: $e',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
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
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDragAndDropModal(BuildContext context) {
    String? selectedFilePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Import Data Kategori',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'File Excel yang diunggah',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: _buildDragAndDropZone(
                      context,
                      selectedFilePath,
                      (String? filePath) {
                        setState(() {
                          selectedFilePath = filePath;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        try {
                          String filePath =
                              await apiService.downloadCategoryTemplate();
                          Directory? downloadsDirectory =
                              await getExternalStorageDirectory();
                          if (downloadsDirectory != null) {
                            String fileName = 'template_kategori.xlsx';
                            String savePath =
                                '${downloadsDirectory.path}/Download/$fileName';
                            await Directory(
                                    '${downloadsDirectory.path}/Download')
                                .create(recursive: true);
                            await File(filePath).copy(savePath);
                            await File(filePath).delete();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Template berhasil diunduh: $savePath',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
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
                            throw Exception(
                                'Tidak dapat menemukan folder Download');
                          }
                        } catch (e) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Gagal mengunduh template: $e',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
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
                      },
                      child: Text(
                        'Download Template Excel',
                        style: TextStyle(color: Color(0xFFEB8153)),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: selectedFilePath != null
                        ? () async {
                            try {
                              final response = await ApiService()
                                  .importCategoryFromExcel(selectedFilePath!);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Data berhasil diimpor',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: EdgeInsets.all(10),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              _showImportedDataDialog(context, response);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal mengimpor kategori: $e',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
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
                        : null,
                    child: Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFEB8153),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: MediaQuery.of(context).size.width * 0.2,
                      ),
                      minimumSize: Size(double.infinity, 0),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showImportedDataDialog(
      BuildContext context, List<dynamic> importedData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Column(
            children: [
              Text(
                'Data Kategori Berhasil di Import',
                style: TextStyle(
                  color: Color(0xFFEB8153),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Divider(
                color: Color(0xFFEB8153),
                thickness: 2,
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: importedData.length,
              itemBuilder: (context, index) {
                final data = importedData[index];
                return Card(
                  elevation: 0,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Color(0xFFEB8153), width: 1.5),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFFFFF5EE),
                          radius: 25,
                          child: Text(
                            data['Nama'][0],
                            style: TextStyle(
                              color: Color(0xFFEB8153),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['Nama'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFFEB8153),
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Jenis Kategori: ${data['Jenis Kategori'] == 1 ? 'Pemasukan' : 'Pengeluaran'}',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Deskripsi: ${data['Deskripsi'] as String}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text(
                'Tutup',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFEB8153),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDragAndDropZone(
    BuildContext context,
    String? selectedFilePath,
    Function(String?) onFileSelected,
  ) {
    return InkWell(
      onTap: () => _pickFile(context, onFileSelected),
      child: Container(
        height: 175,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFEB8153)),
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.grey[200],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined,
                  size: 40, color: Color(0xFFEB8153)),
              SizedBox(height: 10),
              Text(
                selectedFilePath != null
                    ? 'File terpilih: ${selectedFilePath.split('/').last}'
                    : 'Drag and drop your files here\nor click to upload, xlsx or xls',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickFile(BuildContext context, Function(String?) onFileSelected) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      onFileSelected(file.path);
    }
  }

  void _importFile(BuildContext context, String filePath) async {
    try {
      final response = await apiService.importCategoryFromExcel(filePath);
      // Menghapus peringatan tentang jumlah data yang diimpor
      _showImportedDataDialog(context, response);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengimpor kategori: $e')),
      );
    }
  }

  void _showDetailsModal(BuildContext context, int categoryId) async {
    Category category;
    try {
      category = await ApiService().fetchCategoryDetail(categoryId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail kategori: $e')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Kategori',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 4, right: 4),
                            padding: EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFF5EE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.category_outlined,
                                    color: Color(0xFFEB8153),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nama Kategori',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        category.name,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 4, left: 8),
                            padding: EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFF5EE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.type_specimen_outlined,
                                    color: Color(0xFFEB8153),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Jenis Kategori',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        category.jenisKategori == 1
                                            ? 'Pemasukan'
                                            : 'Pengeluaran',
                                        style: TextStyle(fontSize: 14),
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
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFF5EE),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: Color(0xFFEB8153),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Deskripsi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  category.description,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _confirmDelete(context, category.id);
                    },
                    icon: Icon(Icons.delete_outline, size: 18),
                    label: Text(
                      'Hapus',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFDA0000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      minimumSize: Size(95, 36),
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditCategories(
                                  category: category,
                                  onUpdate: _refreshCategoryList,
                                )),
                      );
                    },
                    icon: Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFE85C0D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      minimumSize: Size(95, 36),
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

// Fungsi untuk menampilkan dialog konfirmasi hapus
  void _confirmDelete(BuildContext context, int categoryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'Konfirmasi Hapus',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFE85C0D),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16),
              Text(
                'Apakah Anda yakin ingin menghapus kategori ini?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.grey, // Warna abu-abu untuk background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await apiService.deleteCategory(categoryId);
                  Navigator.of(context).pop(); // Tutup dialog konfirmasi
                  Navigator.of(context).pop(); // Tutup modal sheet
                  _refreshCategoryList();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Kategori berhasil dihapus',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.all(10),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop(); // Tutup dialog konfirmasi
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus kategori: $e',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
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
              },
              child: Text('Hapus'),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFDA0000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}// Fungsi untuk menghapus kategori


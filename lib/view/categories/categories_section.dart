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
  String selectedFilter = 'Semua'; // Default filter

  // Track login status

  final SharedPreferencesService _prefsService = SharedPreferencesService();

  // Controller untuk pencarian
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    filteredCategories = List.from(categories);
    _fetchCategories(currentPage, 10);
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

  Future<void> _fetchCategories(int page, int itemsPerLoad) async {
    if (isFetching || !hasMoreCategories)
      return; // Exit if already fetching or no more categories

    setState(() {
      isFetching = true; // Set fetching state to true
      isLoadingMore = true; // Show loading indicator when fetching more
    });

    try {
      // Fetch categories from the server based on the current page
      List<Category> newCategories = await ApiService().fetchCategories();

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

        // Simpan roles menggunakan SharedPreferencesService
        final roles = await _prefsService.getRoles();
        if (roles != null) {
          print('Roles yang ditemukan: $roles'); // Print roles untuk debugging
          await _prefsService.saveRoles(roles);
          print('Roles berhasil disimpan'); // Konfirmasi penyimpanan
        } else {
          print('Roles tidak ditemukan'); // Print jika roles null
        }
      }
    } catch (e) {
      // Handle errors if any
      print('Error saat memuat kategori: $e'); // Print error jika terjadi
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
    await _fetchCategories(currentPage, 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                // Fixed orange background section
                Container(
                  width: double.infinity,
                  constraints:
                      BoxConstraints(maxHeight: 250), // Batasi tinggi maksimal
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
                    children: [
                      // Background pattern dengan ukuran relatif
                      Positioned(
                        right: -20,
                        bottom: -15,
                        child: Icon(
                          Icons.insert_chart_outlined_rounded,
                          size: 100, // Ukuran tetap
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      Positioned(
                        left: -15,
                        top: 15,
                        child: Icon(
                          Icons.interests_outlined,
                          size: 60, // Ukuran tetap
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      // Content dengan padding yang konsisten
                      Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.interests_outlined,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Kategori',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Pilih Kategori',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Container(
                              height: 36,
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Cari nama atau jenis kategori...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                  ),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                    size: 14,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Categories List
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16.0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Buttons in the upper right corner
                        FutureBuilder<Map<String, dynamic>?>(
                          future: SharedPreferencesService().getRoles(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final roles = snapshot.data?['roles'] as List;
                              bool isReaderOnly = roles.length == 1 &&
                                  roles[0]['name'] == 'Reader';

                              if (!isReaderOnly) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      right: 14.0, top: 14.0, left: 14.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Filter dropdown
                                      Container(
                                        width: 150,
                                        height: 32,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                          borderRadius:
                                              BorderRadius.circular(6.0),
                                        ),
                                        child: Theme(
                                          data: Theme.of(context).copyWith(
                                            canvasColor: Colors.white,
                                            // Memastikan dropdown muncul di bawah
                                            popupMenuTheme:
                                                PopupMenuThemeData(),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: selectedFilter,
                                              isExpanded: true,
                                              isDense: true,
                                              itemHeight: 48,
                                              icon: Icon(Icons.arrow_drop_down,
                                                  color: Color(0xFFEB8153)),
                                              dropdownColor: Colors.white,
                                              // Memaksa dropdown muncul di bawah
                                              menuMaxHeight: 300,
                                              // Mengatur posisi dropdown
                                              alignment: AlignmentDirectional
                                                  .bottomStart,
                                              items: [
                                                DropdownMenuItem<String>(
                                                  value: 'Semua',
                                                  child: Container(
                                                    constraints: BoxConstraints(
                                                        minWidth: 150),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.list_alt,
                                                            size: 16,
                                                            color: Color(
                                                                0xFFEB8153)),
                                                        SizedBox(width: 8),
                                                        Flexible(
                                                          child: Text(
                                                            'Semua',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .black87,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem<String>(
                                                  value: 'Pemasukan',
                                                  child: Container(
                                                    constraints: BoxConstraints(
                                                        minWidth: 150),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .arrow_downward,
                                                            size: 16,
                                                            color:
                                                                Colors.green),
                                                        SizedBox(width: 8),
                                                        Flexible(
                                                          child: Text(
                                                            'Pemasukan',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .black87,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem<String>(
                                                  value: 'Pengeluaran',
                                                  child: Container(
                                                    constraints: BoxConstraints(
                                                        minWidth: 150),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.arrow_upward,
                                                            size: 16,
                                                            color: Colors.red),
                                                        SizedBox(width: 8),
                                                        Flexible(
                                                          child: Text(
                                                            'Pengeluaran',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .black87,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedFilter = newValue!;
                                                  if (selectedFilter ==
                                                      'Semua') {
                                                    filteredCategories =
                                                        List.from(categories);
                                                  } else if (selectedFilter ==
                                                      'Pemasukan') {
                                                    filteredCategories = categories
                                                        .where((category) =>
                                                            category
                                                                .jenisKategori ==
                                                            1)
                                                        .toList();
                                                  } else if (selectedFilter ==
                                                      'Pengeluaran') {
                                                    filteredCategories = categories
                                                        .where((category) =>
                                                            category
                                                                .jenisKategori ==
                                                            2)
                                                        .toList();
                                                  }
                                                  if (_searchController
                                                      .text.isNotEmpty) {
                                                    _filterCategories(
                                                        _searchController.text);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Action buttons
                                      Row(
                                        children: [
                                          _buildActionButton(
                                            Icons.print_outlined,
                                            Color(0xFF51A6F5),
                                            () {
                                              _showExportPDFDialog(context);
                                            },
                                          ),
                                          SizedBox(width: 4),
                                          _buildActionButton(
                                            Icons.file_upload_outlined,
                                            Color(0xFF68CF29),
                                            () {
                                              _showDragAndDropModal(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                            return SizedBox.shrink();
                          },
                        ),
                        Expanded(
                          child: LazyLoadScrollView(
                            onEndOfPage: () {
                              if (!isFetching) {
                                // Batasi jumlah data yang dimuat per scroll
                                final itemsPerLoad = 10;
                                _fetchCategories(currentPage, itemsPerLoad);
                              }
                            },
                            child: RefreshIndicator(
                              onRefresh: _refreshCategoryList,
                              child: ListView.separated(
                                physics: AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.only(
                                    bottom: 100), // Padding bawah diperbesar
                                itemCount: filteredCategories.length +
                                    (isLoadingMore ? 1 : 0),
                                separatorBuilder: (context, index) => Divider(
                                  color: Colors.grey[300],
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  // Muat data berikutnya saat mendekati akhir list
                                  if (index >= filteredCategories.length - 5 &&
                                      !isFetching) {
                                    _fetchCategories(currentPage, 10);
                                  }

                                  if (index == filteredCategories.length) {
                                    return Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.0,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0xFFEB8153)),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  // Sort categories - lowercase first, then uppercase, for all letters
                                  filteredCategories.sort((a, b) {
                                    String aLower = a.name.toLowerCase();
                                    String bLower = b.name.toLowerCase();

                                    // If same letter but different case
                                    if (aLower[0] == bLower[0]) {
                                      if (a.name[0].toLowerCase() ==
                                              a.name[0] &&
                                          b.name[0].toUpperCase() ==
                                              b.name[0]) {
                                        return -1;
                                      }
                                      if (a.name[0].toUpperCase() ==
                                              a.name[0] &&
                                          b.name[0].toLowerCase() ==
                                              b.name[0]) {
                                        return 1;
                                      }
                                    }

                                    // Otherwise sort alphabetically
                                    return aLower.compareTo(bLower);
                                  });

                                  final category = filteredCategories[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    leading: Container(
                                      padding: EdgeInsets.all(6),
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
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      category.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      category.jenisKategori == 1
                                          ? 'Pemasukan'
                                          : 'Pengeluaran',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: category.jenisKategori == 1
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    trailing: Icon(Icons.chevron_right,
                                        color: Color(0xFFEB8153), size: 18),
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
          ),
        ),
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
            width: 45, // Ukuran dikurangi dari 52
            height: 45, // Ukuran dikurangi dari 52
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 0.5),
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
                  size: 24, // Ukuran icon dikurangi dari 28
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
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4.0,
                  offset: const Offset(0.0, 4.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Cetak Kategori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Apakah Anda yakin ingin mengekspor daftar kategori ke PDF?',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Container(
                      width: 80,
                      height: 30,
                      child: ElevatedButton(
                        child: Text(
                          'Batal',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 30,
                      child: ElevatedButton(
                        child: Text('Cetak', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFFEB8153),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
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
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'PDF berhasil diekspor ke: $newPath',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11),
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  margin: EdgeInsets.all(6),
                                ),
                              );
                            } else {
                              throw Exception(
                                  'Tidak dapat menemukan direktori Downloads');
                            }
                          } catch (e) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gagal mengekspor PDF: $e',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                margin: EdgeInsets.all(6),
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
          top: Radius.circular(12.0),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(12.0),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey, size: 20),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'File Excel yang diunggah',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: _buildDragAndDropZone(
                      context,
                      selectedFilePath,
                      (String? filePath) {
                        setState(() {
                          print("apapa");
                          print(filePath.toString());
                          selectedFilePath = filePath;

                          print("cek " + selectedFilePath.toString());
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16),
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
                                      color: Colors.white, fontSize: 12),
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                margin: EdgeInsets.all(8),
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
                                    color: Colors.white, fontSize: 12),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: EdgeInsets.all(8),
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Download Template Excel',
                        style:
                            TextStyle(color: Color(0xFFEB8153), fontSize: 12),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
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
                                        color: Colors.white, fontSize: 12),
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: EdgeInsets.all(8),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              _showImportedDataDialog(context, response);
                            } catch (e) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$e',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: EdgeInsets.all(8),
                                ),
                              );
                            }
                          }
                        : null,
                    child: Text('Upload', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFEB8153),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: MediaQuery.of(context).size.width * 0.15,
                      ),
                      minimumSize: Size(double.infinity, 0),
                    ),
                  ),
                  SizedBox(height: 8),
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
    if (importedData == null || importedData.isEmpty) {
      // Handle kasus ketika data kosong atau null
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak ada data yang diimpor',
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
                // Validasi data sebelum mengakses
                if (data == null ||
                    !data.containsKey('Nama') ||
                    !data.containsKey('Jenis Kategori') ||
                    !data.containsKey('Deskripsi')) {
                  return SizedBox.shrink(); // Skip item jika data tidak valid
                }

                final nama = data['Nama'] as String? ?? 'Tidak ada nama';
                final jenisKategori = data['Jenis Kategori'];
                final deskripsi =
                    data['Deskripsi'] as String? ?? 'Tidak ada deskripsi';

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
                            nama.isNotEmpty ? nama[0] : '?',
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
                                nama,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFFEB8153),
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Jenis Kategori: ${jenisKategori == 1 ? 'Pemasukan' : 'Pengeluaran'}',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Deskripsi: $deskripsi',
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
        height: 130, // Dikurangi lagi dari 150
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFEB8153)),
          borderRadius: BorderRadius.circular(5.0), // Dikurangi lagi dari 6.0
          color: Colors.grey[200],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined,
                  size: 28, color: Color(0xFFEB8153)), // Dikurangi lagi dari 32
              SizedBox(height: 6), // Dikurangi lagi dari 8
              Text(
                selectedFilePath != null
                    ? 'File terpilih: ${selectedFilePath.split('/').last}'
                    : 'Drag and drop your files here\nor click to upload, xlsx or xls',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey), // Dikurangi lagi dari 14
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
      setState(() {
        PlatformFile file = result.files.first;

        print("filr " + file.toString());

        onFileSelected(file.path);
      });
    }
  }

  void _importFile(BuildContext context, String filePath) async {
    try {
      final response = await apiService.importCategoryFromExcel(filePath);
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
          top: Radius.circular(14.0), // Dikurangi lagi dari 16.0
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0), // Dikurangi lagi dari 20.0
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(14.0), // Dikurangi lagi dari 16.0
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
                      fontSize: 18, // Dikurangi lagi dari 20
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: Colors.grey, size: 18), // Dikurangi lagi dari 20
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              SizedBox(height: 10), // Dikurangi lagi dari 12
              Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 3, right: 3),
                            padding:
                                EdgeInsets.all(8.0), // Dikurangi lagi dari 10.0
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                  5.0), // Dikurangi lagi dari 6.0
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(
                                      6), // Dikurangi lagi dari 8
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFF5EE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.category_outlined,
                                    color: Color(0xFFEB8153),
                                    size: 18, // Dikurangi lagi dari 20
                                  ),
                                ),
                                SizedBox(width: 10), // Dikurangi lagi dari 12
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nama Kategori',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              12, // Dikurangi lagi dari 14
                                        ),
                                      ),
                                      SizedBox(
                                          height: 4), // Dikurangi lagi dari 6
                                      Text(
                                        category.name,
                                        style: TextStyle(
                                            fontSize:
                                                11), // Dikurangi lagi dari 12
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
                            margin: EdgeInsets.only(
                                bottom: 3, left: 5), // Dikurangi lagi dari 6
                            padding:
                                EdgeInsets.all(8.0), // Dikurangi lagi dari 10.0
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                  5.0), // Dikurangi lagi dari 6.0
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(
                                      6), // Dikurangi lagi dari 8
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFF5EE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.type_specimen_outlined,
                                    color: Color(0xFFEB8153),
                                    size: 18, // Dikurangi lagi dari 20
                                  ),
                                ),
                                SizedBox(width: 10), // Dikurangi lagi dari 12
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Jenis Kategori',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              12, // Dikurangi lagi dari 14
                                        ),
                                      ),
                                      SizedBox(
                                          height: 4), // Dikurangi lagi dari 6
                                      Text(
                                        category.jenisKategori == 1
                                            ? 'Pemasukan'
                                            : 'Pengeluaran',
                                        style: TextStyle(
                                            fontSize:
                                                11), // Dikurangi lagi dari 12
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
                      margin: EdgeInsets.only(top: 8), // Dikurangi lagi dari 10
                      padding: EdgeInsets.all(8.0), // Dikurangi lagi dari 10.0
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            5.0), // Dikurangi lagi dari 6.0
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6), // Dikurangi lagi dari 8
                            decoration: BoxDecoration(
                              color: Color(0xFFFFF5EE),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: Color(0xFFEB8153),
                              size: 18, // Dikurangi lagi dari 20
                            ),
                          ),
                          SizedBox(width: 10), // Dikurangi lagi dari 12
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Deskripsi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12, // Dikurangi lagi dari 14
                                  ),
                                ),
                                SizedBox(height: 4), // Dikurangi lagi dari 6
                                Text(
                                  category.description,
                                  style: TextStyle(
                                      fontSize: 11), // Dikurangi lagi dari 12
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
              SizedBox(height: 10), // Dikurangi lagi dari 12
              FutureBuilder<Map<String, dynamic>?>(
                future: SharedPreferencesService().getRoles(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    bool isReader =
                        snapshot.data!['roles'][0]['name'] == 'Reader';
                    if (isReader) {
                      return Container();
                    }
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _confirmDelete(context, category.id);
                        },
                        child: Text(
                          'Hapus',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11, // Dikurangi lagi dari 12
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFFDA0000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                5.0), // Dikurangi lagi dari 6.0
                          ),
                          minimumSize:
                              Size(75, 28), // Dikurangi lagi dari 85, 32
                          padding: EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 10), // Dikurangi lagi dari 6, 12
                        ),
                      ),
                      SizedBox(width: 5), // Dikurangi lagi dari 6
                      ElevatedButton(
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
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11, // Dikurangi lagi dari 12
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFFE85C0D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                5.0), // Dikurangi lagi dari 6.0
                          ),
                          minimumSize:
                              Size(75, 28), // Dikurangi lagi dari 85, 32
                          padding: EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 10), // Dikurangi lagi dari 6, 12
                        ),
                      ),
                    ],
                  );
                },
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


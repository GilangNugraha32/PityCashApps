import 'package:flutter/material.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
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
  bool isLoggedIn = false; // Track login status

  final SharedPreferencesService _prefsService = SharedPreferencesService();

  @override
  void initState() {
    super.initState();
    filteredCategories = List.from(categories);
    _fetchCategories(currentPage);
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    token = await _prefsService.getToken(); // Retrieve token
    name = await _prefsService.getUserName(); // Retrieve user name
    setState(() {
      isLoggedIn = token != null; // Update login status
    });
  }

  void _filterCategories(String query) {
    if (categories.isEmpty) return; // Ensure categories are not empty
    setState(() {
      if (query.isEmpty) {
        filteredCategories = List.from(categories);
      } else {
        filteredCategories = categories.where((category) {
          return category.name.toLowerCase().contains(query.toLowerCase());
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
    if (isLoadingMore) return;
    setState(() {
      isLoadingMore = true;
    });

    try {
      final newCategories = await apiService.fetchCategories(page: page);
      setState(() {
        categories.addAll(newCategories);
        filteredCategories = List.from(
            categories); // Reset filtered list after fetching new data
        currentPage++;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
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
                  color: Color(0xFFEB8153),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(16.0),
                    bottomLeft: Radius.circular(16.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isLoggedIn ? 'Hi, $name!' : 'Hi, Guest!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
                        'Select Category',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        onChanged: _filterCategories,
                        decoration: InputDecoration(
                          hintText: 'Cari...',
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
                  padding: const EdgeInsets.all(16.0),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircleAvatar(
                              backgroundColor: Color(0xFF51A6F5),
                              child: IconButton(
                                icon: Icon(Icons.print_outlined),
                                color: Colors.white,
                                iconSize: 28,
                                onPressed: () {
                                  // Add your print action here
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircleAvatar(
                              backgroundColor: Color(0xFF68CF29),
                              child: IconButton(
                                icon: Icon(Icons.arrow_circle_down_sharp),
                                color: Colors.white,
                                iconSize: 28,
                                onPressed: () {
                                  // Add your download action here
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10), // Spacing between buttons and list
                      Expanded(
                        child: LazyLoadScrollView(
                          onEndOfPage: () {
                            _fetchCategories(
                                currentPage); // Load more categories
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.all(0),
                            itemCount: filteredCategories.length +
                                (isLoadingMore
                                    ? 1
                                    : 0), // Show loading indicator if loading more
                            separatorBuilder: (context, index) => Divider(),
                            itemBuilder: (context, index) {
                              if (index == filteredCategories.length) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                ); // Loading indicator
                              }
                              final category = filteredCategories[
                                  index]; // Use filtered categories
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Color(0xFFEB8153),
                                  child: Icon(Icons.monetization_on_outlined,
                                      color: Colors.white),
                                ),
                                title: Text(category.name,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  category.jenisKategori == 1
                                      ? 'Pemasukan'
                                      : 'Pengeluaran',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[600]),
                                ),
                                onTap: () {
                                  _showDetailsModal(context, category.id);
                                },
                              );
                            },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahCategories(),
            ),
          );
        },
        backgroundColor: Colors.orange,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showDetailsModal(BuildContext context, int categoryId) async {
    // Ambil detail kategori menggunakan fetchCategoryDetail
    Category category;
    try {
      category = await ApiService().fetchCategoryDetail(categoryId);
    } catch (e) {
      // Tampilkan pesan kesalahan jika gagal mengambil detail
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail kategori: $e')),
      );
      return; // Keluarkan dari fungsi jika terjadi kesalahan
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      builder: (BuildContext context) {
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
                    'Detail Category',
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
              Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 4, right: 4),
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.category, color: Colors.grey),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Category Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      TextFormField(
                                        initialValue: category.name,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                        ),
                                        enabled: false,
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
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.type_specimen, color: Colors.grey),
                                SizedBox(width: 2),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Category Jenis',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      TextFormField(
                                        initialValue:
                                            category.jenisKategori == 1
                                                ? 'Pemasukan'
                                                : 'Pengeluaran',
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                        ),
                                        enabled: false,
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
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.description, color: Colors.grey),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                TextFormField(
                                  initialValue: category.description,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  enabled: false,
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
                  ElevatedButton(
                    onPressed: () {
                      _confirmDelete(context,
                          category.id); // Panggil fungsi konfirmasi hapus
                    },
                    child: Text(
                      'Hapus',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFDA0000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditCategories(category: category),
                        ),
                      );
                    },
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFE85C0D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus kategori ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await apiService
                      .deleteCategory(categoryId); // Panggil fungsi hapus
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.of(context).pop(); // Tutup modal
                  // Tambahkan logika untuk memperbarui tampilan setelah penghapusan
                  // Misalnya, panggil setState atau refresh daftar kategori
                } catch (e) {
                  // Tampilkan pesan kesalahan jika terjadi
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus kategori: $e')),
                  );
                }
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
// Fungsi untuk menghapus kategori

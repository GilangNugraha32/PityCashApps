import 'package:file_picker/file_picker.dart';
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
  bool isLoggedIn = false;
  bool isFetching = false; // Guard variable to prevent multiple fetch requests
  bool hasMoreCategories =
      true; // To track if there are more categories to load

  // Track login status

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
            if (!filteredCategories.any(
                (existingCategory) => existingCategory.id == category.id)) {
              filteredCategories.add(category);
            }
          });
          currentPage++; // Increment the page for the next load
        });
      }
    } catch (e) {
      // Handle errors if any
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories')),
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
      filteredCategories.clear(); // Clear the existing list
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
                          'Category',
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
                                  _showDragAndDropModal(context);
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
                                currentPage); // Load more categories when reaching the end
                          },
                          child: RefreshIndicator(
                            onRefresh:
                                _refreshCategoryList, // Pull down to refresh the list
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
                                  ); // Show a loading indicator when loading more categories
                                }
                                final category = filteredCategories[
                                    index]; // Use filtered categories
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Color(0xFFEB8153),
                                    child: Icon(Icons.monetization_on_outlined,
                                        color: Colors.white),
                                  ),
                                  title: Text(
                                    category.name,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahCategories(),
            ),
          );
          if (result == 'success') {
            _refreshCategoryList(); // Refresh the list if a category was successfully added
          }
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

  void _showDragAndDropModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Modal appears from top
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
              SizedBox(height: 10), // Space between the gray text and the zone
              Center(
                child: _buildDragAndDropZone(), // Custom drag-and-drop zone
              ),
              SizedBox(height: 20), // Space between zone and template text
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    // Function to download the template Excel can be added here later
                  },
                  child: Text(
                    'Download Template Excel',
                    style: TextStyle(
                        color:
                            Color(0xFFEB8153)), // Changed color for visibility
                  ),
                ),
              ),
              SizedBox(height: 10), // Space between template text and button
              ElevatedButton(
                onPressed: () {
                  _pickFile(); // Call the function to pick a file
                },
                child: Text('Upload'),
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFFEB8153), // Background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: MediaQuery.of(context).size.width *
                        0.2, // Adjust padding for the button
                  ),
                  minimumSize: Size(double.infinity, 0), // Full width button
                ),
              ),
              SizedBox(height: 10), // Space at the bottom of the modal
            ],
          ),
        );
      },
    );
  }

// Widget for the drag and drop zone
  Widget _buildDragAndDropZone() {
    return InkWell(
      onTap: _pickFile, // Action to pick a file when tapped
      child: Container(
        height: 175, // Height of the drop zone
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFEB8153)),
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.grey[200], // Background color for the drop zone
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined,
                  size: 40, color: Color(0xFFEB8153)),
              SizedBox(height: 10),
              Text(
                'Drag and drop your files here\nor click to upload, xlsx or xls',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

// Function to pick files
  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'], // Allow only Excel files
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      print('File picked: ${file.name}'); // Display picked file name
      // You can now upload the file to the server or do other actions.
    } else {
      // User canceled the picker
    }
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
                    'Detail Kategori',
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
                                        'Nama Kategori',
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
                                        'Jenis Kategori',
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
                                  'Deskripsi',
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
                      Navigator.pop(context); // Close the modal first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditCategories(
                                  category: category,
                                  onUpdate: _refreshCategoryList,
                                ) // Pass the refresh function
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
                      .deleteCategory(categoryId); // Call delete function
                  Navigator.of(context).pop(); // Close the confirmation dialog
                  Navigator.of(context).pop(); // Close the modal sheet

                  // Call refresh function to reload the updated category list
                  _refreshCategoryList();

                  // Optionally, you can also show a success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kategori berhasil dihapus')),
                  );
                } catch (e) {
                  // Show error message if deletion fails
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

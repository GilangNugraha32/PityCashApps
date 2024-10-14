import 'package:flutter/material.dart';
import 'package:pity_cash/models/category_model.dart';
import 'package:pity_cash/service/api_service.dart';

class EditCategories extends StatefulWidget {
  final Category category;
  final VoidCallback onUpdate; // Callback for refresh

  EditCategories({required this.category, required this.onUpdate});
  @override
  _EditCategoriesState createState() => _EditCategoriesState();
}

class _EditCategoriesState extends State<EditCategories> {
  final _formKey = GlobalKey<FormState>();
  late String _namaKategori;
  late int _jenisKategori;
  late String _deskripsi;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _namaKategori = widget.category.name;
    _jenisKategori = widget.category.jenisKategori;
    _deskripsi = widget.category.description;
  }

  Future<void> _updateCategory() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _apiService.updateCategory(
          widget.category.id,
          _namaKategori,
          _jenisKategori,
          _deskripsi,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category updated successfully!')),
        );
        widget.onUpdate(); // Call the refresh method after successful update

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height / 3.6,
            decoration: BoxDecoration(
              color: Color(0xFFEB8153),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(16.0),
                bottomLeft: Radius.circular(16.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Edit Kategori',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Menyembunyikan ID Kategori
                  SizedBox(height: 12),
                  // Text(
                  //   'ID Kategori: ${widget.category.id}',
                  //   style: TextStyle(
                  //     fontSize: 16,
                  //     color: Colors.white,
                  //   ),
                  // ),
                  // SizedBox(height: 12),
                  Spacer(),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nama Kategori',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        TextFormField(
                          initialValue: _namaKategori,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nama kategori',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a category name';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _namaKategori = value;
                          },
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Jenis Kategori',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          value: _jenisKategori,
                          decoration: InputDecoration(
                            hintText: 'Pilih jenis kategori',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 1, child: Text('Pemasukan')),
                            DropdownMenuItem(
                                value: 2, child: Text('Pengeluaran')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _jenisKategori = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a category type';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Deskripsi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        TextFormField(
                          initialValue: _deskripsi,
                          decoration: InputDecoration(
                            hintText: 'Masukkan deskripsi kategori',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _deskripsi = value;
                          },
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Cancel'),
                              style: ElevatedButton.styleFrom(
                                primary: Color(0xFFDA0000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _updateCategory,
                              child: Text('Submit'),
                              style: ElevatedButton.styleFrom(
                                primary: Color(0xFFE85C0D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
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
        ],
      ),
    );
  }
}

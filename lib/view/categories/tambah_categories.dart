import 'package:flutter/material.dart';
import 'package:pity_cash/models/category_model.dart';
import 'package:pity_cash/service/api_service.dart';

class TambahCategories extends StatefulWidget {
  @override
  _TambahCategoriesState createState() => _TambahCategoriesState();
}

class _TambahCategoriesState extends State<TambahCategories> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  int? selectedJenisKategori;
  final ApiService apiService = ApiService();

  final List<Map<String, dynamic>> jenisKategoriOptions = [
    {'label': 'Pemasukan', 'value': 1},
    {'label': 'Pengeluaran', 'value': 2},
  ];

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
                      'Tambah Kategori',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nama Kategori',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      TextField(
                        controller: nameController,
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
                      ),
                      SizedBox(height: 6),
                      Text('Jenis Kategori',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: selectedJenisKategori,
                        onChanged: (int? newValue) {
                          setState(() {
                            selectedJenisKategori = newValue;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: jenisKategoriOptions.map((option) {
                          return DropdownMenuItem<int>(
                            value: option['value'],
                            child: Text(option['label']),
                          );
                        }).toList(),
                        hint: Text('Pilih jenis kategori'),
                      ),
                      SizedBox(height: 6),
                      Text('Deskripsi',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      TextField(
                        controller: descriptionController,
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
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Navigate back
                            },
                            child: Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              primary: Color(0xFFDA0000), // Red color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              String name = nameController.text;
                              String description = descriptionController.text;

                              // Check if the required fields are not empty
                              if (name.isNotEmpty &&
                                  selectedJenisKategori != null) {
                                try {
                                  // Call the createCategory function from ApiService
                                  await ApiService().createCategory(
                                    name,
                                    selectedJenisKategori!, // Ensure this is not null
                                    description,
                                  );

                                  // Show a Snackbar if the category is successfully added
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Kategori berhasil ditambahkan')),
                                  );

                                  // Navigate back to the previous screen and pass 'success' as a result
                                  Navigator.pop(context,
                                      'success'); // Pass a result to the previous page
                                } catch (e) {
                                  // Show an error message if there's an issue
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Gagal menambahkan kategori')),
                                  );
                                }
                              } else {
                                // Show an error message if any field is empty
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Please fill all fields')),
                                );
                              }
                            },
                            child: Text('Submit'),
                            style: ElevatedButton.styleFrom(
                              primary: Color(0xFFE85C0D), // Orange color
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
        ],
      ),
    );
  }
}

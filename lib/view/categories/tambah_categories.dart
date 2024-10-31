import 'package:flutter/material.dart';
import 'package:pity_cash/models/category_model.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/view/home/home.dart';

class TambahCategories extends StatefulWidget {
  final VoidCallback? onUpdate;

  const TambahCategories({
    Key? key,
    this.onUpdate,
  }) : super(key: key);

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
            decoration: BoxDecoration(
              color: Color(0xFFEB8153),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(24.0),
                bottomLeft: Radius.circular(24.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  SizedBox(height: 24),
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
                      Container(
                        height: 50,
                        child: TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nama kategori',
                            hintStyle: TextStyle(fontSize: 16),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                  color: Color(0xFFEB8153), width: 2.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            prefixIcon: Icon(Icons.category_outlined,
                                color: Color(0xFFEB8153)),
                          ),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('Jenis Kategori',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Container(
                        height: 50,
                        child: DropdownButtonFormField<int>(
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
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(
                                  color: Color(0xFFEB8153), width: 2.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            prefixIcon:
                                Icon(Icons.list, color: Color(0xFFEB8153)),
                          ),
                          items: jenisKategoriOptions.map((option) {
                            return DropdownMenuItem<int>(
                              value: option['value'],
                              child: Text(option['label'],
                                  style: TextStyle(fontSize: 16)),
                            );
                          }).toList(),
                          hint: Text('Pilih jenis kategori',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('Deskripsi',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan deskripsi kategori',
                          hintStyle: TextStyle(fontSize: 16),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: Color(0xFFEB8153), width: 2.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 8.0),
                          prefixIcon: Icon(Icons.description_outlined,
                              color: Color(0xFFEB8153)),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Batal'),
                            style: ElevatedButton.styleFrom(
                              primary: Color(0xFFDA0000),
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
                              if (name.isNotEmpty &&
                                  selectedJenisKategori != null) {
                                try {
                                  await ApiService().createCategory(
                                    name,
                                    selectedJenisKategori!,
                                    description,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Berhasil ditambahkan!',
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

                                  // Panggil callback untuk refresh
                                  widget.onUpdate?.call();

                                  // Kembali ke halaman sebelumnya
                                  Navigator.pop(context);

                                  // Refresh halaman yang dituju dengan mengganti route
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HomeScreen(initialIndex: 1),
                                    ),
                                  );
                                } catch (e) {
                                  String errorMessage =
                                      'Gagal menambahkan kategori';
                                  if (e
                                      .toString()
                                      .contains('nama sudah digunakan')) {
                                    errorMessage =
                                        'Nama kategori sudah digunakan';
                                  } else if (description.length > 30) {
                                    errorMessage =
                                        'Deskripsi terlalu panjang (maksimal 30 karakter)';
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        errorMessage,
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
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Harap isi semua kolom',
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
                            child: Text('Simpan'),
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
        ],
      ),
    );
  }
}

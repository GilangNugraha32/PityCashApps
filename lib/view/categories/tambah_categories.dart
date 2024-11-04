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
  String selectedJenisKategoriLabel = '';
  final ApiService apiService = ApiService();

  final List<Map<String, dynamic>> jenisKategoriOptions = [
    {'label': 'Pemasukan', 'value': 1},
    {'label': 'Pengeluaran', 'value': 2},
  ];

  void _showJenisKategoriModal() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih Jenis Kategori',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 15),
              ...jenisKategoriOptions.map((option) {
                final isLast = option == jenisKategoriOptions.last;
                return Column(
                  children: [
                    ListTile(
                      title: Text(option['label']),
                      onTap: () {
                        setState(() {
                          selectedJenisKategori = option['value'];
                          selectedJenisKategoriLabel = option['label'];
                        });
                        Navigator.pop(context);
                      },
                      trailing: Radio(
                        value: option['value'],
                        groupValue: selectedJenisKategori,
                        activeColor: Color(0xFFEB8153),
                        onChanged: (value) {
                          setState(() {
                            selectedJenisKategori = value;
                            selectedJenisKategoriLabel = option['label'];
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                        height: 1,
                      ),
                  ],
                );
              }).toList(),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

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
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: nameController,
                          style: TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Masukkan nama kategori',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            suffixIcon: Icon(
                              Icons.interests_outlined,
                              color: Color(0xFFEB8153),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('Jenis Kategori',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      InkWell(
                        onTap: _showJenisKategoriModal,
                        child: Container(
                          height: 50,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.list, color: Color(0xFFEB8153)),
                              SizedBox(width: 12),
                              Text(
                                selectedJenisKategoriLabel.isEmpty
                                    ? 'Pilih jenis kategori'
                                    : selectedJenisKategoriLabel,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: selectedJenisKategoriLabel.isEmpty
                                      ? Colors.grey[400]
                                      : Colors.black,
                                ),
                              ),
                              Spacer(),
                              Icon(Icons.arrow_drop_down,
                                  color: Color(0xFFEB8153)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('Deskripsi',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          style: TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Masukkan deskripsi kategori',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.notes,
                              color: Color(0xFFEB8153),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
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

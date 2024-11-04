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
  String selectedJenisKategoriLabel = '';

  final List<Map<String, dynamic>> jenisKategoriOptions = [
    {'label': 'Pemasukan', 'value': 1},
    {'label': 'Pengeluaran', 'value': 2},
  ];

  @override
  void initState() {
    super.initState();
    _namaKategori = widget.category.name;
    _jenisKategori = widget.category.jenisKategori;
    _deskripsi = widget.category.description;
    selectedJenisKategoriLabel =
        _jenisKategori == 1 ? 'Pemasukan' : 'Pengeluaran';
  }

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
                          _jenisKategori = option['value'];
                          selectedJenisKategoriLabel = option['label'];
                        });
                        Navigator.pop(context);
                      },
                      trailing: Radio(
                        value: option['value'],
                        groupValue: _jenisKategori,
                        activeColor: Color(0xFFEB8153),
                        onChanged: (value) {
                          setState(() {
                            _jenisKategori = value as int;
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
          SnackBar(
            content: Text(
              'Berhasil diperbarui!',
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
        widget.onUpdate(); // Call the refresh method after successful update

        Navigator.pop(context);
      } catch (e) {
        String errorMessage =
            'Gagal memperbarui kategori Nama kategori sudah digunakan';
        if (e.toString().contains('nama sudah digunakan')) {
          errorMessage = 'Nama kategori sudah digunakan';
        } else if (_deskripsi.length > 30) {
          errorMessage = 'Deskripsi terlalu panjang (maksimal 30 karakter)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
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
    }
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
                        icon: Icon(Icons.arrow_back_outlined,
                            color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Icon(
                        Icons.notifications_outlined,
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
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
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
                          child: TextFormField(
                            initialValue: _namaKategori,
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
                          child: TextFormField(
                            initialValue: _deskripsi,
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              if (value.length > 30) {
                                return 'Description must be 30 characters or less';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _deskripsi = value;
                            },
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _updateCategory,
                              child: Text('Simpan'),
                              style: ElevatedButton.styleFrom(
                                primary: Color(0xFFE85C0D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
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

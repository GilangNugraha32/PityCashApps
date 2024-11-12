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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 3,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih Jenis Kategori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 12),
              ...jenisKategoriOptions.map((option) {
                final isLast = option == jenisKategoriOptions.last;
                return Column(
                  children: [
                    ListTile(
                      title:
                          Text(option['label'], style: TextStyle(fontSize: 14)),
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
              SizedBox(height: 16),
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
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(8),
          ),
        );
        widget.onUpdate();
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
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.24,
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFFEB8153),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFEB8153).withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -30,
                      bottom: -20,
                      child: Icon(
                        Icons.insert_chart_outlined_rounded,
                        size: MediaQuery.of(context).size.width * 0.45,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      top: 20,
                      child: Icon(
                        Icons.interests_outlined,
                        size: MediaQuery.of(context).size.width * 0.25,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Edit Kategori',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 3,
                                          color: Colors.black.withOpacity(0.2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    width: 50,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
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
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 3.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nama Kategori',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            initialValue: _namaKategori,
                            style: TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama kategori',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              suffixIcon: Icon(
                                Icons.interests_outlined,
                                color: Color(0xFFEB8153),
                                size: 18,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
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
                        SizedBox(height: 10),
                        Text('Jenis Kategori',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        InkWell(
                          onTap: _showJenisKategoriModal,
                          child: Container(
                            height: 45,
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.list,
                                    color: Color(0xFFEB8153), size: 18),
                                SizedBox(width: 10),
                                Text(
                                  selectedJenisKategoriLabel.isEmpty
                                      ? 'Pilih jenis kategori'
                                      : selectedJenisKategoriLabel,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selectedJenisKategoriLabel.isEmpty
                                        ? Colors.grey[400]
                                        : Colors.black,
                                  ),
                                ),
                                Spacer(),
                                Icon(Icons.arrow_drop_down,
                                    color: Color(0xFFEB8153), size: 18),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('Deskripsi',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            initialValue: _deskripsi,
                            maxLines: 3,
                            style: TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Masukkan deskripsi kategori',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.notes,
                                color: Color(0xFFEB8153),
                                size: 18,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
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
                        SizedBox(height: 20),
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
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size(60, 28),
                              ),
                              child:
                                  Text('Batal', style: TextStyle(fontSize: 11)),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _updateCategory,
                              style: ElevatedButton.styleFrom(
                                primary: Color(0xFFE85C0D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size(60, 28),
                              ),
                              child: Text('Simpan',
                                  style: TextStyle(fontSize: 11)),
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

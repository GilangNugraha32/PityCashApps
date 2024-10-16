import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/view/pemasukan/edit_pemasukan.dart';

class DetailPemasukan extends StatefulWidget {
  final Pemasukan pemasukan;
  final Function? onDelete; // Callback for delete action

  const DetailPemasukan({Key? key, required this.pemasukan, this.onDelete})
      : super(key: key);

  @override
  _DetailPemasukanState createState() => _DetailPemasukanState();
}

class _DetailPemasukanState extends State<DetailPemasukan> {
  late Pemasukan pemasukanDetail;

  @override
  void initState() {
    super.initState();
    pemasukanDetail = widget.pemasukan; // Initialize pemasukanDetail
  }

  void _navigateToEditPage(Pemasukan pemasukan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPemasukan(pemasukan: pemasukan),
      ),
    );

    if (result == true) {
      fetchIncomes(); // Refresh the data on the previous screen
    }
  }

  Future<void> fetchIncomes({int page = 1}) async {
    ApiService apiService = ApiService();
    try {
      List<Pemasukan> incomes = await apiService.fetchIncomes(page: page);
      // Update the state with the fetched data
      setState(() {
        pemasukanDetail = incomes.firstWhere(
            (income) => income.idData == pemasukanDetail.idData,
            orElse: () => pemasukanDetail);
      });
      print('Fetched incomes: $incomes');
    } catch (e) {
      print('Error fetching incomes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal mengambil data pemasukan: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Bagian Atas Profil (Warna Oranye)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFFEB8153),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(90.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Detail Pemasukan',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(90.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 80,
                            child: ElevatedButton(
                              onPressed: () {
                                _showDeleteConfirmationDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                primary: Color(0xFF1A3A63),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: Text('Hapus'),
                            ),
                          ),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 80,
                            child: ElevatedButton(
                              onPressed: () {
                                _navigateToEditPage(pemasukanDetail);
                              },
                              style: ElevatedButton.styleFrom(
                                primary: Color(0xFFF7941E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: Text('Edit'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 50),
                      SizedBox(
                        width: 250,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFFEB8153),
                                child: Icon(Icons.date_range_outlined,
                                    color: Colors.white, size: 22),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(pemasukanDetail.date
                                      .toString()), // Menampilkan tanggal pemasukan
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Menampilkan detail pemasukan secara dinamis
                      Card(
                        color: Colors.grey[350],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    pemasukanDetail.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[100],
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Text(
                                      pemasukanDetail.category?.name ??
                                          'Tidak ada kategori', // Cek null pada category
                                      style: TextStyle(
                                        color: Colors.orange[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(thickness: 0.5, color: Colors.black54),
                              Text(
                                'Deskripsi:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(pemasukanDetail.description),
                              SizedBox(height: 40),
                              Divider(thickness: 0.5, color: Colors.black54),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    NumberFormat.currency(
                                            locale: 'id_ID',
                                            symbol: 'Rp',
                                            decimalDigits: 0)
                                        .format(double.tryParse(
                                                pemasukanDetail.jumlah) ??
                                            0),
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
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

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus data ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final apiService = ApiService();
                  await apiService.deleteIncome(
                      pemasukanDetail.idData); // Call the delete method

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Berhasil dihapus!')),
                  );
                  if (widget.onDelete != null) {
                    widget
                        .onDelete!(); // Invoke the callback to refresh the list
                  }
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context)
                      .pop(true); // Go back and indicate success
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus data: $e')),
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

class ThousandSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Menghapus semua karakter non-digit
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return TextEditingValue();
    }

    // Menggunakan intl package untuk format dengan pemisah ribuan
    String formattedText =
        NumberFormat('#,##0', 'id_ID').format(int.parse(newText));

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

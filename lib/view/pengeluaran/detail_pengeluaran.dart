import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/models/outcomes_model.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/view/pemasukan/edit_pemasukan.dart';
import 'package:pity_cash/view/pengeluaran/edit_pengeluaran.dart';

class DetailPengeluaran extends StatelessWidget {
  final List<Pengeluaran> pengeluaranList; // Daftar pengeluaran yang diteruskan

  DetailPengeluaran({required this.pengeluaranList});

  @override
  Widget build(BuildContext context) {
    print("Pengeluaran List: $pengeluaranList");
// Cek nilai tanggal
    final String baseUrl =
        "http://pitycash.mamorasoft.com/api"; // Ganti dengan base URL Anda

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
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Hi, Syahrul!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                    'Detail Pengeluaran',
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditPengeluaran(
                                        pengeluaranList: pengeluaranList),
                                  ),
                                );
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
                          SizedBox(width: 10),
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
                                  padding: EdgeInsets.all(
                                      8.0), // Increased padding for better aesthetics
                                  child: Text(
                                    // Pastikan kita mendapatkan tanggal dari pengeluaranList
                                    pengeluaranList.isNotEmpty &&
                                            pengeluaranList[0].tanggal != null
                                        ? DateFormat('d MMMM yyyy')
                                            .format(pengeluaranList[0].tanggal!)
                                        : 'Tidak ada data',
                                    style: TextStyle(
                                      fontSize:
                                          14, // Sesuaikan ukuran font sesuai kebutuhan
                                      color: Colors
                                          .black87, // Sesuaikan warna teks
                                    ),
                                    overflow: TextOverflow
                                        .ellipsis, // Prevent text from overflowing
                                    maxLines: 1, // Limit to one line
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Menampilkan detail pengeluaran secara dinamis
                      ListView.builder(
                        itemCount: pengeluaranList.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final pengeluaran = pengeluaranList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Card(
                              color: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Left side: Image
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            pengeluaran.image != null
                                                ? '$baseUrl/${pengeluaran.image}' // Menggunakan base URL
                                                : 'https://via.placeholder.com/60', // Gambar placeholder jika null
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                        width:
                                            16), // Space between image and text
                                    // Right side: Text details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              // Name
                                              Expanded(
                                                child: Text(
                                                  pengeluaran.name,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 19),
                                                ),
                                              ),
                                              // Spacer to push the button to the right
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape
                                                      .rectangle, // Rectangle box shape
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10), // Rounded corners
                                                  color: Colors
                                                      .red, // Red background for the icon button
                                                ),
                                                child: IconButton(
                                                  icon: Icon(
                                                      Icons.delete_outline,
                                                      color: Colors
                                                          .white), // White outlined trash icon
                                                  onPressed: () {
                                                    // Action for delete
                                                    print('Hapus pengeluaran');
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          // Category
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8.0, vertical: 4.0),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[100],
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: Text(
                                              pengeluaran.category?.name ??
                                                  'Tidak ada kategori',
                                              style: TextStyle(
                                                color: Colors.orange[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          // Description

                                          Text(pengeluaran.description),
                                          SizedBox(
                                              height:
                                                  15), // Space before amount
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment
                                                .start, // Ensure alignment of the content
                                            children: [
                                              // First row (Jumlah Satuan and Nominal Rp)
                                              Row(
                                                children: [
                                                  Expanded(
                                                    flex:
                                                        1, // Set a consistent width for the label section
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          'Jumlah Satuan : ',
                                                          style: TextStyle(
                                                              fontSize: 13),
                                                        ),
                                                        Text(
                                                          '${pengeluaran.jumlahSatuan}',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex:
                                                        1, // Set a consistent width for the value section
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          'Nominal Rp : ',
                                                          style: TextStyle(
                                                              fontSize: 13),
                                                        ),
                                                        Text(
                                                          '${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(pengeluaran.nominal)}',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                  height:
                                                      8), // Space between rows

                                              // Second row (DLL and Jumlah)
                                              Row(
                                                children: [
                                                  Expanded(
                                                    flex:
                                                        1, // Align this row exactly like the first row
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          'DLL : ',
                                                          style: TextStyle(
                                                              fontSize: 13),
                                                        ),
                                                        Text(
                                                          '${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(pengeluaran.dll)}',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex:
                                                        1, // Align this row exactly like the first row
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          'Jumlah : ',
                                                          style: TextStyle(
                                                              fontSize: 13),
                                                        ),
                                                        Text(
                                                          '${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(pengeluaran.jumlah)}',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                              height:
                                                  8), // Space before the created and updated timestamps
                                          // Created and updated timestamps
                                          Text(
                                            'Dibuat pada: ${pengeluaran.createdAt.toLocal().toString().split(' ')[0]}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                          Text(
                                            'Diperbarui pada: ${pengeluaran.updatedAt.toLocal().toString().split(' ')[0]}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
                // try {
                //   final apiService =
                //       ApiService(); // Create an instance of ApiService
                //   await apiService
                //       .deleteIncome(pengeluaran.id); // Call the delete method

                //   // Show Snackbar for successful deletion
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     SnackBar(content: Text('Berhasil dihapus!')),
                //   );

                //   Navigator.of(context).pop(); // Close the dialog
                //   Navigator.of(context).pop(); // Go back to the previous screen
                // } catch (e) {
                //   // Handle error (show a snackbar or dialog)
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     SnackBar(content: Text('Gagal menghapus data: $e')),
                //   );
                // }
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}

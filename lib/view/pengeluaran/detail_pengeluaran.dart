import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/models/outcomes_model.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/view/pemasukan/edit_pemasukan.dart';
import 'package:pity_cash/view/pengeluaran/edit_pengeluaran.dart';

class DetailPengeluaran extends StatelessWidget {
  final List<Pengeluaran> pengeluaranList;

  DetailPengeluaran({required this.pengeluaranList});

  @override
  Widget build(BuildContext context) {
    print("Pengeluaran List: $pengeluaranList");
    final String baseUrl = "http://pitycash.mamorasoft.com/api";

    return Scaffold(
      body: Column(
        children: [
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
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.notifications,
                            color: Colors.white, size: 24),
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
                            width: 110,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (pengeluaranList.isNotEmpty) {
                                  _showDeleteConfirmationParentDialog(
                                      context, pengeluaranList[0].idParent);
                                }
                              },
                              icon: Icon(Icons.delete,
                                  color: Colors.red, size: 18),
                              label: Text(
                                'Hapus',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.white,
                                onPrimary: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(color: Colors.red),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditPengeluaran(
                                        pengeluaranList: pengeluaranList),
                                  ),
                                );
                              },
                              icon: Icon(Icons.edit,
                                  color: Color(0xFFF7941E), size: 18),
                              label: Text(
                                'Edit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.white,
                                onPrimary: Color(0xFFF7941E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(color: Color(0xFFF7941E)),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      _buildDateButton(pengeluaranList),
                      SizedBox(height: 10),
                      ListView.builder(
                        itemCount: pengeluaranList.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final pengeluaran = pengeluaranList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Card(
                              color: Color(0xFFFFF5E6), // Warna cream
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                side: BorderSide(
                                    color: Color(0xFFEB8153),
                                    width: 1.5), // Outline
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          child: Image.network(
                                            pengeluaran.image != null
                                                ? '$baseUrl/${pengeluaran.image}'
                                                : 'https://via.placeholder.com/60',
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[300],
                                                child: Icon(Icons.error,
                                                    color: Colors.red),
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pengeluaran.name,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 19),
                                              ),
                                              SizedBox(height: 4),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8.0,
                                                    vertical: 4.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange[100],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                ),
                                                child: Text(
                                                  pengeluaran.category?.name ??
                                                      'Tidak ada kategori',
                                                  style: TextStyle(
                                                      color: Colors.orange[800],
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (pengeluaranList.length > 1)
                                          IconButton(
                                            icon: Icon(Icons.delete_outline,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _showDeleteConfirmationDataDialog(
                                                    context,
                                                    pengeluaran.idData),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Text(pengeluaran.description,
                                        style: TextStyle(fontSize: 14)),
                                    SizedBox(height: 16),
                                    _buildInfoRow(
                                        'Jumlah Satuan',
                                        '${pengeluaran.jumlahSatuan}',
                                        'Nominal',
                                        NumberFormat.currency(
                                                locale: 'id_ID',
                                                symbol: 'Rp ',
                                                decimalDigits: 0)
                                            .format(pengeluaran.nominal)),
                                    SizedBox(height: 8),
                                    _buildInfoRow(
                                        'DLL',
                                        NumberFormat.currency(
                                                locale: 'id_ID',
                                                symbol: 'Rp ',
                                                decimalDigits: 0)
                                            .format(pengeluaran.dll),
                                        'Jumlah',
                                        NumberFormat.currency(
                                                locale: 'id_ID',
                                                symbol: 'Rp ',
                                                decimalDigits: 0)
                                            .format(pengeluaran.jumlah)),
                                    SizedBox(height: 16),
                                    Text(
                                        'Dibuat pada: ${DateFormat('dd MMM yyyy').format(pengeluaran.createdAt.toLocal())}',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    Text(
                                        'Diperbarui pada: ${DateFormat('dd MMM yyyy').format(pengeluaran.updatedAt.toLocal())}',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
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

  Widget _buildDateButton(List<Pengeluaran> pengeluaranList) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      child: Card(
        elevation: 4,
        color: Color(0xFFFFF5E6), // Warna cream untuk background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.orange.shade300, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFFEB8153), size: 28),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  pengeluaranList.isNotEmpty &&
                          pengeluaranList[0].tanggal != null
                      ? DateFormat('d MMMM yyyy')
                          .format(pengeluaranList[0].tanggal!)
                      : 'Tidak ada data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEB8153),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(label1, value1),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildInfoItem(label2, value2),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(height: 4),
        Text(value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showDeleteConfirmationDataDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus data ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final apiService = ApiService();
                  await apiService.deleteDataPengeluaran(id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Berhasil dihapus!')),
                  );
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
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

  void _showDeleteConfirmationParentDialog(BuildContext context, int idParent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content:
              Text('Apakah Anda yakin ingin menghapus semua data terkait?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final apiService = ApiService();
                  await apiService.deleteParentPengeluaran(idParent);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Semua data berhasil dihapus!')),
                  );
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
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

import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:intl/intl.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/models/outcomes_model.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/view/home/home.dart';
import 'package:pity_cash/view/pemasukan/edit_pemasukan.dart';
import 'package:pity_cash/view/pengeluaran/edit_pengeluaran.dart';

class DetailPengeluaran extends StatelessWidget {
  final List<Pengeluaran> pengeluaranList;

  DetailPengeluaran({required this.pengeluaranList});

  String _getMonthName(int month) {
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    print("Pengeluaran List: $pengeluaranList");
    final String baseUrl = "http://pitycash.mamorasoft.com/api";

    // Hitung total keseluruhan
    final totalKeseluruhan = pengeluaranList.fold<double>(
      0,
      (previousValue, element) => previousValue + element.jumlah.toDouble(),
    );

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFFEB8153),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
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
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(initialIndex: 3),
                            ),
                          ),
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
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30.0, 20.0, 30.0, 0),
                child: Column(
                  children: [
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
                            icon:
                                Icon(Icons.delete, color: Colors.red, size: 18),
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
                                borderRadius: BorderRadius.circular(10.0),
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
                    SizedBox(height: 25),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                margin: EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Color(0xFFFFF5EE),
                                    ],
                                  ),
                                  border: Border.all(
                                      color: Color(0xFFEB8153).withOpacity(0.3),
                                      width: 1.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Keseluruhan',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFEB8153)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: AnimatedDefaultTextStyle(
                                              duration:
                                                  Duration(milliseconds: 300),
                                              style: TextStyle(
                                                color: Color(0xFFEB8153),
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              child: Text(
                                                '${pengeluaranList.first.tanggal!.day} ${_getMonthName(pengeluaranList.first.tanggal!.month)} ${pengeluaranList.first.tanggal!.year}',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        color:
                                            Color(0xFFEB8153).withOpacity(0.2),
                                        thickness: 1,
                                        height: 24,
                                      ),
                                      TweenAnimationBuilder<double>(
                                        duration: Duration(milliseconds: 1500),
                                        tween: Tween<double>(
                                          begin: 0,
                                          end: totalKeseluruhan.toDouble(),
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return Text(
                                            NumberFormat.currency(
                                                    locale: 'id_ID',
                                                    symbol: 'Rp',
                                                    decimalDigits: 0)
                                                .format(value),
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFEB8153),
                                              letterSpacing: 0.5,
                                              height: 1.2,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: pengeluaranList.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final pengeluaran = pengeluaranList[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Color(0xFFEB8153), width: 1),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: ExpansionTile(
                                      initiallyExpanded: true,
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pengeluaran.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF1A3A63),
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  NumberFormat.currency(
                                                          locale: 'id_ID',
                                                          symbol: 'Rp',
                                                          decimalDigits: 0)
                                                      .format(
                                                          pengeluaran.jumlah),
                                                  style: TextStyle(
                                                    color: Color(0xFFEB8153),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (pengeluaranList.length > 1)
                                            IconButton(
                                              icon: Icon(Icons.delete_outline),
                                              color: Colors.red[400],
                                              onPressed: () =>
                                                  _showDeleteConfirmationDataDialog(
                                                      context,
                                                      pengeluaran.idData),
                                            ),
                                        ],
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Divider(
                                                  height: 1,
                                                  color: Colors.grey[300]),
                                              SizedBox(height: 16),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Container(
                                                      width: 100,
                                                      height: 100,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors
                                                                .grey[300]!,
                                                            width: 1),
                                                      ),
                                                      child:
                                                          FutureBuilder<String>(
                                                        future: ApiService()
                                                            .fetchPengeluaranImage(
                                                                pengeluaran
                                                                    .idData),
                                                        builder: (context,
                                                            snapshot) {
                                                          if (snapshot
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .waiting) {
                                                            return Center(
                                                                child: CircularProgressIndicator(
                                                                    color: Color(
                                                                        0xFFEB8153)));
                                                          }

                                                          if (snapshot.hasError ||
                                                              !snapshot
                                                                  .hasData ||
                                                              snapshot.data!
                                                                  .isEmpty) {
                                                            return Image
                                                                .network(
                                                              pengeluaran.image !=
                                                                      null
                                                                  ? '$baseUrl/${pengeluaran.image}'
                                                                  : 'https://via.placeholder.com/100',
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Icon(
                                                                    Icons.error,
                                                                    color: Colors
                                                                            .red[
                                                                        400]);
                                                              },
                                                            );
                                                          }

                                                          return GestureDetector(
                                                            onTap: () {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        Dialog(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .transparent,
                                                                  insetPadding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              16),
                                                                  child:
                                                                      Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .white,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              20),
                                                                      boxShadow: [
                                                                        BoxShadow(
                                                                          color: Colors
                                                                              .black
                                                                              .withOpacity(0.2),
                                                                          blurRadius:
                                                                              10,
                                                                          offset: Offset(
                                                                              0,
                                                                              5),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Container(
                                                                          padding: EdgeInsets.symmetric(
                                                                              horizontal: 20,
                                                                              vertical: 16),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            gradient:
                                                                                LinearGradient(
                                                                              colors: [
                                                                                Color(0xFFEB8153),
                                                                                Color(0xFFFF9D6C)
                                                                              ],
                                                                              begin: Alignment.topLeft,
                                                                              end: Alignment.bottomRight,
                                                                            ),
                                                                            borderRadius:
                                                                                BorderRadius.vertical(
                                                                              top: Radius.circular(20),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Row(
                                                                                children: [
                                                                                  Icon(
                                                                                    Icons.receipt_long,
                                                                                    color: Colors.white,
                                                                                    size: 24,
                                                                                  ),
                                                                                  SizedBox(width: 12),
                                                                                  Text(
                                                                                    'Bukti Transaksi',
                                                                                    style: TextStyle(
                                                                                      color: Colors.white,
                                                                                      fontSize: 20,
                                                                                      fontWeight: FontWeight.bold,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              IconButton(
                                                                                icon: Icon(Icons.close, color: Colors.white),
                                                                                onPressed: () => Navigator.pop(context),
                                                                                splashRadius: 24,
                                                                              )
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          margin:
                                                                              EdgeInsets.all(16),
                                                                          constraints:
                                                                              BoxConstraints(
                                                                            maxHeight:
                                                                                MediaQuery.of(context).size.height * 0.7,
                                                                            maxWidth:
                                                                                MediaQuery.of(context).size.width * 0.9,
                                                                          ),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.circular(12),
                                                                            border:
                                                                                Border.all(
                                                                              color: Colors.grey.withOpacity(0.2),
                                                                              width: 1,
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              ClipRRect(
                                                                            borderRadius:
                                                                                BorderRadius.circular(12),
                                                                            child:
                                                                                InteractiveViewer(
                                                                              boundaryMargin: EdgeInsets.all(20.0),
                                                                              minScale: 0.5,
                                                                              maxScale: 4.0,
                                                                              child: Image.memory(
                                                                                base64Decode(snapshot.data!.split(',').last),
                                                                                fit: BoxFit.contain,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: Image.memory(
                                                              base64Decode(
                                                                  snapshot.data!
                                                                      .split(
                                                                          ',')
                                                                      .last),
                                                              fit: BoxFit.cover,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .orange[50],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            border: Border.all(
                                                                color: Colors
                                                                        .orange[
                                                                    300]!,
                                                                width: 1),
                                                          ),
                                                          child: Text(
                                                            pengeluaran.category
                                                                    ?.name ??
                                                                'Tidak ada kategori',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .orange[800],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(height: 12),
                                                        Text(
                                                          pengeluaran
                                                              .description,
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .grey[700],
                                                              height: 1.5),
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 20),
                                              Container(
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                    color: Colors.grey[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color:
                                                            Colors.grey[300]!,
                                                        width: 1)),
                                                child: Column(
                                                  children: [
                                                    _buildInfoRow(
                                                      'Jumlah Satuan',
                                                      '${pengeluaran.jumlahSatuan}',
                                                      'Nominal',
                                                      NumberFormat.currency(
                                                              locale: 'id_ID',
                                                              symbol: 'Rp',
                                                              decimalDigits: 0)
                                                          .format(pengeluaran
                                                              .nominal),
                                                    ),
                                                    SizedBox(height: 12),
                                                    Divider(
                                                        height: 1,
                                                        color:
                                                            Colors.grey[300]),
                                                    SizedBox(height: 12),
                                                    _buildInfoRow(
                                                      'DLL',
                                                      NumberFormat.currency(
                                                              locale: 'id_ID',
                                                              symbol: 'Rp',
                                                              decimalDigits: 0)
                                                          .format(
                                                              pengeluaran.dll),
                                                      'Jumlah',
                                                      NumberFormat.currency(
                                                              locale: 'id_ID',
                                                              symbol: 'Rp',
                                                              decimalDigits: 0)
                                                          .format(pengeluaran
                                                              .jumlah),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Dibuat: ${DateFormat('dd MMM yyyy').format(pengeluaran.createdAt.toLocal())}',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.grey[600]),
                                                  ),
                                                  Text(
                                                    'Diperbarui: ${DateFormat('dd MMM yyyy').format(pengeluaran.updatedAt.toLocal())}',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.grey[600]),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
                  ],
                ),
              ),
            ),
          ),
        ],
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
        SizedBox(width: 10),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Konfirmasi Hapus',
            style: TextStyle(color: Colors.red),
          ),
          content: Text('Apakah Anda yakin ingin menghapus data ini?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final apiService = ApiService();
                  await apiService.deleteDataPengeluaran(id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Berhasil dihapus!',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.all(10),
                    ),
                  );
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(initialIndex: 3),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus data: $e',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
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
              child: Text('Hapus'),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Konfirmasi Hapus',
            style: TextStyle(color: Colors.red),
          ),
          content:
              Text('Apakah Anda yakin ingin menghapus semua data terkait?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final apiService = ApiService();
                  await apiService.deleteParentPengeluaran(idParent);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Semua data berhasil dihapus!',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.all(10),
                    ),
                  );
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(initialIndex: 3),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus data: $e',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
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
              child: Text(
                'Hapus',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

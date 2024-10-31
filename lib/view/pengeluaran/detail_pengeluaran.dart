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
                    SizedBox(height: 5),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Total Keseluruhan:',
                                                  style: TextStyle(
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.04,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  '${pengeluaranList.first.tanggal!.day} ${_getMonthName(pengeluaranList.first.tanggal!.month)} ${pengeluaranList.first.tanggal!.year}',
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.04,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              NumberFormat.currency(
                                                      locale: 'id_ID',
                                                      symbol: 'Rp',
                                                      decimalDigits: 0)
                                                  .format(totalKeseluruhan),
                                              style: TextStyle(
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.05,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFEB8153),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ListView.builder(
                                    itemCount: pengeluaranList.length,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final pengeluaran =
                                          pengeluaranList[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2.0, horizontal: 12.0),
                                        child: Card(
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15.0),
                                            side: BorderSide(
                                                color: Color(0xFFEB8153),
                                                width: 0.5),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: ExpansionTile(
                                                  initiallyExpanded: true,
                                                  title: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              pengeluaran.name,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color: Color(
                                                                    0xFF1A3A63),
                                                              ),
                                                            ),
                                                            Text(
                                                              NumberFormat.currency(
                                                                      locale:
                                                                          'id_ID',
                                                                      symbol:
                                                                          'Rp',
                                                                      decimalDigits:
                                                                          0)
                                                                  .format(
                                                                      pengeluaran
                                                                          .jumlah),
                                                              style: TextStyle(
                                                                color: Color(
                                                                    0xFFEB8153),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      if (pengeluaranList
                                                              .length >
                                                          1)
                                                        IconButton(
                                                          icon: Icon(
                                                              Icons
                                                                  .delete_outline,
                                                              color:
                                                                  Colors.red),
                                                          onPressed: () =>
                                                              _showDeleteConfirmationDataDialog(
                                                                  context,
                                                                  pengeluaran
                                                                      .idData),
                                                        ),
                                                    ],
                                                  ),
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16.0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10.0),
                                                                child:
                                                                    FutureBuilder<
                                                                        String>(
                                                                  future: ApiService()
                                                                      .fetchPengeluaranImage(
                                                                          pengeluaran
                                                                              .idData),
                                                                  builder: (context,
                                                                      snapshot) {
                                                                    Widget
                                                                        imageWidget;
                                                                    if (snapshot
                                                                            .connectionState ==
                                                                        ConnectionState
                                                                            .waiting) {
                                                                      imageWidget =
                                                                          Container(
                                                                        width:
                                                                            80,
                                                                        height:
                                                                            80,
                                                                        color: Colors
                                                                            .grey[200],
                                                                        child: Center(
                                                                            child:
                                                                                CircularProgressIndicator(color: Color(0xFFEB8153))),
                                                                      );
                                                                    } else if (snapshot.hasError ||
                                                                        !snapshot
                                                                            .hasData ||
                                                                        snapshot
                                                                            .data!
                                                                            .isEmpty) {
                                                                      imageWidget =
                                                                          Image
                                                                              .network(
                                                                        pengeluaran.image !=
                                                                                null
                                                                            ? '$baseUrl/${pengeluaran.image}'
                                                                            : 'https://via.placeholder.com/80',
                                                                        width:
                                                                            80,
                                                                        height:
                                                                            80,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        errorBuilder: (context,
                                                                            error,
                                                                            stackTrace) {
                                                                          return Container(
                                                                            width:
                                                                                80,
                                                                            height:
                                                                                80,
                                                                            color:
                                                                                Colors.grey[200],
                                                                            child:
                                                                                Icon(Icons.error, color: Colors.red),
                                                                          );
                                                                        },
                                                                      );
                                                                    } else {
                                                                      imageWidget =
                                                                          Image
                                                                              .memory(
                                                                        base64Decode(snapshot
                                                                            .data!
                                                                            .split(',')
                                                                            .last),
                                                                        width:
                                                                            80,
                                                                        height:
                                                                            80,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      );
                                                                    }

                                                                    return GestureDetector(
                                                                      onTap:
                                                                          () {
                                                                        if (snapshot.hasData &&
                                                                            snapshot.data!.isNotEmpty) {
                                                                          showDialog(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (BuildContext context) {
                                                                              return Dialog(
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: BorderRadius.circular(20.0),
                                                                                ),
                                                                                child: Container(
                                                                                  width: MediaQuery.of(context).size.width * 0.8,
                                                                                  height: MediaQuery.of(context).size.height * 0.6,
                                                                                  decoration: BoxDecoration(
                                                                                    borderRadius: BorderRadius.circular(20.0),
                                                                                    color: Colors.white,
                                                                                  ),
                                                                                  child: Column(
                                                                                    children: [
                                                                                      Container(
                                                                                        padding: EdgeInsets.all(16),
                                                                                        decoration: BoxDecoration(
                                                                                          color: Color(0xFFEB8153),
                                                                                          borderRadius: BorderRadius.only(
                                                                                            topLeft: Radius.circular(20.0),
                                                                                            topRight: Radius.circular(20.0),
                                                                                          ),
                                                                                        ),
                                                                                        child: Row(
                                                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                          children: [
                                                                                            Text(
                                                                                              'Bukti Transaksi',
                                                                                              style: TextStyle(
                                                                                                color: Colors.white,
                                                                                                fontSize: 20,
                                                                                                fontWeight: FontWeight.bold,
                                                                                              ),
                                                                                            ),
                                                                                            IconButton(
                                                                                              icon: Icon(Icons.close, color: Colors.white),
                                                                                              onPressed: () => Navigator.of(context).pop(),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                      Expanded(
                                                                                        child: InteractiveViewer(
                                                                                          panEnabled: true,
                                                                                          boundaryMargin: EdgeInsets.all(20),
                                                                                          minScale: 0.5,
                                                                                          maxScale: 4,
                                                                                          child: Image.memory(
                                                                                            base64Decode(snapshot.data!.split(',').last),
                                                                                            fit: BoxFit.contain,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                          );
                                                                        }
                                                                      },
                                                                      child:
                                                                          imageWidget,
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  width: 16),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Container(
                                                                      padding: EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              8.0,
                                                                          vertical:
                                                                              4.0),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .orange[50],
                                                                        borderRadius:
                                                                            BorderRadius.circular(10.0),
                                                                        border: Border.all(
                                                                            color:
                                                                                Colors.orange[300]!,
                                                                            width: 0.5),
                                                                      ),
                                                                      child:
                                                                          Text(
                                                                        pengeluaran.category?.name ??
                                                                            'Tidak ada kategori',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.orange[800],
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            8),
                                                                    Text(
                                                                      pengeluaran
                                                                          .description,
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.grey[600]),
                                                                      maxLines:
                                                                          2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: 16),
                                                          _buildInfoRow(
                                                            'Jumlah Satuan',
                                                            '${pengeluaran.jumlahSatuan}',
                                                            'Nominal',
                                                            NumberFormat.currency(
                                                                    locale:
                                                                        'id_ID',
                                                                    symbol:
                                                                        'Rp',
                                                                    decimalDigits:
                                                                        0)
                                                                .format(
                                                                    pengeluaran
                                                                        .nominal),
                                                          ),
                                                          SizedBox(height: 8),
                                                          _buildInfoRow(
                                                            'DLL',
                                                            NumberFormat.currency(
                                                                    locale:
                                                                        'id_ID',
                                                                    symbol:
                                                                        'Rp',
                                                                    decimalDigits:
                                                                        0)
                                                                .format(
                                                                    pengeluaran
                                                                        .dll),
                                                            'Jumlah',
                                                            NumberFormat.currency(
                                                                    locale:
                                                                        'id_ID',
                                                                    symbol:
                                                                        'Rp',
                                                                    decimalDigits:
                                                                        0)
                                                                .format(
                                                                    pengeluaran
                                                                        .jumlah),
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
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                            .grey[
                                                                        500]),
                                                              ),
                                                              Text(
                                                                'Diperbarui: ${DateFormat('dd MMM yyyy').format(pengeluaran.updatedAt.toLocal())}',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                            .grey[
                                                                        500]),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 20),
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

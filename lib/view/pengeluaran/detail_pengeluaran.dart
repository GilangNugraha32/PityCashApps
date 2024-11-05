import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:intl/intl.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/models/outcomes_model.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/service/share_preference.dart';
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
            height: MediaQuery.of(context).size.height * 0.1117,
            decoration: BoxDecoration(
              color: Color(0xFFEB8153),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 13,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Detail Pengeluaran',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 0),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0),
                          child: Column(
                            children: [
                              SizedBox(height: 10),
                              // Rincian Transaksi Section
                              Container(
                                padding: EdgeInsets.all(4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          color: Color(0xFF1A3A63),
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Rincian Transaksi',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A3A63),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Card(
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Color(0xFFEB8153)
                                              .withOpacity(0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Tanggal Transaksi',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFFEB8153)
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  child: Text(
                                                    '${pengeluaranList.first.tanggal!.day} ${_getMonthName(pengeluaranList.first.tanggal!.month)} ${pengeluaranList.first.tanggal!.year}',
                                                    style: TextStyle(
                                                      color: Color(0xFFEB8153),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 10),
                                            ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  NeverScrollableScrollPhysics(),
                                              itemCount: pengeluaranList.length,
                                              itemBuilder: (context, index) {
                                                final item =
                                                    pengeluaranList[index];
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                      bottom: 10),
                                                  child: Row(
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
                                                              item.name,
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                            ),
                                                            SizedBox(height: 2),
                                                            Text(
                                                              '${item.jumlahSatuan} x ${NumberFormat.currency(
                                                                locale: 'id_ID',
                                                                symbol: 'Rp',
                                                                decimalDigits:
                                                                    0,
                                                              ).format(item.nominal)}',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey[600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Text(
                                                        NumberFormat.currency(
                                                          locale: 'id_ID',
                                                          symbol: 'Rp',
                                                          decimalDigits: 0,
                                                        ).format(item.jumlah),
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              Color(0xFF1A3A63),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            Divider(
                                              color:
                                                  Colors.grey.withOpacity(0.3),
                                              thickness: 1,
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Biaya dll',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                Text(
                                                  NumberFormat.currency(
                                                    locale: 'id_ID',
                                                    symbol: 'Rp',
                                                    decimalDigits: 0,
                                                  ).format(pengeluaranList
                                                      .fold<double>(
                                                          0.0,
                                                          (sum, item) =>
                                                              sum + item.dll)),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF1A3A63),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Total Belanja',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1A3A63),
                                                  ),
                                                ),
                                                TweenAnimationBuilder<double>(
                                                  duration: Duration(
                                                      milliseconds: 1500),
                                                  tween: Tween<double>(
                                                    begin: 0,
                                                    end: totalKeseluruhan
                                                        .toDouble(),
                                                  ),
                                                  curve: Curves.easeOutCubic,
                                                  builder:
                                                      (context, value, child) {
                                                    return Text(
                                                      NumberFormat.currency(
                                                        locale: 'id_ID',
                                                        symbol: 'Rp',
                                                        decimalDigits: 0,
                                                      ).format(value),
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFFEB8153),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),

                              // Detail Produk Section
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 0.5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.shopping_cart_outlined,
                                          color: Color(0xFF1A3A63),
                                          size: 18,
                                        ),
                                        Text(
                                          'Detail Produk Belanja',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A3A63),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ListView.separated(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: pengeluaranList.length,
                                      separatorBuilder: (context, index) =>
                                          SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final pengeluaran =
                                            pengeluaranList[index];
                                        return Card(
                                          elevation: 1,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: Color(0xFFEB8153)
                                                  .withOpacity(0.3),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Theme(
                                            data: Theme.of(context).copyWith(
                                              dividerColor: Colors.transparent,
                                            ),
                                            child: ExpansionTile(
                                              initiallyExpanded: true,
                                              title: Row(
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
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                            color: Color(
                                                                0xFF1A3A63),
                                                          ),
                                                        ),
                                                        SizedBox(height: 2),
                                                        Text(
                                                          NumberFormat.currency(
                                                            locale: 'id_ID',
                                                            symbol: 'Rp',
                                                            decimalDigits: 0,
                                                          ).format(pengeluaran
                                                              .jumlah),
                                                          style: TextStyle(
                                                            color: Color(
                                                                0xFFEB8153),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  FutureBuilder<
                                                      Map<String, dynamic>?>(
                                                    future:
                                                        SharedPreferencesService()
                                                            .getRoles(),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot.hasData &&
                                                          snapshot.data !=
                                                              null) {
                                                        bool isReader = snapshot
                                                                        .data![
                                                                    'roles'][0]
                                                                ['name'] ==
                                                            'Reader';
                                                        if (!isReader &&
                                                            pengeluaranList
                                                                    .length >
                                                                1) {
                                                          return IconButton(
                                                            icon: Icon(Icons
                                                                .delete_outline),
                                                            color:
                                                                Colors.red[400],
                                                            iconSize: 18,
                                                            onPressed: () =>
                                                                _showDeleteConfirmationDataDialog(
                                                              context,
                                                              pengeluaran
                                                                  .idData,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                      return Container();
                                                    },
                                                  ),
                                                ],
                                              ),
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      12.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Divider(
                                                          height: 1,
                                                          color:
                                                              Colors.grey[300]),
                                                      SizedBox(height: 12),
                                                      LayoutBuilder(builder:
                                                          (context,
                                                              constraints) {
                                                        return Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                              child: Container(
                                                                width: constraints
                                                                        .maxWidth *
                                                                    0.25,
                                                                height: constraints
                                                                        .maxWidth *
                                                                    0.25,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  border: Border
                                                                      .all(
                                                                    color: Colors
                                                                            .grey[
                                                                        300]!,
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                child:
                                                                    FutureBuilder<
                                                                        String>(
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
                                                                        child:
                                                                            CircularProgressIndicator(
                                                                          color:
                                                                              Color(0xFFEB8153),
                                                                        ),
                                                                      );
                                                                    }

                                                                    if (snapshot.hasError ||
                                                                        !snapshot
                                                                            .hasData ||
                                                                        snapshot
                                                                            .data!
                                                                            .isEmpty) {
                                                                      return Image
                                                                          .network(
                                                                        pengeluaran.image !=
                                                                                null
                                                                            ? '$baseUrl/${pengeluaran.image}'
                                                                            : 'https://via.placeholder.com/100',
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        errorBuilder: (context,
                                                                            error,
                                                                            stackTrace) {
                                                                          return Icon(
                                                                              Icons.error,
                                                                              color: Colors.red[400]);
                                                                        },
                                                                      );
                                                                    }

                                                                    return GestureDetector(
                                                                      onTap:
                                                                          () {
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder: (context) =>
                                                                              Dialog(
                                                                            backgroundColor:
                                                                                Colors.transparent,
                                                                            insetPadding:
                                                                                EdgeInsets.all(16),
                                                                            child:
                                                                                Container(
                                                                              decoration: BoxDecoration(
                                                                                color: Colors.white,
                                                                                borderRadius: BorderRadius.circular(20),
                                                                                boxShadow: [
                                                                                  BoxShadow(
                                                                                    color: Colors.black.withOpacity(0.2),
                                                                                    blurRadius: 10,
                                                                                    offset: Offset(0, 5),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  Container(
                                                                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                                                                    decoration: BoxDecoration(
                                                                                      gradient: LinearGradient(
                                                                                        colors: [
                                                                                          Color(0xFFEB8153),
                                                                                          Color(0xFFFF9D6C)
                                                                                        ],
                                                                                        begin: Alignment.topLeft,
                                                                                        end: Alignment.bottomRight,
                                                                                      ),
                                                                                      borderRadius: BorderRadius.vertical(
                                                                                        top: Radius.circular(20),
                                                                                      ),
                                                                                    ),
                                                                                    child: Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                      children: [
                                                                                        Row(
                                                                                          children: [
                                                                                            Icon(
                                                                                              Icons.receipt_long,
                                                                                              color: Colors.white,
                                                                                              size: 16,
                                                                                            ),
                                                                                            SizedBox(width: 12),
                                                                                            Text(
                                                                                              'Gambar ${pengeluaran.name}',
                                                                                              style: TextStyle(
                                                                                                color: Colors.white,
                                                                                                fontSize: 12,
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
                                                                                    margin: EdgeInsets.all(16),
                                                                                    constraints: BoxConstraints(
                                                                                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                                                                                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                                                                                    ),
                                                                                    decoration: BoxDecoration(
                                                                                      borderRadius: BorderRadius.circular(12),
                                                                                      border: Border.all(
                                                                                        color: Colors.grey.withOpacity(0.2),
                                                                                        width: 1,
                                                                                      ),
                                                                                    ),
                                                                                    child: ClipRRect(
                                                                                      borderRadius: BorderRadius.circular(12),
                                                                                      child: InteractiveViewer(
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
                                                                      child: Image
                                                                          .memory(
                                                                        base64Decode(snapshot
                                                                            .data!
                                                                            .split(',')
                                                                            .last),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 12),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Container(
                                                                    padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            4),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .orange[50],
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              6),
                                                                      border: Border.all(
                                                                          color: Colors.orange[
                                                                              300]!,
                                                                          width:
                                                                              0.5),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .insert_chart_outlined_outlined,
                                                                          size:
                                                                              14,
                                                                          color:
                                                                              Colors.orange[800],
                                                                        ),
                                                                        SizedBox(
                                                                            width:
                                                                                4),
                                                                        Flexible(
                                                                          child:
                                                                              Text(
                                                                            pengeluaran.category?.name ??
                                                                                'Tidak ada kategori',
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.orange[800],
                                                                              fontWeight: FontWeight.w600,
                                                                              fontSize: 11,
                                                                            ),
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      height:
                                                                          8),
                                                                  Text(
                                                                    pengeluaran
                                                                        .description,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                              .grey[
                                                                          700],
                                                                      height:
                                                                          1.4,
                                                                    ),
                                                                    maxLines: 3,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      }),
                                                      SizedBox(height: 16),
                                                      Container(
                                                        padding:
                                                            EdgeInsets.all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[50],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          border: Border.all(
                                                              color: Colors
                                                                  .grey[300]!,
                                                              width: 0.5),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            _buildInfoRow(
                                                              'Jumlah Satuan',
                                                              '${pengeluaran.jumlahSatuan}',
                                                              'Nominal',
                                                              NumberFormat
                                                                  .currency(
                                                                locale: 'id_ID',
                                                                symbol: 'Rp',
                                                                decimalDigits:
                                                                    0,
                                                              ).format(
                                                                  pengeluaran
                                                                      .nominal),
                                                            ),
                                                            SizedBox(height: 8),
                                                            Divider(
                                                                height: 1,
                                                                color: Colors
                                                                    .grey[300]),
                                                            SizedBox(height: 8),
                                                            _buildInfoRow(
                                                              'DLL',
                                                              NumberFormat
                                                                  .currency(
                                                                locale: 'id_ID',
                                                                symbol: 'Rp',
                                                                decimalDigits:
                                                                    0,
                                                              ).format(
                                                                  pengeluaran
                                                                      .dll),
                                                              'Jumlah',
                                                              NumberFormat
                                                                  .currency(
                                                                locale: 'id_ID',
                                                                symbol: 'Rp',
                                                                decimalDigits:
                                                                    0,
                                                              ).format(
                                                                  pengeluaran
                                                                      .jumlah),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(height: 12),
                                                      Container(
                                                        width: double.infinity,
                                                        padding:
                                                            EdgeInsets.all(8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[100],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Wrap(
                                                          spacing: 12,
                                                          runSpacing: 6,
                                                          alignment:
                                                              WrapAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .access_time,
                                                                  size: 14,
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                ),
                                                                SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  'Dibuat: ${DateFormat('dd MMM yyyy').format(pengeluaran.createdAt.toLocal())}',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                            .grey[
                                                                        600],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons.update,
                                                                  size: 14,
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                ),
                                                                SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  'Diperbarui: ${DateFormat('dd MMM yyyy').format(pengeluaran.updatedAt.toLocal())}',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                            .grey[
                                                                        600],
                                                                  ),
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
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: SharedPreferencesService().getRoles(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          bool isReader =
                              snapshot.data!['roles'][0]['name'] == 'Reader';
                          if (isReader) {
                            return Container();
                          }
                        }
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.white,
                                    side: BorderSide(
                                      color: Colors.red,
                                      width: 0.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (pengeluaranList.isNotEmpty) {
                                      _showDeleteConfirmationParentDialog(
                                          context, pengeluaranList[0].idParent);
                                    }
                                  },
                                  child: Text(
                                    'Hapus',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.white,
                                    side: BorderSide(
                                      color: Color(0xFFEB8153),
                                      width: 0.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditPengeluaran(
                                            pengeluaranList: pengeluaranList),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Color(0xFFEB8153),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.withOpacity(0.5), width: 0.5),
          ),
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          titlePadding:
              EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
          title: Text(
            'Konfirmasi Hapus',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus data ini?',
            style: TextStyle(fontSize: 11),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 28,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final apiService = ApiService();
                        await apiService.deleteDataPengeluaran(id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Berhasil dihapus!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: EdgeInsets.all(8),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
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
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: EdgeInsets.all(8),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
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
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.withOpacity(0.5), width: 0.5),
          ),
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          titlePadding:
              EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
          title: Text(
            'Konfirmasi Hapus',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus semua data terkait?',
            style: TextStyle(fontSize: 11),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 28,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final apiService = ApiService();
                        await apiService.deleteParentPengeluaran(idParent);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Semua data berhasil dihapus!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: EdgeInsets.all(8),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
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
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: EdgeInsets.all(8),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

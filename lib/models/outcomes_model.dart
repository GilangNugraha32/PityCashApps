import 'package:pity_cash/models/category_model.dart';
import 'package:pity_cash/models/transaction_model.dart';

class Pengeluaran {
  final int idData;
  final String name;
  final String description;
  final double jumlah;
  final int jumlahSatuan;
  final double nominal;
  final double dll;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? id;
  final int idParent;
  final DateTime? tanggal;
  final Category? category;
  final List<Transaksi>? transaksi;
  final Pengeluaran? parentPengeluaran;

  Pengeluaran({
    required this.idData,
    required this.name,
    required this.description,
    required this.jumlah,
    required this.jumlahSatuan,
    required this.nominal,
    required this.dll,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    this.id,
    required this.idParent,
    this.tanggal,
    this.category,
    this.transaksi,
    this.parentPengeluaran,
  });

  factory Pengeluaran.fromJson(Map<String, dynamic> json) {
    DateTime? parentTanggal;

    if (json['parent_pengeluaran'] != null) {
      parentTanggal = DateTime.parse(json['parent_pengeluaran']['tanggal']);
    }

    return Pengeluaran(
      idData: int.tryParse(json['id_data'].toString()) ?? 0,
      name: json['name'] ?? 'Tidak ada',
      description: json['description'] ?? 'Tidak ada',
      jumlah: double.tryParse(json['jumlah'].toString()) ?? 0.0,
      jumlahSatuan: int.tryParse(json['jumlah_satuan'].toString()) ?? 1,
      nominal: double.tryParse(json['nominal'].toString()) ?? 0.0,
      dll: double.tryParse(json['dll'].toString()) ?? 0.0,
      image: json['image'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      idParent: int.tryParse(json['id_parent'].toString()) ?? 0,
      tanggal: parentTanggal,
      category:
          json['category'] != null ? Category.fromJson(json['category']) : null,
      transaksi: json['transaksi'] != null
          ? Transaksi.fromJsonList(json['transaksi'])
          : null,
      parentPengeluaran: json['parent_pengeluaran'] != null
          ? Pengeluaran.fromJson(json['parent_pengeluaran'])
          : null,
    );
  }

  @override
  String toString() {
    return 'Pengeluaran{idData: $idData, name: $name, tanggal: $tanggal}';
  }
}

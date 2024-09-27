import 'package:pity_cash/models/category_model.dart';
import 'package:pity_cash/models/transaction_model.dart';
class Pengeluaran {
  final int idData;
  final String name;
  final String description;
  final double jumlah; // Menggunakan double untuk jumlah
  final int jumlahSatuan; // Sesuai tipe data di JSON
  final double nominal; // Menggunakan double untuk nominal
  final double dll; // Menggunakan double untuk dll
  final String? image; // Gambar bisa null
  final DateTime createdAt; // Gunakan DateTime untuk timestamp
  final DateTime updatedAt; // Gunakan DateTime untuk timestamp
  final int? id; // id bisa null jika tidak ada
  final int idParent; // Menggunakan id_parent
  final Category? category; // Kategori bisa null
  final List<Transaksi>? transaksi; // Menambahkan field untuk transaksi

  Pengeluaran({
    required this.idData,
    required this.name,
    required this.description,
    required this.jumlah,
    required this.jumlahSatuan,
    required this.nominal,
    required this.dll,
    this.image, // Gambar opsional
    required this.createdAt,
    required this.updatedAt,
    this.id, // id opsional
    required this.idParent,
    this.category, // kategori opsional
    this.transaksi, // Menambahkan transaksi opsional
  });

  // Konversi dari JSON ke objek Pengeluaran
  factory Pengeluaran.fromJson(Map<String, dynamic> json) {
    return Pengeluaran(
      idData: json['id_data'],
      name: json['name'] ?? 'Tidak ada', // Jika null, gunakan 'Tidak ada'
      description: json['description'] ?? 'Tidak ada',
      jumlah: double.tryParse(json['jumlah']) ?? 0.0, // Mengkonversi string ke double
      jumlahSatuan: json['jumlah_satuan'] ?? 1, // Default jika null
      nominal: double.tryParse(json['nominal']) ?? 0.0, // Mengkonversi string ke double
      dll: double.tryParse(json['dll']) ?? 0.0, // Mengkonversi string ke double
      image: json['image'], // Bisa null, tidak perlu fallback
      createdAt: DateTime.parse(json['created_at']), // Menggunakan DateTime
      updatedAt: DateTime.parse(json['updated_at']), // Menggunakan DateTime
      id: json['id'], // id bisa null
      idParent: json['id_parent'] ?? 0, // Default jika null
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null, // Memastikan kategori tidak null
      transaksi: json['transaksi'] != null
          ? Transaksi.fromJsonList(json['transaksi'])
          : null, // Pastikan transaksi tidak null
    );
  }

  // Fungsi untuk mengonversi dari list JSON ke List<Pengeluaran>
  static List<Pengeluaran> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Pengeluaran.fromJson(json)).toList();
  }
}

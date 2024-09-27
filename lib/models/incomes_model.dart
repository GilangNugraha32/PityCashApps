import 'package:pity_cash/models/category_model.dart';

class Pemasukan {
  final int idData;
  final String name;
  final String description;
  final String date;
  final String jumlah;
  final String createdAt;
  final String updatedAt;
  final int? id; // Change to nullable
  final Category? category; // Keep it nullable

  Pemasukan({
    required this.idData,
    required this.name,
    required this.description,
    required this.date,
    required this.jumlah,
    required this.createdAt,
    required this.updatedAt,
    this.id, // Nullable
    this.category, // Nullable
  });

  factory Pemasukan.fromJson(Map<String, dynamic> json) {
    return Pemasukan(
      idData: json['id_data'],
      name: json['name'],
      description: json['description'],
      date: json['date'],
      jumlah: json['jumlah'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      id: json['id'], // Direct assignment (now nullable)
      category: json['category'] != null ? Category.fromJson(json['category']) : null, // Nullable handling
    );
  }
}

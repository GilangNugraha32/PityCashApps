class Transaksi {
  final int idData;
  final String name;
  final double jumlah; // Pastikan ini menggunakan double

  Transaksi({
    required this.idData,
    required this.name,
    required this.jumlah,
  });

  // Konversi dari JSON ke objek Transaksi
  factory Transaksi.fromJson(Map<String, dynamic> json) {
    return Transaksi(
      idData: json['id_data'],
      name: json['name'],
      jumlah: double.tryParse(json['jumlah']) ?? 0.0,
    );
  }

  // Fungsi untuk mengonversi dari list JSON ke List<Transaksi>
  static List<Transaksi> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Transaksi.fromJson(json)).toList();
  }
}

class Transaksi {
  final int idData;
  final String name;
  final double jumlah;

  Transaksi({
    required this.idData,
    required this.name,
    required this.jumlah,
  });

  factory Transaksi.fromJson(Map<String, dynamic> json) {
    return Transaksi(
      idData: int.tryParse(json['id_data'].toString()) ?? 0,
      name: json['name'] ?? 'Tidak ada',
      jumlah: double.tryParse(json['jumlah'].toString()) ?? 0.0,
    );
  }

  static List<Transaksi> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Transaksi.fromJson(json)).toList();
  }
}

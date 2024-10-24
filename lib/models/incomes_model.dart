import 'package:pity_cash/models/category_model.dart';

class Pemasukan {
  final int idData;
  final String name;
  final String description;
  final String date;
  final String jumlah;
  final String createdAt;
  final String updatedAt;
  final int? id;
  final Category? category;

  Pemasukan({
    required this.idData,
    required this.name,
    required this.description,
    required this.date,
    required this.jumlah,
    required this.createdAt,
    required this.updatedAt,
    this.id,
    this.category,
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
      id: json['id'],
      category:
          json['category'] != null ? Category.fromJson(json['category']) : null,
    );
  }
}

class DataKeuangan {
  final String tanggal;
  final String jumlah;

  DataKeuangan(this.tanggal, this.jumlah);
}

class DataKeuanganDikelompokkan {
  final String tanggal;
  final String totalJumlah;
  final List<Pemasukan> items;

  DataKeuanganDikelompokkan(this.tanggal, this.totalJumlah, this.items);

  factory DataKeuanganDikelompokkan.dariPemasukan(List<Pemasukan> pemasukan) {
    final dataDigroup = pemasukan.fold<Map<String, List<Pemasukan>>>(
      {},
      (map, item) {
        if (!map.containsKey(item.date)) {
          map[item.date] = [];
        }
        map[item.date]!.add(item);
        return map;
      },
    );

    return DataKeuanganDikelompokkan(
      dataDigroup.keys.first,
      dataDigroup.values.first.fold(
          '0',
          (sum, item) =>
              (double.parse(sum) + double.parse(item.jumlah)).toString()),
      dataDigroup.values.first,
    );
  }
}

class JumlahPerBulan {
  final String bulan;
  final String totalJumlah;
  final List<Pemasukan> items;

  JumlahPerBulan(this.bulan, this.totalJumlah, this.items);

  factory JumlahPerBulan.dariPemasukan(List<Pemasukan> pemasukan) {
    final dataDigroup = pemasukan.fold<Map<String, List<Pemasukan>>>(
      {},
      (map, item) {
        final bulanTahun =
            item.date.substring(0, 7); // Asumsi format tanggal 'YYYY-MM-DD'
        if (!map.containsKey(bulanTahun)) {
          map[bulanTahun] = [];
        }
        map[bulanTahun]!.add(item);
        return map;
      },
    );

    return JumlahPerBulan(
      dataDigroup.keys.first,
      dataDigroup.values.first.fold(
          '0',
          (sum, item) =>
              (double.parse(sum) + double.parse(item.jumlah)).toString()),
      dataDigroup.values.first,
    );
  }
}

class JumlahPerTahun {
  final String tahun;
  final String totalJumlah;
  final List<Pemasukan> items;

  JumlahPerTahun(this.tahun, this.totalJumlah, this.items);

  factory JumlahPerTahun.dariPemasukan(List<Pemasukan> pemasukan) {
    final dataDigroup = pemasukan.fold<Map<String, List<Pemasukan>>>(
      {},
      (map, item) {
        final tahun =
            item.date.substring(0, 4); // Asumsi format tanggal 'YYYY-MM-DD'
        if (!map.containsKey(tahun)) {
          map[tahun] = [];
        }
        map[tahun]!.add(item);
        return map;
      },
    );

    return JumlahPerTahun(
      dataDigroup.keys.first,
      dataDigroup.values.first.fold(
          '0',
          (sum, item) =>
              (double.parse(sum) + double.parse(item.jumlah)).toString()),
      dataDigroup.values.first,
    );
  }
}

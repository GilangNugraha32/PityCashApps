import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:pity_cash/models/category_model.dart';
import 'package:dio/dio.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/models/outcomes_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // final String baseUrl = "http://192.168.0.211:8000/api";
  final String baseUrl = "http://pitycash.mamorasoft.com/api";
  final Dio _dio = Dio();

  ApiService() {
    _dio.options.headers['Content-Type'] = 'application/json';
    _setAuthToken();
  }

  // Set Auth Token in header
  Future<void> _setAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Token: $token'); // Log untuk melihat token
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<double> fetchSaldopPemasukkanKeseluruhan() async {
    try {
      await _setAuthToken();
      final response = await _dio.get('$baseUrl/income/saldo');

      print('Response status code: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map && response.data.containsKey('data')) {
          final double saldoKeseluruhan =
              double.parse(response.data['data'].toString());
          return saldoKeseluruhan;
        } else {
          throw Exception('Data saldo keseluruhan tidak valid');
        }
      } else {
        throw Exception(
            'Gagal mengambil saldo keseluruhan: ${response.statusCode}');
      }
    } catch (e) {
      print('Error mengambil saldo keseluruhan: $e');
      throw Exception('Gagal mengambil saldo keseluruhan');
    }
  }

  Future<double> fetchSaldo() async {
    try {
      await _setAuthToken();
      final response = await _dio.get(
        '$baseUrl/income/saldo',
      );

      print('Response status code: ${response.statusCode}'); // Log status code
      print('Response data: ${response.data}'); // Log data yang diterima

      if (response.statusCode == 200) {
        // Cek format dari response.data
        if (response.data is Map) {
          final double saldo = double.parse(response.data['1'].toString());
          return saldo;
        } else {
          throw Exception('Response data is not a valid map');
        }
      } else {
        throw Exception('Failed to fetch saldo: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching saldo: $e');
      throw Exception('Failed to fetch saldo');
    }
  }

  Future<double> fetchPengeluaranSaldoSeluruh() async {
    try {
      await _setAuthToken();
      final response = await _dio.get('$baseUrl/income/saldo');

      print('Response status code: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map && response.data.containsKey('0')) {
          final double minSaldo = double.parse(response.data['0'].toString());
          return minSaldo;
        } else {
          throw Exception('Data saldo minimum tidak valid');
        }
      } else {
        throw Exception(
            'Gagal mengambil saldo minimum: ${response.statusCode}');
      }
    } catch (e) {
      print('Error mengambil saldo minimum: $e');
      throw Exception('Gagal mengambil saldo minimum');
    }
  }

  Future<double> fetchMinimalSaldo() async {
    print('Mengambil saldo minimal');
    try {
      await _setAuthToken();
      final response = await _dio.get('$baseUrl/setting/edit-minimal-saldo');

      print('Kode status respons: ${response.statusCode}');
      print('Data respons: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map &&
            response.data.containsKey('data') &&
            response.data['data'] is Map &&
            response.data['data'].containsKey('saldo')) {
          final double minimalSaldo =
              double.parse(response.data['data']['saldo'].toString());
          return minimalSaldo;
        } else {
          throw Exception('Data saldo minimal tidak valid');
        }
      } else {
        throw Exception(
            'Gagal mengambil saldo minimal: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat mengambil saldo minimal: ${e.response?.data}');
        throw Exception(
            'Gagal mengambil saldo minimal: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat mengambil saldo minimal: $e');
        throw Exception('Gagal mengambil saldo minimal');
      }
    }
  }

  Future<void> updateMinimalSaldo(double minimalSaldo) async {
    print('Memperbarui saldo minimal: $minimalSaldo');
    try {
      await _setAuthToken();
      final response = await _dio.post(
        '$baseUrl/setting/update-minimal-saldo',
        data: {'saldo_hidden': minimalSaldo},
      );

      print('Kode status respons: ${response.statusCode}');
      print('Data respons: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 200 &&
            responseData['message'] == "Minimal saldo berhasil diperbarui") {
          print('Saldo minimal berhasil diperbarui');
          print('Data yang diperbarui: ${responseData['data']}');
        } else {
          throw Exception('Respons tidak sesuai yang diharapkan');
        }
      } else {
        throw Exception(
            'Gagal memperbarui saldo minimal: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat memperbarui saldo minimal: ${e.response?.data}');
        throw Exception(
            'Gagal memperbarui saldo minimal: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat memperbarui saldo minimal: $e');
        throw Exception('Gagal memperbarui saldo minimal');
      }
    }
  }

  // Fetch all categories with pagination
  Future<List<Category>> fetchCategories({int page = 1}) async {
    print('Mengambil kategori dari halaman: $page');
    try {
      await _setAuthToken();

      // Ambil roles dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final rolesString = prefs.getString('roles');
      final roles = rolesString != null ? json.decode(rolesString) : null;

      final response = await _dio.get(
        '$baseUrl/category/all',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data['data']['data'] as List;
        print('Kategori yang diambil: $data');

        // Simpan roles untuk penggunaan selanjutnya
        if (roles != null) {
          await prefs.setString('roles', json.encode(roles));
        }

        return data
            .map((categoryJson) => Category.fromJson(categoryJson))
            .toList();
      } else {
        throw Exception('Gagal memuat kategori');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat mengambil kategori: ${e.response?.data}');
      } else {
        print('Error saat mengambil kategori: $e');
      }
      throw Exception('Gagal memuat kategori');
    }
  }

  // Fetch all categories with pagination
  Future<List<Category>> fetchAllCategories({int page = 1}) async {
    print('Fetching categories from page: $page');
    try {
      await _setAuthToken();
      final response = await _dio.get(
        '$baseUrl/category/all',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data['data']['data'] as List;
        print('Categories fetched: $data'); // Print the fetched data
        return data
            .map((categoryJson) => Category.fromJson(categoryJson))
            .toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError fetching categories: ${e.response?.data}');
      } else {
        print('Error fetching categories: $e');
      }
      throw Exception('Failed to load categories');
    }
  }

  // Fetch category detail by ID
  Future<Category> fetchCategoryDetail(int id) async {
    print('Fetching category detail for ID: $id');
    try {
      await _setAuthToken();
      final response = await _dio.get('$baseUrl/category/detail/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return Category.fromJson(data);
      } else {
        throw Exception('Failed to load category detail');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError fetching category detail: ${e.response?.data}');
      } else {
        print('Error fetching category detail: $e');
      }
      throw Exception('Failed to load category detail');
    }
  }

  // Update category
  Future<void> updateCategory(
      int id, String name, int jenisKategori, String description) async {
    print(
        'Updating category ID: $id with name: $name, jenisKategori: $jenisKategori');
    try {
      await _setAuthToken();
      final response = await _dio.put(
        '$baseUrl/category/update/$id',
        data: {
          'name': name,
          'jenis_kategori': jenisKategori,
          'description': description,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Category updated successfully');
      } else {
        String errorMessage =
            response.data['message'] ?? 'Failed to update category';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError updating category: ${e.response?.data}');
        throw Exception(
            'Failed to update category: ${e.response?.data['message'] ?? 'Unknown error'}');
      } else {
        print('Error updating category: $e');
        throw Exception('Failed to update category');
      }
    }
  }

  // Menampilkan foto profil pengguna
  Future<String> showProfilePicture() async {
    print('Menampilkan foto profil');
    try {
      await _setAuthToken();

      final response = await _dio.get(
        '$baseUrl/user/profile-picture',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        print('Foto profil berhasil ditampilkan');
        // Mengkonversi response bytes menjadi base64
        final bytes = response.data as List<int>;
        final base64Image = base64Encode(bytes);
        return 'data:image/png;base64,$base64Image';
      } else {
        throw Exception(
            'Gagal menampilkan foto profil: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat menampilkan foto profil: ${e.response?.data}');
        throw Exception(
            'Gagal menampilkan foto profil: ${e.response?.statusMessage ?? e.message}');
      } else {
        print('Error saat menampilkan foto profil: $e');
        throw Exception('Gagal menampilkan foto profil: $e');
      }
    }
  }

  // Create category
  Future<void> createCategory(
      String name, int jenisKategori, String description) async {
    print('Creating category with name: $name, jenisKategori: $jenisKategori');
    try {
      await _setAuthToken();
      final response = await _dio.post(
        '$baseUrl/category/store',
        data: {
          'name': name,
          'jenis_kategori': jenisKategori, // Ensure correct key
          'description': description,
        },
      );

      if (response.statusCode == 201) {
        print('Category created successfully');
      } else {
        throw Exception('Failed to create category');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError creating category: ${e.response?.data}');
      } else {
        print('Error creating category: $e');
      }
      throw Exception('Failed to create category');
    }
  }

  // Delete category
  Future<void> deleteCategory(int id) async {
    print('Deleting category ID: $id');
    try {
      await _setAuthToken();
      final response = await _dio.delete('$baseUrl/category/destroy/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Category deleted successfully');
      } else {
        String errorMessage =
            response.data['message'] ?? 'Failed to delete category';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError deleting category: ${e.response?.data}');
        throw Exception(
            'Failed to delete category: ${e.response?.data['message'] ?? 'Unknown error'}');
      } else {
        print('Error deleting category: $e');
        throw Exception('Failed to delete category');
      }
    }
  }

  // Unduh template Excel kategori
  Future<String> downloadCategoryTemplate() async {
    print('Mengunduh template Excel kategori');
    try {
      await _setAuthToken(); // Set auth token if necessary

      // Request permission to write to external storage
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Izin penyimpanan tidak diberikan');
      }

      final response = await _dio.get(
        '$baseUrl/category/template',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final bytes = response.data;

        // Gunakan direktori Download untuk penyimpanan internal
        Directory? downloadsDir = await getApplicationDocumentsDirectory();
        if (downloadsDir == null) {
          throw Exception('Tidak dapat menemukan direktori Download');
        }

        String downloadsPath = '${downloadsDir.path}/Download';
        // Pastikan direktori Download ada
        await Directory(downloadsPath).create(recursive: true);

        final file = File('$downloadsPath/template_kategori.xlsx');

        await file.writeAsBytes(bytes);
        print('Template kategori berhasil diunduh: ${file.path}');
        return file.path;
      } else {
        throw Exception('Gagal mengunduh template kategori');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat mengunduh template: ${e.response?.data}');
        throw Exception(
            'Gagal mengunduh template: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat mengunduh template: $e');
        throw Exception('Gagal mengunduh template kategori');
      }
    }
  }

  // Import kategori menggunakan Excel
  Future<List<Map<String, dynamic>>> importCategoryFromExcel(
      String filePath) async {
    print('Mengimpor kategori dari Excel: $filePath');

    try {
      await _setAuthToken();

      // Generate random string untuk nama file yang akan dikirim ke server
      String randomString = '';
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final random = Random();
      for (var i = 0; i < 16; i++) {
        randomString += chars[random.nextInt(chars.length)];
      }

      // Buat temporary file dengan nama random
      final tempDir = await getTemporaryDirectory();
      final originalFile = File(filePath);
      final fileExtension = filePath.split('.').last;
      final randomFileName = '$randomString.$fileExtension';
      final tempFile = File('${tempDir.path}/$randomFileName');

      // Copy file asli ke temporary file
      await originalFile.copy(tempFile.path);

      print('Nama file yang diacak untuk server: $randomFileName');

      // Gunakan temporary file untuk upload
      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          tempFile.path,
          filename:
              randomFileName, // Pastikan nama file yang dikirim ke server sudah diacak
        ),
      });

      final response = await _dio.post(
        '$baseUrl/category/import',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Accept': 'application/json',
          },
        ),
      );

      // Hapus temporary file setelah upload
      await tempFile.delete();

      print('Respons server: ${response.data}');

      if (response.statusCode == 200) {
        print('Kategori berhasil diimpor');

        if (response.data is Map<String, dynamic>) {
          final status = response.data['status'];
          final message = response.data['message'];
          final importedData = response.data['data'];

          if (status == 200 &&
              message == "Data berhasil diimpor" &&
              importedData != null &&
              importedData is List) {
            print('Data yang diimpor:');

            List<Map<String, dynamic>> importedCategories = [];
            for (var item in importedData) {
              // Filter data null dan kosong
              if (item['Nama'] != null &&
                  item['Jenis Kategori'] != null &&
                  item['Deskripsi'] != null &&
                  item['Nama'].toString().trim().isNotEmpty) {
                print(
                    '- Nama: ${item['Nama']}, Jenis Kategori: ${item['Jenis Kategori']}, Deskripsi: ${item['Deskripsi']}');
                importedCategories.add({
                  'Nama': item['Nama'],
                  'Jenis Kategori': item['Jenis Kategori'],
                  'Deskripsi': item['Deskripsi'],
                });
              }
            }

            if (importedCategories.isEmpty) {
              throw Exception('Tidak ada data valid untuk diimpor');
            }

            return importedCategories;
          } else {
            print('Format data tidak sesuai atau tidak ada data valid.');
            return [];
          }
        } else {
          throw Exception('Format respons tidak sesuai');
        }
      } else {
        throw Exception('Gagal mengimpor kategori: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        final responseData = e.response?.data;
        String errorMessage = 'Error tidak diketahui';

        if (responseData != null && responseData is Map<String, dynamic>) {
          final errorString = responseData['error']?.toString();
          if (errorString != null && errorString.contains('Duplicate entry')) {
            errorMessage = 'Nama kategori sudah ada di database';
          } else {
            errorMessage = responseData['message'] ?? 'Error tidak diketahui';
          }
        }

        print('DioError saat mengimpor kategori: $responseData');
        throw Exception('Gagal mengimpor kategori: $errorMessage');
      } else {
        print('Error saat mengimpor kategori: $e');
        throw Exception('Gagal mengimpor kategori: $e');
      }
    }
  }

  Future<String> exportCategoryPDF() async {
    print('Mengekspor kategori ke PDF');
    try {
      await _setAuthToken(); // Pastikan token autentikasi diatur

      final response = await _dio.get(
        '$baseUrl/category/export',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Mendapatkan direktori dokumen
        Directory? downloadsDir = await getApplicationDocumentsDirectory();
        if (downloadsDir == null) {
          throw Exception('Tidak dapat menemukan direktori Download');
        }

        String downloadsPath = '${downloadsDir.path}/Download';
        // Pastikan direktori Download ada
        await Directory(downloadsPath).create(recursive: true);

        final fileName =
            'kategori_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final filePath = '$downloadsPath/$fileName';

        // Menyimpan file PDF
        File(filePath).writeAsBytesSync(response.data);

        print('PDF kategori berhasil diekspor ke: $filePath');
        return filePath;
      } else {
        throw Exception(
            'Gagal mengekspor kategori ke PDF: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat mengekspor kategori: ${e.response?.data}');
        throw Exception(
            'Gagal mengekspor kategori: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat mengekspor kategori: $e');
        throw Exception('Gagal mengekspor kategori ke PDF');
      }
    }
  }

  // Fetch all incomes with pagination
  Future<List<Pemasukan>> fetchIncomes({int page = 1}) async {
    print('Fetching incomes from page: $page');
    await _setAuthToken(); // Ensure the authentication token is set

    try {
      final response = await _dio.get(
        '$baseUrl/income/all',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        // Ensure the response structure matches your expectations
        final incomeData = response.data['data']['data'] as List;
        print('Incomes fetched: $incomeData');

        // Check if incomeData is empty
        if (incomeData.isEmpty) {
          print('No incomes found for page $page');
          return []; // Return an empty list if no data found
        }

        // Map each JSON object to Pemasukan
        return incomeData.map((incomeJson) {
          return Pemasukan.fromJson(incomeJson);
        }).toList();
      } else {
        throw Exception('Failed to load incomes: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError fetching incomes: ${e.response?.data}');
      } else {
        print('Error fetching incomes: $e');
      }
      throw Exception('Failed to load incomes'); // Propagate the error
    }
  }

  Future<Pemasukan> fetchPemasukanDetail(int id) async {
    print('Fetching category detail for ID: $id');
    try {
      await _setAuthToken();
      final response = await _dio.get('$baseUrl/income/detail/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return Pemasukan.fromJson(data);
      } else {
        throw Exception('Failed to load income detail');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError fetching income detail: ${e.response?.data}');
      } else {
        print('Error fetching income detail: $e');
      }
      throw Exception('Failed to load income detail');
    }
  }

  Future<void> createPemasukan(
    BuildContext context, {
    required String name,
    required String description,
    required String date,
    required String jumlah,
    required int jenisKategori,
  }) async {
    // Validate input fields
    if (name.isEmpty ||
        description.isEmpty ||
        date.isEmpty ||
        jumlah.isEmpty ||
        jenisKategori <= 0) {
      throw Exception('All fields must be provided');
    }

    print('Creating income with name: $name, jenisKategori: $jenisKategori');

    try {
      await _setAuthToken(); // Ensure your token is set for authentication

      final response = await _dio.post(
        '$baseUrl/income/store',
        data: {
          'name': name,
          'description': description,
          'date': date,
          'jumlah': jumlah,
          'category_id': jenisKategori,
        },
      );

      if (response.statusCode == 201) {
        print('Income created successfully: ${response.data}');
        Navigator.pop(context, response.data); // Sends the created data back
      } else {
        print('Failed to create income: ${response.data}');
        throw Exception('Failed to create income: ${response.data}');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError creating income: ${e.response?.data}');
        throw Exception('Failed to create income: ${e.response?.data}');
      } else {
        print('Error creating income: $e');
        throw Exception('Failed to create income');
      }
    }
  }

  Future<void> updateIncomes(int id, String name, String description,
      String date, String jumlah, int categoryId) async {
    print('Updating income ID: $id');

    // Prepare the log of updated fields
    Map<String, dynamic> updatedFields = {
      'name': name,
      'description': description,
      'jumlah': jumlah,
      'date': date,
      'id': categoryId
    };

    try {
      await _setAuthToken(); // Ensure you set the authorization token if needed

      final response = await _dio.put(
        '$baseUrl/income/update/$id',
        data: updatedFields,
      );

      // Check for success status codes
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Income updated successfully with the following updates:');
        updatedFields.forEach((key, value) {
          print('$key: $value');
        });
      } else {
        String errorMessage =
            response.data['message'] ?? 'Failed to update income';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError updating income: ${e.response?.data}');
        String errorMessage =
            e.response?.data['message'] ?? 'Unknown Dio error occurred';
        throw Exception('Failed to update income: $errorMessage');
      } else {
        print('Error updating income: $e');
        throw Exception('Failed to update income: $e');
      }
    }
  }

  Future<void> deleteIncome(int id) async {
    try {
      await _setAuthToken(); // Ensure the token is set before making the request
      final response = await _dio.delete('$baseUrl/income/destroy/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Income deleted successfully');
      } else {
        String errorMessage =
            response.data['message'] ?? 'Failed to delete income';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError deleting income: ${e.response?.data}');
        throw Exception(
            'Failed to delete income: ${e.response?.data['message'] ?? 'Unknown error'}');
      } else {
        print('Error deleting income: $e');
        throw Exception('Failed to delete income');
      }
    }
  }

  Future<String> downloadIncomeTemplate() async {
    try {
      await _setAuthToken(); // Pastikan token auth telah diatur

      final response = await _dio.get(
        '$baseUrl/income/template',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Mendapatkan direktori temporary untuk menyimpan file
        final tempDir = await getTemporaryDirectory();
        final tempPath = tempDir.path;
        final fileName = 'template_pemasukan.xlsx';
        final filePath = '$tempPath/$fileName';

        // Menulis data response ke file
        File file = File(filePath);
        await file.writeAsBytes(response.data);

        print('Template pemasukan berhasil diunduh: $filePath');
        return filePath;
      } else {
        throw Exception(
            'Gagal mengunduh template pemasukan: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        print(
            'DioError saat mengunduh template pemasukan: ${e.response?.data}');
        throw Exception(
            'Gagal mengunduh template pemasukan: ${e.response?.data['message'] ?? 'Kesalahan tidak diketahui'}');
      } else {
        print('Error saat mengunduh template pemasukan: $e');
        throw Exception('Gagal mengunduh template pemasukan');
      }
    }
  }

  Future<List<Map<String, dynamic>>> importIncomeFromExcel(
      String filePath) async {
    print('Mengimpor data pemasukan dari Excel: $filePath');

    try {
      await _setAuthToken(); // Pastikan token otorisasi diset sebelum request

      // Buat FormData untuk mengirim file
      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath,
            filename: 'template_pemasukan.xlsx'),
      });

      final response = await _dio.post(
        '$baseUrl/income/import',
        data: formData,
        options: Options(),
      );

      print('Respons server: ${response.data}');

      // Cek status code
      if (response.statusCode == 200) {
        print('Data pemasukan berhasil diimpor');

        // Validasi respons format JSON
        if (response.data is Map<String, dynamic>) {
          final status = response.data['status'];
          final message = response.data['message'];
          final importedData = response.data['data'];

          // Pastikan status dan data sesuai dengan yang diharapkan
          if (status == 200 &&
              message == "Data Berhasil Ditambahkan" &&
              importedData != null &&
              importedData is List) {
            print('Data yang diimpor:');

            List<Map<String, dynamic>> importedIncomes = [];
            for (var item in importedData) {
              print(
                  '- Nama: ${item['Nama']}, Deskripsi: ${item['Deskripsi']}, Tanggal: ${item['Tanggal']}, Jumlah: ${item['Jumlah']}, Kode Kategori: ${item['Kode Kategori']}');
              importedIncomes.add({
                'Nama': item['Nama'],
                'Deskripsi': item['Deskripsi'],
                'Tanggal': item['Tanggal'],
                'Jumlah': item['Jumlah'],
                'Kode Kategori': item['Kode Kategori'],
              });
            }
            return importedIncomes;
          } else {
            print('Format data tidak sesuai atau tidak ada data yang diimpor.');
            return [];
          }
        } else {
          throw Exception('Format respons tidak sesuai');
        }
      } else {
        throw Exception(
            'Gagal mengimpor data pemasukan: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        // Tangani kesalahan dari Dio (request ke server)
        final responseData = e.response?.data;
        final errorMessage =
            responseData != null && responseData is Map<String, dynamic>
                ? responseData['message'] ?? 'Error tidak diketahui'
                : 'Error tidak diketahui';

        print('DioError saat mengimpor data pemasukan: $responseData');
        throw Exception('Gagal mengimpor data pemasukan: $errorMessage');
      } else {
        // Tangani kesalahan lainnya
        print('Error saat mengimpor data pemasukan: $e');
        throw Exception('Gagal mengimpor data pemasukan: $e');
      }
    }
  }

  Future<String> exportIncomePDF() async {
    print('Mengekspor pemasukan ke PDF');
    try {
      await _setAuthToken(); // Pastikan token autentikasi diatur

      final response = await _dio.get(
        '$baseUrl/income/export/pdf',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Mendapatkan direktori dokumen
        Directory? downloadsDir = await getApplicationDocumentsDirectory();
        if (downloadsDir == null) {
          throw Exception('Tidak dapat menemukan direktori Download');
        }

        String downloadsPath = '${downloadsDir.path}/Download';
        // Pastikan direktori Download ada
        await Directory(downloadsPath).create(recursive: true);

        final fileName =
            'pemasukan_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final filePath = '$downloadsPath/$fileName';

        // Menyimpan file PDF
        File(filePath).writeAsBytesSync(response.data);

        print('PDF pemasukan berhasil diekspor ke: $filePath');
        return filePath;
      } else {
        throw Exception(
            'Gagal mengekspor pemasukan ke PDF: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat mengekspor pemasukan: ${e.response?.data}');
        throw Exception(
            'Gagal mengekspor pemasukan: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat mengekspor pemasukan: $e');
        throw Exception('Gagal mengekspor pemasukan ke PDF: $e');
      }
    }
  }
  // End of Selection

  Future<String> exportIncomeExcel() async {
    print('Mengekspor pemasukan ke Excel');
    try {
      await _setAuthToken(); // Pastikan token autentikasi diatur

      final response = await _dio.post(
        '$baseUrl/income/export/excel',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Mendapatkan direktori dokumen
        Directory? downloadsDir = await getApplicationDocumentsDirectory();
        if (downloadsDir == null) {
          throw Exception('Tidak dapat menemukan direktori Download');
        }

        String downloadsPath = '${downloadsDir.path}/Download';
        // Pastikan direktori Download ada
        await Directory(downloadsPath).create(recursive: true);

        final fileName =
            'pemasukan_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final filePath = '$downloadsPath/$fileName';

        // Menyimpan file Excel
        File(filePath).writeAsBytesSync(response.data);

        print('Excel pemasukan berhasil diekspor ke: $filePath');
        return filePath;
      } else {
        throw Exception(
            'Gagal mengekspor pemasukan ke Excel: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat mengekspor pemasukan: ${e.response?.data}');
        throw Exception(
            'Gagal mengekspor pemasukan: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat mengekspor Excel: $e');
        throw Exception('Gagal mengekspor Excel pemasukan');
      }
    }
  }

  Future<List<Pengeluaran>> fetchExpenses({
    int page = 1,
    DateTimeRange? dateRange,
  }) async {
    print('Mengambil data pengeluaran dari halaman: $page');
    try {
      await _setAuthToken();

      final Map<String, dynamic> queryParams = {'page': page};

      if (dateRange != null) {
        queryParams['start_date'] =
            DateFormat('yyyy-MM-dd').format(dateRange.start);
        queryParams['end_date'] =
            DateFormat('yyyy-MM-dd').format(dateRange.end);
      }

      final response = await _dio.get(
        '$baseUrl/outcome/all',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> expenseData = response.data['data']['data'];
        print('Data pengeluaran berhasil diambil: ${expenseData.length} item');

        return expenseData.map((json) => Pengeluaran.fromJson(json)).toList();
      } else {
        throw Exception(
            'Gagal mengambil data pengeluaran: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat mengambil data pengeluaran: ${e.response?.data}');
        throw Exception(
            'Gagal mengambil data pengeluaran: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat mengambil data pengeluaran: $e');
        throw Exception('Gagal mengambil data pengeluaran');
      }
    }
  }

// Misalnya, fungsi ini untuk mendapatkan tanggal berdasarkan idParent
  Future<Map<int, DateTime?>> fetchTanggalMap() async {
    // Gantikan dengan logika untuk mengambil tanggal yang relevan
    // Contoh hardcode, sesuaikan dengan sumber data Anda
    return {
      1: DateTime.parse('2024-01-01'),
      2: DateTime.parse('2024-01-02'),
      // Tambahkan sesuai kebutuhan
    };
  }

  Future<Pengeluaran> fetchPengeluaranDetail(int id) async {
    print('Mengambil detail pengeluaran untuk ID: $id');
    try {
      await _setAuthToken();
      final response = await _dio.get('$baseUrl/outcome/detail/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        print('Data detail pengeluaran: $data'); // Tambahkan log data

        if (data != null) {
          return Pengeluaran.fromJson(data);
        } else {
          throw Exception('Data detail pengeluaran kosong');
        }
      } else {
        throw Exception(
            'Gagal memuat detail pengeluaran: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        print(
            'DioError saat mengambil detail pengeluaran: ${e.response?.data}');
        throw Exception(
            'Gagal memuat detail pengeluaran: ${e.response?.statusMessage}');
      } else {
        print('Error saat mengambil detail pengeluaran: $e');
        throw Exception('Gagal memuat detail pengeluaran: $e');
      }
    }
  }

  Future<String> fetchPengeluaranImage(int id) async {
    print('Mengambil gambar pengeluaran untuk ID: $id');
    try {
      await _setAuthToken();
      final response = await _dio.get(
        '$baseUrl/outcome/image/$id',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        print('Gambar pengeluaran berhasil diambil');
        // Mengkonversi response bytes menjadi base64
        final bytes = response.data as List<int>;
        final base64Image = base64Encode(bytes);
        return 'data:image/png;base64,$base64Image';
      } else {
        throw Exception(
            'Gagal mengambil gambar pengeluaran: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        print(
            'DioError saat mengambil gambar pengeluaran: ${e.response?.data}');
        throw Exception(
            'Gagal mengambil gambar pengeluaran: ${e.response?.statusMessage ?? e.message}');
      } else {
        print('Error saat mengambil gambar pengeluaran: $e');
        throw Exception('Gagal mengambil gambar pengeluaran: $e');
      }
    }
  }

  Future<void> createPengeluaran(
    List<String> names,
    List<String> descriptions,
    List<String> parentDates,
    List<int> jumlahs,
    List<int> jumlahSatuans,
    List<double> nominals,
    List<double> dls,
    List<int> categoryIds,
    List<File> files,
  ) async {
    try {
      // Prepare form data
      var formData = FormData();

      // Add basic fields as arrays
      formData.fields.addAll([
        for (int i = 0; i < names.length; i++) MapEntry('name[]', names[i]),
        for (int i = 0; i < descriptions.length; i++)
          MapEntry('description[]', descriptions[i]),
        for (int i = 0; i < parentDates.length; i++)
          MapEntry('tanggal[]', parentDates[i]),
        for (int i = 0; i < jumlahs.length; i++)
          MapEntry('jumlah[]', jumlahs[i].toString()),
        for (int i = 0; i < jumlahSatuans.length; i++)
          MapEntry('jumlah_satuan[]', jumlahSatuans[i].toString()),
        for (int i = 0; i < nominals.length; i++)
          MapEntry('nominal[]', nominals[i].toString()),
        for (int i = 0; i < dls.length; i++)
          MapEntry('dll[]', dls[i].toString()),
        for (int i = 0; i < categoryIds.length; i++)
          MapEntry('category_id[]', categoryIds[i].toString()),
      ]);

      // Add files if they exist
      if (files.isNotEmpty) {
        for (int i = 0; i < files.length; i++) {
          if (files[i].path.isNotEmpty) {
            String fileName = files[i].path.split('/').last;
            formData.files.add(
              MapEntry(
                'image[]',
                await MultipartFile.fromFile(
                  files[i].path,
                  filename: fileName,
                ),
              ),
            );
          }
        }
      }

      print('Mengirim request dengan form data: ${formData.fields}');
      print('Files yang akan dikirim: ${formData.files.length}');

      await _setAuthToken();
      final response = await _dio.post(
        '$baseUrl/outcome/store',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201) {
        print('Pengeluaran berhasil ditambahkan: ${response.data}');
        // Mengambil path gambar dari response
        if (response.data['data'] != null &&
            response.data['data']['image'] != null) {
          String imagePath = response.data['data']['image'];
          print('Path gambar tersimpan: $imagePath');
        }
      } else {
        throw Exception('Gagal membuat pengeluaran: ${response.data}');
      }
    } catch (e) {
      print('Error dalam ApiService: $e');
      if (e is DioError) {
        print('Response data: ${e.response?.data}');
        print('Response status code: ${e.response?.statusCode}');
        print('Response headers: ${e.response?.headers}');
      }
      throw Exception('Error dalam ApiService: $e');
    }
  }

  Future<void> editPengeluaran(
    int parentId,
    List<String> tanggalList,
    List<int> dataIds,
    List<String> names,
    List<String> descriptions,
    List<int> jumlahs,
    List<int> jumlahSatuans,
    List<double> nominals,
    List<double> dls,
    List<int> categoryIds,
    List<File> files,
  ) async {
    try {
      var formData = FormData();

      // Add parent ID
      formData.fields.add(MapEntry('id_parent', parentId.toString()));

      // Add tanggal as single field
      formData.fields.add(MapEntry('tanggal', tanggalList.first));

      // Add basic fields as arrays
      for (int i = 0; i < names.length; i++) {
        formData.fields.addAll([
          MapEntry('id_data[]', dataIds[i].toString()),
          MapEntry('name[]', names[i]),
          MapEntry('description[]', descriptions[i]),
          MapEntry('jumlah[]', jumlahs[i].toString()),
          MapEntry('jumlah_satuan[]', jumlahSatuans[i].toString()),
          MapEntry('nominal[]', nominals[i].toString()),
          MapEntry('dll[]', dls[i].toString()),
          MapEntry('category_id[]', categoryIds[i].toString()),
        ]);
      }

      // Add files if they exist
      if (files.isNotEmpty) {
        for (int i = 0; i < files.length; i++) {
          if (files[i].path.isNotEmpty) {
            String fileName = files[i].path.split('/').last;
            formData.files.add(
              MapEntry(
                'image[]',
                await MultipartFile.fromFile(
                  files[i].path,
                  filename: fileName,
                ),
              ),
            );
          }
        }
      }

      print('Mengirim request dengan form data: ${formData.fields}');
      print('Files yang akan dikirim: ${formData.files.length}');

      await _setAuthToken();
      final response = await _dio.post(
        '$baseUrl/outcome/update/$parentId',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        print('Data updated successfully: ${response.data}');
        if (response.data['status'] == 'success') {
          print('Data berhasil diperbarui.');
          var responseData = response.data['data'];
          print('Parent ID: ${responseData['id']}');
          print('Tanggal: ${responseData['tanggal']}');

          if (responseData['pengeluaran'] != null) {
            for (var item in responseData['pengeluaran']) {
              print('ID Data: ${item['id_data']}');
              print('Name: ${item['name']}');
              print('Description: ${item['description']}');
              print('Image: ${item['image']}');
            }
          }
        } else {
          throw Exception('Failed to update data: ${response.data['message']}');
        }
      } else {
        throw Exception('Failed to update data: ${response.data}');
      }
    } catch (e) {
      print('Error dalam ApiService: $e');
      if (e is DioError) {
        print('Response data: ${e.response?.data}');
        print('Response status code: ${e.response?.statusCode}');
        print('Response headers: ${e.response?.headers}');
      }
      throw Exception('Error dalam ApiService: $e');
    }
  }

// Example method to upload files if necessary

  Future<void> deleteDataPengeluaran(int id) async {
    print('Deleting outcome ID: $id');
    try {
      await _setAuthToken(); // Pastikan token autentikasi diatur
      final response = await _dio.delete('$baseUrl/outcome/pengeluaran/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Outcome deleted successfully');
      } else {
        String errorMessage =
            response.data['message'] ?? 'Failed to delete outcome';
        throw Exception(errorMessage); // Lempar exception jika gagal
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError deleting outcome: ${e.response?.data}');
        throw Exception(
            'Failed to delete outcome: ${e.response?.data['message'] ?? 'Unknown error'}');
      } else {
        print('Error deleting outcome: $e');
        throw Exception(
            'Failed to delete outcome'); // Lempar exception untuk error lainnya
      }
    }
  }

  Future<void> deleteParentPengeluaran(int idParent) async {
    print('Deleting all outcomes for Parent ID: $idParent');
    try {
      await _setAuthToken(); // Ensure the authentication token is set
      final response =
          await _dio.delete('$baseUrl/outcome/pengeluaran/parent/$idParent');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('All outcomes deleted successfully');
      } else {
        String errorMessage =
            response.data['message'] ?? 'Failed to delete outcomes';
        throw Exception(errorMessage); // Throw exception if deletion failed
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError deleting outcomes: ${e.response?.data}');
        throw Exception(
            'Failed to delete outcomes: ${e.response?.data['message'] ?? 'Unknown error'}');
      } else {
        print('Error deleting outcomes: $e');
        throw Exception(
            'Failed to delete outcomes'); // Throw exception for other errors
      }
    }
  }

  Future<List<Map<String, dynamic>>> importPengeluaranFromExcel(
      String filePath) async {
    print('Mengimpor data pengeluaran dari Excel: $filePath');

    try {
      await _setAuthToken(); // Pastikan token otorisasi diset sebelum request

      // Buat FormData untuk mengirim file
      // Dapatkan nama file dari filePath
      String fileName = path.basename(filePath);

      // Buat FormData untuk mengirim file
      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _dio.post(
        '$baseUrl/outcome/import',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Accept': 'application/json',
          },
        ),
      );

      print('Respons server: ${response.statusCode}');

      // Cek status code
      if (response.statusCode == 200) {
        print('Data pengeluaran berhasil diimpor');

        // Validasi respons format JSON
        if (response.data is Map<String, dynamic>) {
          final status = response.data['status'];
          final message = response.data['message'];

          // Pastikan status sesuai dengan yang diharapkan
          if (status == 200 && message == "Data Berhasil Ditambahkan") {
            print('Import berhasil: $message');
            return []; // Mengembalikan list kosong karena tidak menampilkan data
          } else {
            print('Import gagal: $message');
            return [];
          }
        } else {
          throw Exception('Format respons tidak sesuai');
        }
      } else {
        throw Exception(
            'Gagal mengimpor data pengeluaran: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        // Tangani kesalahan dari Dio (request ke server)
        final responseData = e.response?.data;
        final errorMessage =
            responseData != null && responseData is Map<String, dynamic>
                ? responseData['message'] ?? 'Error tidak diketahui'
                : 'Error tidak diketahui';

        print('DioError saat mengimpor data pengeluaran: $errorMessage');
        throw Exception('Gagal mengimpor data pengeluaran: $errorMessage');
      } else {
        // Tangani kesalahan lainnya
        print('Error saat mengimpor data pengeluaran: $e');
        throw Exception('Gagal mengimpor data pengeluaran: $e');
      }
    }
  }

  Future<void> updateUserProfile({
    required String name,
    required String email,
    required String kelamin,
    required String alamat,
    File? foto_profil,
  }) async {
    print('Memperbarui profil pengguna');
    try {
      await _setAuthToken(); // Pastikan token autentikasi diatur

      FormData formData = FormData.fromMap({
        'name': name,
        'email': email,
        'kelamin': kelamin,
        'alamat': alamat,
      });

      if (foto_profil != null) {
        String fileName = foto_profil.path.split('/').last;
        formData.files.add(MapEntry(
          'foto_profil',
          await MultipartFile.fromFile(foto_profil.path, filename: fileName),
        ));
      }

      final response = await _dio.post(
        '$baseUrl/user/update-profile',
        data: formData,
      );

      if (response.statusCode == 200) {
        print('Profil pengguna berhasil diperbarui');
        // Anda mungkin ingin memperbarui data pengguna yang disimpan secara lokal di sini
      } else {
        String pesanError =
            response.data['message'] ?? 'Gagal memperbarui profil pengguna';
        throw Exception(pesanError);
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat memperbarui profil: ${e.response?.data}');
        throw Exception(
            'Gagal memperbarui profil: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat memperbarui profil: $e');
        throw Exception('Gagal memperbarui profil pengguna');
      }
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    print('Memperbarui kata sandi pengguna');
    try {
      await _setAuthToken(); // Pastikan token autentikasi diatur

      final response = await _dio.post(
        '$baseUrl/user/update-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );

      if (response.statusCode == 200) {
        print('Kata sandi pengguna berhasil diperbarui');
      } else {
        String pesanError =
            response.data['message'] ?? 'Gagal memperbarui kata sandi pengguna';
        throw Exception(pesanError);
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat memperbarui kata sandi: ${e.response?.data}');
        throw Exception(
            'Gagal memperbarui kata sandi: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat memperbarui kata sandi: $e');
        throw Exception('Gagal memperbarui kata sandi pengguna');
      }
    }
  }

  Future<String> exportPdfPengeluaran() async {
    print('Mengekspor PDF pengeluaran');
    try {
      await _setAuthToken(); // Pastikan token autentikasi diatur

      final response = await _dio.get(
        '$baseUrl/outcome/export/pdf',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Simpan file PDF ke penyimpanan lokal
        final bytes = response.data;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/pengeluaran_export.pdf');
        await file.writeAsBytes(bytes);

        print('PDF pengeluaran berhasil diekspor: ${file.path}');
        return file.path;
      } else {
        String pesanError =
            response.data['message'] ?? 'Gagal mengekspor PDF pengeluaran';
        throw Exception(pesanError);
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat mengekspor PDF: ${e.response?.data}');
        throw Exception(
            'Gagal mengekspor PDF: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat mengekspor PDF: $e');
        throw Exception('Gagal mengekspor PDF pengeluaran');
      }
    }
  }

  Future<String> exportExcelPengeluaran() async {
    print('Mengekspor Excel pengeluaran');
    try {
      await _setAuthToken(); // Pastikan token autentikasi diatur

      final response = await _dio.post(
        '$baseUrl/outcome/export/excel',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Simpan file Excel ke penyimpanan lokal
        final bytes = response.data;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/pengeluaran_export.xlsx');
        await file.writeAsBytes(bytes);

        print('Excel pengeluaran berhasil diekspor: ${file.path}');
        return file.path;
      } else {
        String pesanError =
            response.data['message'] ?? 'Gagal mengekspor Excel pengeluaran';
        throw Exception(pesanError);
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat mengekspor Excel: ${e.response?.data}');
        throw Exception(
            'Gagal mengekspor Excel: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat mengekspor Excel: $e');
        throw Exception('Gagal mengekspor Excel pengeluaran');
      }
    }
  }

  Future<String> downloadOutcomeTemplate() async {
    print('Mengunduh template pengeluaran');
    try {
      await _setAuthToken(); // Pastikan token autentikasi diatur

      final response = await _dio.get(
        '$baseUrl/outcome/template',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Simpan file template ke penyimpanan lokal
        final bytes = response.data;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/template_pengeluaran.xlsx');
        await file.writeAsBytes(bytes);

        print('Template pengeluaran berhasil diunduh: ${file.path}');
        return file.path;
      } else {
        String pesanError =
            response.data['message'] ?? 'Gagal mengunduh template pengeluaran';
        throw Exception(pesanError);
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat mengunduh template: ${e.response?.data}');
        throw Exception(
            'Gagal mengunduh template: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat mengunduh template: $e');
        throw Exception('Gagal mengunduh template pengeluaran');
      }
    }
  }

  Future<void> importOutcomeData(File file) async {
    print('Mengimpor data pengeluaran');
    try {
      await _setAuthToken(); // Pastikan token autentikasi diatur

      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post(
        '$baseUrl/outcome/import',
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      if (response.statusCode == 200) {
        print('Data pengeluaran berhasil diimpor');
      } else {
        String pesanError =
            response.data['message'] ?? 'Gagal mengimpor data pengeluaran';
        throw Exception(pesanError);
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError saat mengimpor data: ${e.response?.data}');
        throw Exception(
            'Gagal mengimpor data: ${e.response?.data['message'] ?? 'Error tidak diketahui'}');
      } else {
        print('Error saat mengimpor data: $e');
        throw Exception('Gagal mengimpor data pengeluaran');
      }
    }
  }
}

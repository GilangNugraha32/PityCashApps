import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pity_cash/models/category_model.dart';
import 'package:dio/dio.dart';
import 'package:pity_cash/models/incomes_model.dart';
import 'package:pity_cash/models/outcomes_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
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

  Future<double> fetchSaldo() async {
    try {
      await _setAuthToken();
      final response = await _dio.get(
        'http://pitycash.mamorasoft.com/api/income/saldo',
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

  // Fetch all categories with pagination
  Future<List<Category>> fetchCategories({int page = 1}) async {
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

  Future<List<Pengeluaran>> fetchExpenses({
    int page = 1,
    DateTimeRange? dateRange, // Menambahkan parameter date range
  }) async {
    print('Fetching expenses from page: $page');
    try {
      await _setAuthToken(); // Ensure the auth token is set

      // Menambahkan query parameter untuk date range jika ada
      final Map<String, dynamic> queryParams = {'page': page};

      if (dateRange != null) {
        queryParams['start_date'] =
            DateFormat('yyyy-MM-dd').format(dateRange.start);
        queryParams['end_date'] =
            DateFormat('yyyy-MM-dd').format(dateRange.end);
      }

      final response = await _dio.get(
        '$baseUrl/outcome/all',
        queryParameters: queryParams, // Menambahkan queryParams
      );

      print('Status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final expenseData = response.data['data']['data'] as List;
        print('Expenses fetched: $expenseData');

        // Create a list of Pengeluaran from the fetched expense data
        return expenseData.map((expenseJson) {
          return Pengeluaran.fromJson(expenseJson); // Call with single argument
        }).toList();
      } else {
        throw Exception('Failed to load expenses: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioError) {
        print('DioError fetching expenses: ${e.response?.data}');
      } else {
        print('Error fetching expenses: $e');
      }
      throw Exception('Failed to load expenses');
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

  Future<void> createPengeluaran(
    List<String> names,
    List<String> descriptions,
    List<String> parentDates, // Accept formatted dates
    List<int> jumlahs,
    List<int> jumlahSatuans,
    List<double> nominals,
    List<double> dls,
    List<int> categoryIds,
    List<File> files,
  ) async {
    try {
      List<Map<String, dynamic>> pengeluaranList = [];

      // Prepare the list of pengeluaran items
      for (int i = 0; i < names.length; i++) {
        pengeluaranList.add({
          'name': names[i],
          'description': descriptions[i],
          'jumlah_satuan': jumlahSatuans[i],
          'nominal': nominals[i],
          'dll': dls[i],
          'jumlah': jumlahs[i],
          'id': categoryIds[i], // Ensure this matches your API expectations
        });
      }

      // Check that parent dates are not empty
      if (parentDates.isEmpty) {
        throw Exception("At least one date must be provided.");
      }

      // Construct the request body
      Map<String, dynamic> requestBody = {
        'tanggal': parentDates, // Use the formatted parent dates directly
        'name': names,
        'description': descriptions,
        'jumlah_satuan': jumlahSatuans,
        'nominal': nominals,
        'dll': dls,
        'jumlah': jumlahs,
        'id': categoryIds,
        // 'image': images, // Include if you have images to upload
      };

      // Debugging: Log the request body
      print('Request Body: $requestBody');

      // Send the request
      await _setAuthToken(); // Assuming this method sets the auth token correctly
      final response =
          await _dio.post('$baseUrl/outcome/store', data: requestBody);

      // Check the response
      if (response.statusCode == 201) {
        print('Pengeluaran berhasil ditambahkan: ${response.data}');
      } else {
        throw Exception('Failed to create pengeluaran: ${response.data}');
      }
    } catch (e) {
      print('Error in ApiService: $e');
      if (e is DioError) {
        print('Response data: ${e.response?.data}');
        print('Response status code: ${e.response?.statusCode}');
        print('Response headers: ${e.response?.headers}');
      }
      throw Exception('Error in ApiService: $e');
    }
  }

  Future<void> editPengeluaran(
    int parentId,
    List<String> tanggalList, // List to hold dates for each entry
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
      List<Map<String, dynamic>> pengeluaranList = [];

      for (int i = 0; i < names.length; i++) {
        // Check for non-null values before adding to the list
        if (dataIds[i] != null &&
            names[i].isNotEmpty &&
            jumlahSatuans[i] != null &&
            nominals[i] != null &&
            jumlahs[i] != null &&
            categoryIds[i] != null) {
          pengeluaranList.add({
            'id_data': dataIds[i],
            'name': names[i],
            'description': descriptions[i], // Provide default if null
            'jumlah_satuan': jumlahSatuans[i].toString(), // Convert to String
            'nominal': nominals[i].toString(), // Convert to String
            'dll': dls[i].toString(), // Convert to String
            'jumlah': jumlahs[i].toString(), // Convert to String
            'id': categoryIds[i].toString(), // Convert to String
            'tanggal':
                tanggalList[i], // Use tanggal from the list for each entry
            // Add image data handling if applicable
            'image': files.isNotEmpty && files[i].path.isNotEmpty
                ? await _uploadFile(files[i]) // Ensure you upload the file
                : null,
          });
        } else {
          print(
              "Error: Missing required fields for pengeluaran item at index $i");
        }
      }

      if (pengeluaranList.isEmpty) {
        print("Error: No valid pengeluaran items to update.");
        return; // Exit early if no valid items
      }

      // Create the request body according to the API requirements
      Map<String, dynamic> requestBody = {
        'tanggal': tanggalList.isNotEmpty
            ? tanggalList.first
            : DateTime.now()
                .toIso8601String()
                .split('T')
                .first, // Default if list is empty
        'name': names,
        'description': descriptions,
        'jumlah_satuan': jumlahSatuans,
        'nominal': nominals,
        'jumlah': jumlahs,
        'dll': dls,
        'id': categoryIds,
        'image': files
            .map((file) => file.path)
            .toList(), // Ensure images are properly formatted
        'pengeluaran': pengeluaranList, // Include the list of pengeluaran items
      };

      print('Request Body: $requestBody');

      await _setAuthToken();
      final response = await _dio.put(
        '$baseUrl/outcome/update/$parentId',
        data: requestBody,
      );

      if (response.statusCode == 200) {
        print('Data updated successfully: ${response.data}');
        // Handle the successful response as needed
        if (response.data['status'] == 'success') {
          print(response.data['message']);
        }
      } else {
        print('Failed to update data: ${response.statusCode} ${response.data}');
      }
    } catch (e) {
      // Log error with more detail
      print('Error in ApiService: $e');
      // Check for specific exceptions if needed
      if (e is DioError) {
        // Handle DioError specifically
        print('DioError: ${e.response?.data} ${e.response?.statusCode}');
      }
    }
  }

// Example method to upload files if necessary
  Future<String?> _uploadFile(File file) async {
    try {
      // Implement your file upload logic here and return the image URL or null
      return null; // Replace with actual implementation
    } catch (e) {
      print('Error uploading file: $e');
      return null; // Handle the upload failure
    }
  }

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
}

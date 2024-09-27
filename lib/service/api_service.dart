import 'package:flutter/cupertino.dart';
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
        final incomeData = response.data['data']['data']
            as List; // Assuming 'data' contains a list of incomes
        print('Incomes fetched: $incomeData');

        return incomeData.map((incomeJson) {
          return Pemasukan.fromJson(
              incomeJson); // Map each JSON object to Pemasukan
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
      'category_id': categoryId
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

  Future<List<Pengeluaran>> fetchExpenses({int page = 1}) async {
    print('Fetching expenses from page: $page');
    try {
      await _setAuthToken(); // Pastikan untuk mengatur token otorisasi
      final response = await _dio.get(
        '$baseUrl/outcome/all',
        queryParameters: {'page': page},
      );

      print('Status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final expenseData = response.data['data']['data'] as List;
        print('Expenses fetched: $expenseData');
        return expenseData
            .map((expenseJson) => Pengeluaran.fromJson(expenseJson))
            .toList();
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
}

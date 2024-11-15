import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:pity_cash/main.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'dart:developer';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final Dio _dio = Dio();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await _prefsService.getToken();
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _login() async {
    final String apiUrl = "http://pitycash.mamorasoft.com/api/login";
//  final String apiUrl = "http://192.168.18.165:8000/api/login";

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _dio.post(
        apiUrl,
        data: {
          "email": _emailController.text,
          "password": _passwordController.text,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      var jsonResponse = response.data;
      log(jsonResponse.toString());

      if (jsonResponse['status'] == 200 && jsonResponse['user'] != null) {
        final token = jsonResponse['token'];
        final user = jsonResponse['user'];
        final userRoles = user['roles'];
        Map<String, dynamic> roles = {};

        if (userRoles != null && userRoles is List && userRoles.isNotEmpty) {
          roles = {
            'roles': userRoles
                .map((role) => {
                      'id': role['id'],
                      'name': role['name'],
                      'guard_name': role['guard_name'],
                      'created_at': role['created_at'],
                      'updated_at': role['updated_at'],
                    })
                .toList()
          };
          log("Roles found in user data: $roles");
        } else {
          log("Error: Exception: Roles data is null or empty");
        }

        if (token != null) {
          await _prefsService.saveToken(token);
          await _prefsService.saveUser(user);
          await _prefsService.saveRoles(roles);
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() {
          _errorMessage = jsonResponse['message'] ?? 'Login gagal';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Email dan Password anda salah!');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEB8153), Color(0xFFFF9D6C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: Hero(
                    tag: 'logo',
                    child: Container(
                      height: 80,
                      child: Image.asset("assets/piticash_log.png"),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Text(
                            "Selamat Datang !",
                            style: TextStyle(
                              color: Color(0xFFEB8153),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Silahkan masuk ke akun Anda",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 4),
                                TextFormField(
                                  controller: _emailController,
                                  style: TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan email',
                                    hintStyle: TextStyle(fontSize: 12),
                                    prefixIcon: Icon(
                                      Icons.email,
                                      color: Color(0xFFEB8153),
                                      size: 18,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Masukkan email'
                                      : null,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 4),
                                TextFormField(
                                  controller: _passwordController,
                                  style: TextStyle(fontSize: 14),
                                  obscureText: _obscureText,
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan kata sandi',
                                    hintStyle: TextStyle(fontSize: 12),
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: Color(0xFFEB8153),
                                      size: 18,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Color(0xFFEB8153),
                                        size: 18,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscureText = !_obscureText),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Masukkan password'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'MASUK',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              style: ElevatedButton.styleFrom(
                                primary: Color(0xFFEB8153),
                                onPrimary: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

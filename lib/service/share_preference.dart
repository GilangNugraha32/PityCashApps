import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _tokenKey = 'token';
  static const String _userKey = 'user';
  static const String _rolesKey = 'roles';
  static SharedPreferences? _instance;

  static Future<SharedPreferencesService> getInstance() async {
    if (_instance == null) {
      _instance = await SharedPreferences.getInstance();
    }
    return SharedPreferencesService();
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _userKey, json.encode(user)); // Save user as JSON string
  }

  Future<void> saveRoles(Map<String, dynamic> roles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _rolesKey, json.encode(roles)); // Save user as JSON string
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return Map<String, dynamic>.from(json.decode(userString));
    }
    return null;
  }

  Future<Map<String, dynamic>?> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final rolesString = prefs.getString(_rolesKey);
    if (rolesString != null) {
      return Map<String, dynamic>.from(json.decode(rolesString));
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getUserName() async {
    final user = await getUser();
    return user?['name']; // Get user's name
  }

  Future<String?> getUserEmail() async {
    final user = await getUser();
    return user?['email']; // Get user's email
  }

  Future<String?> getUserGender() async {
    final user = await getUser();
    return user?['kelamin']; // Get user's gender
  }

  Future<String?> getUserAddress() async {
    final user = await getUser();
    return user?['alamat']; // Get user's address
  }

  Future<String?> getUserPhotoUrl() async {
    final user = await getUser();
    if (user != null && user['profile_picture'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userPhotoUrl', user['profile_picture']);
      return user['profile_picture'];
    }
    return null;
  }

  Future<void> removeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<void> removeRoles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rolesKey);
  }

  // New method to print user data
  Future<void> printUserData() async {
    final user = await getUser();
    if (user != null) {
      print("User Data:");
      user.forEach((key, value) {
        print("$key: $value");
      });
    } else {
      print("No user data found.");
    }
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> removeUserData() async {
    await _instance?.remove('userName'); // Clear the user name
    await _instance?.remove('userEmail'); // Clear the user email
    await _instance?.remove(_rolesKey); // Clear the roles
    // Add more removals if there are other user data keys
  }
}

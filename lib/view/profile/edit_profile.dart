import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/service/api_service.dart';
import 'dart:io';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final ApiService _apiService = ApiService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  String? _selectedGender;
  File? _profileImage;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _prefsService.printUserData();
  }

  Future<void> _loadProfileData() async {
    final username = await _prefsService.getUserName();
    final email = await _prefsService.getUserEmail();
    final alamat = await _prefsService.getUserAddress();
    final gender = await _prefsService.getUserGender();
    final photoUrl = await _prefsService.getUserPhotoUrl();
    setState(() {
      _usernameController.text = username ?? 'Guest';
      _emailController.text = email ?? 'example@example.com';
      _alamatController.text = alamat ?? 'Malang';
      _selectedGender = (gender == 'laki-laki')
          ? 'Laki-Laki'
          : (gender == 'perempuan')
              ? 'Perempuan'
              : 'Tidak ada kelamin';
      _photoUrl = photoUrl;
    });
  }

  Future<void> _updateProfile() async {
    final username = _usernameController.text;
    final email = _emailController.text;
    final alamat = _alamatController.text;
    final gender = _selectedGender;

    if (username.isNotEmpty &&
        email.isNotEmpty &&
        alamat.isNotEmpty &&
        gender != null) {
      try {
        await _apiService.updateUserProfile(
          name: username,
          email: email,
          kelamin: gender.toLowerCase(),
          alamat: alamat,
          foto_profil: _profileImage,
        );

        await _prefsService.saveUser({
          'name': username,
          'email': email,
          'kelamin': gender.toLowerCase(),
          'alamat': alamat,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mohon isi semua field'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFEB8153),
          ),
        ),
        SizedBox(height: 8),
        Container(
          margin: EdgeInsets.only(bottom: 20),
          child: TextFormField(
            controller: controller,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Color(0xFFEB8153)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Color(0xFFEB8153), width: 1),
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFEB8153),
          ),
        ),
        SizedBox(height: 8),
        Container(
          margin: EdgeInsets.only(bottom: 20),
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            items: [
              DropdownMenuItem(value: 'Laki-Laki', child: Text('Laki-Laki')),
              DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person, color: Color(0xFFEB8153)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Color(0xFFEB8153), width: 1),
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEB8153), Color(0xFFFF9D6C)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(50.0),
                    bottomLeft: Radius.circular(50.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 40.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop(true);
                              }
                            },
                          ),
                          Text(
                            'Edit Profil',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.notifications,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              // Implementasi notifikasi
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      GestureDetector(
                        onTap: () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.image,
                          );
                          if (result != null) {
                            setState(() {
                              _profileImage = File(result.files.single.path!);
                            });
                          }
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: FutureBuilder<String>(
                                  future: ApiService().showProfilePicture(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white));
                                    } else if (snapshot.hasError) {
                                      print(
                                          'Error menampilkan foto profil: ${snapshot.error}');
                                      return Image.asset(
                                          'assets/piticash_log.png',
                                          fit: BoxFit.cover);
                                    } else if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      return Image.memory(
                                          base64Decode(
                                              snapshot.data!.split(',').last),
                                          fit: BoxFit.cover);
                                    } else {
                                      return Icon(Icons.person,
                                          size: 60, color: Colors.white);
                                    }
                                  },
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.camera_alt,
                                  color: Color(0xFFEB8153), size: 20),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        _usernameController.text,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _emailController.text,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                          'Nama', _usernameController, Icons.person_outline),
                      _buildTextField(
                          'Email', _emailController, Icons.email_outlined),
                      _buildTextField(
                          'Alamat', _alamatController, Icons.home_outlined),
                      _buildGenderDropdown(),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: Color(0xFFEB8153),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 0,
                        ),
                        child: Text('Perbarui Profil',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
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

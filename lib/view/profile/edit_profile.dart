import 'package:flutter/material.dart';
import 'package:pity_cash/service/share_preference.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _prefsService.printUserData(); // Add this line for debugging
  }

  Future<void> _loadProfileData() async {
    final username = await _prefsService.getUserName();
    final email = await _prefsService.getUserEmail();
    final alamat = await _prefsService.getUserAddress();
    // final gender =
    // await _prefsService.getUserGender(); // Load gender from preferences
    setState(() {
      _usernameController.text = username ?? 'Guest';
      _emailController.text = email ?? 'example@example.com';
      _alamatController.text = alamat ?? 'Malang';
      // _selectedGender = gender ?? 'Laki-Laki'; // Ensure this value is valid
    });
  }

  void _updateProfile() async {
    final username = _usernameController.text;
    final email = _emailController.text;
    final alamat = _alamatController.text;

    if (username.isNotEmpty &&
        email.isNotEmpty &&
        alamat.isNotEmpty &&
        _selectedGender != null) {
      // Update logic can go here, including saving the data back to SharedPreferences
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black),
            hintText: 'Enter your $label',
            fillColor: Colors.grey[200],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Color(0xFFEB8153)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Color(0xFFEB8153)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Color(0xFFEB8153)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          items: [
            DropdownMenuItem(value: 'Laki-Laki', child: Text('Laki-Laki')),
            DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGender = value; // Update pilihan gender
            });
          },
          decoration: InputDecoration(
            prefixIcon:
                Icon(Icons.female_sharp, color: Colors.black), // Ikon hitam
            hintText: 'Select your gender',
            fillColor: Colors.grey[200],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Color(0xFFEB8153)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Color(0xFFEB8153)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Color(0xFFEB8153)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFFEB8153), // Background color (orange)
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20.0),
                bottomLeft: Radius.circular(20.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
              child: Column(
                children: [
                  // Header dengan ikon di pojok kiri dan kanan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/piticash_log.png'),
                    backgroundColor: Colors.transparent,
                  ),

                  SizedBox(height: 8),

                  // Nama dan email berdasarkan login status
                  Text(
                    _usernameController.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    _emailController.text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 16),
                      _buildTextField(
                          'Name', _usernameController, Icons.person_outline),
                      _buildTextField(
                          'Email', _emailController, Icons.email_outlined),
                      _buildTextField(
                          'Address', _alamatController, Icons.home_outlined),
                      _buildGenderDropdown(), // Dropdown for gender
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: Color(0xFFEB8153),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text('Update Profile',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

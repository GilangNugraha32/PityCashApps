import 'package:flutter/material.dart';
import 'package:pity_cash/view/profile/change_password.dart';
import 'package:pity_cash/view/profile/edit_profile.dart';
import 'package:pity_cash/service/share_preference.dart';

class ProfileSection extends StatefulWidget {
  @override
  _ProfileSectionState createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  String? token;
  String? name = 'Guest';
  String? email = 'guest@gmail.com'; // Default email
  bool isLoggedIn = false;
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    token = await _prefsService.getToken();
    name = await _prefsService.getUserName();
    email = await _prefsService.getUserEmail();
    setState(() {
      isLoggedIn = token != null;
    });
  }

  Future<void> logout(BuildContext context) async {
    // Clear user token and any other relevant data from SharedPreferences
    await _prefsService
        .removeToken(); // Use the new method in SharedPreferencesService
    await _prefsService
        .removeUserData(); // Use the new method in SharedPreferencesService

    // Optionally, navigate to the login screen or home screen
    Navigator.of(context)
        .pushReplacementNamed('/login'); // Adjust the route name as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Bagian Atas Profil
          _buildProfileHeader(),

          SizedBox(height: 20),

          // Bagian Bawah dengan Tombol-tombol
          Expanded(
            child: Center(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  _buildButton(
                    context,
                    'Edit Profile',
                    Icons.person_outline,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfile()),
                      );
                    },
                  ),
                  _buildButton(
                    context,
                    'Change Password',
                    Icons.lock_outline_sharp,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChangePasswordProfile()),
                      );
                      // Aksi untuk mengubah password
                    },
                  ),
                  _buildButton(
                    context,
                    'Logout',
                    Icons.logout_outlined,
                    onPressed: () {
                      logout(
                          context); // Call the logout function when the button is pressed

                      // Aksi untuk logout
                    },
                  ),
                  SizedBox(height: 20), // Space at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
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
                Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                Text(
                  'Profile',
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
              isLoggedIn ? '$name' : 'Hi, Guest!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              isLoggedIn ? '$email' : 'guest@gmail.com',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, IconData icon,
      {required VoidCallback onPressed}) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
        width: MediaQuery.of(context).size.width * 0.9,
        height: 45,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFEB8153), // Background color (orange)
            foregroundColor: Colors.white, // Text color (white)
            padding: EdgeInsets.zero, // Remove default padding
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold // White text
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

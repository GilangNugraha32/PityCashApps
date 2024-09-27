import 'package:flutter/material.dart';
import 'package:pity_cash/view/profile/edit_profile.dart';

class ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Bagian Atas Profil
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFFEB8153), // Warna latar belakang orange
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20.0),
                bottomLeft: Radius.circular(20.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
              child: Column(
                children: [
                  // Ikon notifikasi di pojok kanan atas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hi, Syahrul!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                  // Judul "Profile"
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20, // Ukuran font judul
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Avatar bulat dengan foto
                  CircleAvatar(
                    radius: 50, // Ukuran avatar lebih besar
                    backgroundImage: AssetImage(
                        'assets/piticash_log.png'), // Ganti dengan path gambar Anda
                    backgroundColor: Colors.transparent,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Muhammad Syahrul',
                    style: TextStyle(
                      fontSize: 16, // Ukuran font nama
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          // Bagian Bawah dengan Tombol-tombol
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width *
                      2, // Button width nearly full width
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfile(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.zero, // Hilangkan padding default
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFFEB8153),
                          child: Icon(Icons.person_outline,
                              color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: Text('Edit Profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.9, // Button width nearly full width
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      // Aksi untuk Settings
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFFEB8153),
                          child: Icon(Icons.settings_outlined,
                              color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: Text('Settings'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.9, // Button width nearly full width
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      // Aksi untuk Logout
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFFEB8153),
                          child: Icon(Icons.logout_outlined,
                              color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: Text('Logout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20), // Add some space at the bottom
              ],
            ),
          ),
        ],
      ),
    );
  }
}

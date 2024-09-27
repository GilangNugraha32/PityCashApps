import 'package:flutter/material.dart';

class EditProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian Atas Profil
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height / 3.6,
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
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  // Judul "Profile"
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20, // Ukuran font judul
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  // Avatar bulat dengan foto
                  CircleAvatar(
                    radius: 30, // Ukuran avatar
                    backgroundImage: AssetImage(
                        'assets/piticash_log.png'), // Ganti dengan path gambar Anda
                    backgroundColor: Colors.transparent,
                  ),
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
          SizedBox(height: 8),
          // Bagian Bawah dengan Card dan Form Field
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch, // Tombol lebar penuh
                    children: [
                      Text(
                        'Account Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      // Teks di atas form Username
                      Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Form field Username
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Enter your username',
                          fillColor: Colors
                              .grey[200], // Warna latar belakang form field
                          filled: true, // Mengaktifkan warna latar belakang
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: Colors.orange), // Warna pembatas
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color:
                                    Colors.orange), // Warna pembatas saat fokus
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: Colors
                                    .orange), // Warna pembatas saat enabled
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Teks di atas form Password
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Form field Password
                      TextFormField(
                        obscureText: true, // Untuk input password
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          fillColor: Colors
                              .grey[200], // Warna latar belakang form field
                          filled: true, // Mengaktifkan warna latar belakang
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: Colors.orange), // Warna pembatas
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color:
                                    Colors.orange), // Warna pembatas saat fokus
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                                color: Colors
                                    .orange), // Warna pembatas saat enabled
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                      ),
                      SizedBox(height: 30),
                      // Tombol Update Profile
                      SizedBox(
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {
                            // Aksi untuk menyimpan perubahan
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Color(
                                0xFFEB8153), // Warna latar belakang button
                            onPrimary: Colors.white, // Warna teks button
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Text(
                            'Update Profile',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold, // Tebalkan teks tombol
                            ),
                          ),
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
    );
  }
}

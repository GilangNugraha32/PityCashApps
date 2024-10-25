// For mobile (iOS, Android)
import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html';

import 'package:flutter/material.dart';
import 'package:pity_cash/service/api_service.dart';
import 'package:pity_cash/view/profile/change_password.dart';
import 'package:pity_cash/view/profile/edit_profile.dart';
import 'package:pity_cash/service/share_preference.dart';
import 'package:pity_cash/view/profile/settings_saldo.dart';

class ProfileSection extends StatefulWidget {
  @override
  _ProfileSectionState createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  String? token;
  String? name = 'Guest';
  String? email = 'guest@gmail.com';
  String? photoUrl;
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
    photoUrl = await _prefsService.getUserPhotoUrl();
    setState(() {
      isLoggedIn = token != null;
    });
  }

  Future<void> logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Konfirmasi Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFEB8153),
            ),
          ),
          content: Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFEB8153),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await _prefsService.removeToken();
                await _prefsService.removeUserData();
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshProfile() async {
    await _checkLoginStatus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              SizedBox(height: 30),
              _buildProfileOptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEB8153), Color(0xFFFF9D6C)],
        ),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(30.0),
          bottomLeft: Radius.circular(30.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    // Implementasi notifikasi
                  },
                ),
              ],
            ),
            SizedBox(height: 30),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: FutureBuilder<String>(
                  future: ApiService().showProfilePicture(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      );
                    } else if (snapshot.hasError) {
                      print('Error menampilkan foto profil: ${snapshot.error}');
                      return Image.asset(
                        'assets/piticash_log.png',
                        fit: BoxFit.cover,
                      );
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return Image.memory(
                        base64Decode(snapshot.data!.split(',').last),
                        fit: BoxFit.cover,
                      );
                    } else {
                      return Icon(Icons.person, size: 60, color: Colors.white);
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 15),
            Text(
              isLoggedIn ? '$name' : 'Hi, Guest!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5),
            Text(
              isLoggedIn ? '$email' : 'guest@gmail.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0.25,
            child: Column(
              children: [
                _buildOptionButton(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfile()),
                  ).then((_) => _refreshProfile()),
                  showTrailingIcon: true,
                  showBorder: false,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                Divider(height: 0.5, thickness: 0.5),
                _buildOptionButton(
                  icon: Icons.lock_outline,
                  label: 'Ubah Password',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChangePasswordProfile()),
                  ).then((_) => _refreshProfile()),
                  showTrailingIcon: true,
                  showBorder: false,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          _buildOptionButton(
            icon: Icons.settings,
            label: 'Pengaturan Saldo',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsSaldo()),
            ).then((_) => _refreshProfile()),
          ),
          SizedBox(height: 15),
          _buildOptionButton(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () => logout(context),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required void Function() onTap,
    Color color = const Color(0xFFEB8153),
    bool showTrailingIcon = true,
    bool showBorder = true,
    BorderRadius? borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            borderRadius ?? (showBorder ? BorderRadius.circular(15) : null),
        color: Colors.white,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.zero,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: color, size: 18),
        onTap: onTap,
      ),
    );
  }
}

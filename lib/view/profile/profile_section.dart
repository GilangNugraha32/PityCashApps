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
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(
            'Konfirmasi Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFEB8153),
              fontSize: 14,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar?',
            style: TextStyle(fontSize: 12),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: Size(60, 30),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Logout', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFEB8153),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: Size(60, 30),
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
              SizedBox(height: 16),
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
          bottomRight: Radius.circular(20.0),
          bottomLeft: Radius.circular(20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12.0, 30.0, 12.0, 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon:
                      Icon(Icons.notifications, color: Colors.white, size: 18),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: FutureBuilder<String>(
                  future: ApiService().showProfilePicture(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      );
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return Icon(Icons.person, size: 40, color: Colors.white);
                    } else {
                      return Image.memory(
                        base64Decode(snapshot.data!.split(',').last),
                        fit: BoxFit.cover,
                      );
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              isLoggedIn ? '$name' : 'Hi, Guest!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              isLoggedIn ? '$email' : 'guest@gmail.com',
              style: TextStyle(
                fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
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
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<Map<String, dynamic>?>(
            future: _prefsService.getRoles(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                bool isReader = snapshot.data!['roles'][0]['name'] == 'Reader';
                if (isReader) return Container();
              }
              return Column(
                children: [
                  SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0.25,
                    child: _buildOptionButton(
                      icon: Icons.settings,
                      label: 'Pengaturan Saldo',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsSaldo()),
                      ).then((_) => _refreshProfile()),
                      showBorder: false,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0.25,
            child: _buildOptionButton(
              icon: Icons.logout,
              label: 'Logout',
              onTap: () => logout(context),
              color: Colors.red,
              showBorder: false,
              borderRadius: BorderRadius.circular(10),
            ),
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
            borderRadius ?? (showBorder ? BorderRadius.circular(10) : null),
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
          radius: 14,
          child: Icon(icon, color: color, size: 14),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: color, size: 14),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        dense: true,
      ),
    );
  }
}

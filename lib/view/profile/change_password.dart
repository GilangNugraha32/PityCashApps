import 'package:flutter/material.dart';
import 'package:pity_cash/service/share_preference.dart';

class ChangePasswordProfile extends StatefulWidget {
  @override
  _ChangePasswordProfileState createState() => _ChangePasswordProfileState();
}

class _ChangePasswordProfileState extends State<ChangePasswordProfile> {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
    setState(() {
      _usernameController.text = username ?? 'Guest';
      _emailController.text = email ?? 'example@example.com';
    });
  }

  void _updatePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isNotEmpty &&
        newPassword.isNotEmpty &&
        confirmPassword.isNotEmpty) {
      if (newPassword == confirmPassword) {
        // Update logic can go here, including saving the new password back to SharedPreferences
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('New password and confirm password do not match')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  Widget _buildPasswordField(String label, TextEditingController controller,
      bool isVisible, Function() toggleVisibility) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: Icon(
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.black),
              onPressed: toggleVisibility,
            ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Change Password',
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
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/piticash_log.png'),
                    backgroundColor: Colors.transparent,
                  ),
                  SizedBox(height: 8),
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
                      _buildPasswordField(
                          'Current Password',
                          _currentPasswordController,
                          _isCurrentPasswordVisible, () {
                        setState(() {
                          _isCurrentPasswordVisible =
                              !_isCurrentPasswordVisible;
                        });
                      }),
                      _buildPasswordField('New Password',
                          _newPasswordController, _isNewPasswordVisible, () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      }),
                      _buildPasswordField(
                          'Confirm Password',
                          _confirmPasswordController,
                          _isConfirmPasswordVisible, () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      }),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _updatePassword,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: Color(0xFFEB8153),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text('Update Password',
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

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:pity_cash/view/auth/login.dart';

class SplashScreenPage extends StatelessWidget {
  const SplashScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Image.asset(
        "assets/bg_logo_piticash.png", // Replace with your actual asset path
        fit: BoxFit.cover, // Ensure the image covers the entire screen
      ),
      nextScreen: LoginScreen(),
      splashIconSize: double.infinity, // Make sure the image scales correctly
      backgroundColor: Colors.transparent, // Use a transparent background
      duration: 2500, // Duration of the splash screen
      splashTransition: SplashTransition.fadeTransition, // Transition effect
    );
  }
}

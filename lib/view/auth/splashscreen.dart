import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:pity_cash/view/auth/login.dart';
import 'package:page_transition/page_transition.dart';

class SplashScreenPage extends StatelessWidget {
  const SplashScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Image.asset(
        "assets/bg_logo_piticash.png",
        fit: BoxFit.cover,
      ),
      nextScreen: LoginScreen(),
      splashIconSize: double.infinity,
      backgroundColor: Colors.transparent,
      duration: 2500,
      splashTransition: SplashTransition.fadeTransition,
      pageTransitionType: PageTransitionType.rightToLeft,
    );
  }
}

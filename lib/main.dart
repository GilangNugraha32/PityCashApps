import 'package:flutter/material.dart';
import 'package:pity_cash/view/auth/login.dart';
import 'package:pity_cash/view/auth/splashscreen.dart';
import 'package:pity_cash/view/home/home.dart';
import 'package:pity_cash/view/home/home_section.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => SplashScreenPage(),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(), // Directly navigate to HomeScreen
            );

          case '/login':
            return MaterialPageRoute(
              builder: (context) => LoginScreen(),
            );

          default:
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: Text('Not Found')),
                body: Center(child: Text('Page not found')),
              ),
            );
        }
      },
      initialRoute: '/', // Start with the login screen
    );
  }
}

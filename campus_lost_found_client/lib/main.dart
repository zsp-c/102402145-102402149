import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';

void main() {
  ApiConfig.token = '';
  runApp(const CampusLostFoundApp());
}

class CampusLostFoundApp extends StatelessWidget {
  const CampusLostFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '校园失物招领',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFF7A2E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7A2E),
          primary: const Color(0xFFFF7A2E),
          secondary: const Color(0xFF2DB8A3),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF7A2E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        useMaterial3: true,
      ),
      home: ApiConfig.isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_page.dart';

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
      // 入口固定为登录页：main() 里已经把 token 清空，启动时必然是未登录状态。
      //
      // 这里不能写成 `ApiConfig.isLoggedIn ? HomePage() : LoginPage()`：
      // ApiConfig.isLoggedIn 是可变的静态变量，登录后它会变成 true，
      // 此时根 widget 只要再 build 一次（热重载等），home 就会从 LoginPage
      // 翻成 HomePage；而路由栈里已经有一条 HomePage 了（登录时 push 进去的），
      // 同一个 Navigator 里出现两条 HomePage 路由，导致 Overlay 中出现重复的
      // _OverlayEntryWidgetState GlobalKey —— 即 "Duplicate GlobalKeys" 报错。
      //
      // 结论：命令式导航（pushAndRemoveUntil）与声明式根切换不能混用，
      //       登录/退出的页面切换统一交给 Navigator 负责。
      home: const LoginPage(),
    );
  }
}
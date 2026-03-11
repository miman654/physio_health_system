import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '健康管理系统',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: "/login",
      getPages: [
        GetPage(name: "/login", page: () => LoginPage()),
        // GetPage(name: "/home", page: () => HomePage()),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}

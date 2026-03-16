import 'package:flutter/material.dart';
import 'package:get/get.dart';
// 导入页面文件
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/sport_page.dart';
import 'pages/sleep_page.dart';
import 'pages/ai_page.dart';
// 导入控制器（如果需要提前初始化）
import 'controller/auth_controller.dart';
import 'controller/data_controller.dart';

void main() {
  // 先启动app，确保GetMaterialApp已初始化后再注册控制器，以避免contextless导航报错
  runApp(const MyApp());
  Get.put(AuthController());
  Get.put(DataController());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '健康管理系统',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xfff5f5f5),
      ),
      initialRoute: "/login",
      getPages: [
        GetPage(name: "/login", page: () => LoginPage()),
        GetPage(name: "/home", page: () => HomePage()),
        GetPage(name: "/sport", page: () => const SportPage()),
        GetPage(name: "/sleep", page: () => const SleepPage()),
        GetPage(name: "/ai", page: () => const AIPage()),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}

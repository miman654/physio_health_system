import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_strategy/url_strategy.dart';
// 导入页面文件
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/sport_page.dart';
import 'pages/sport_calendar_page.dart';
import 'pages/sleep_page.dart';
import 'pages/ai_page.dart';
import 'pages/device_monitor_page.dart';
// 导入控制器（如果需要提前初始化）
import 'controller/auth_controller.dart';
import 'controller/data_controller.dart';
import 'controller/sleep_controller.dart';
import 'utils/color.dart';

void main() {
  // 设置URL策略，去除#号
  setPathUrlStrategy();

  // 先注册控制器，再运行app
  Get.put(AuthController(), permanent: true); // permanent: true 表示永久保存
  Get.put(DataController(), permanent: true);
  Get.put(SleepController(), permanent: true); // 永久保存睡眠状态
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '健康管理系统',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.primaryDark,
          surface: AppColors.card,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textTitle,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.primaryLight),
          ),
        ),
        dividerColor: AppColors.primaryLight,
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: AppColors.textTitle),
          titleMedium: TextStyle(color: AppColors.textTitle),
          bodyLarge: TextStyle(color: AppColors.textBody),
          bodyMedium: TextStyle(color: AppColors.textBody),
          bodySmall: TextStyle(color: AppColors.textTip),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            side: const BorderSide(color: AppColors.primaryLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      initialRoute: "/login",
      getPages: [
        GetPage(name: "/login", page: () => LoginPage()),
        GetPage(name: "/register", page: () => const RegisterPage()),
        GetPage(name: "/home", page: () => HomePage()),
        GetPage(name: "/sport", page: () => const SportPage()),
        GetPage(name: "/sport-calendar", page: () => const SportCalendarPage()),
        GetPage(name: "/sleep", page: () => const SleepPage()),
        GetPage(name: "/ai", page: () => const AIPage()),
        GetPage(name: "/device-monitor", page: () => const DeviceMonitorPage()),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}

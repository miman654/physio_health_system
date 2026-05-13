import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_strategy/url_strategy.dart';
// 导入页面文件
import 'pages/user/login_page.dart';
import 'pages/user/register_page.dart';
import 'pages/user/profile_wizard_page.dart';
import 'pages/home/home_page.dart';
import 'pages/sport/sport_page.dart';
import 'pages/sport/sport_calendar_page.dart';
import 'pages/sleep/sleep_page.dart';
import 'pages/user/ai_page.dart';
import 'pages/home/device_monitor_page.dart';
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
        GetPage(
          name: "/register/age",
          page: () => const ProfileWizardPage(
            stepIndex: 0,
            title: '你的年龄是多少?',
            unit: '岁',
            minValue: 10,
            maxValue: 100,
            initialValue: 25,
            stepColor: Color(0xFFF7F5B5),
            nextRoute: '/register/height',
          ),
        ),
        GetPage(
          name: "/register/height",
          page: () => const ProfileWizardPage(
            stepIndex: 1,
            title: '你身高多少?',
            unit: '厘米',
            minValue: 100,
            maxValue: 220,
            initialValue: 170,
            stepColor: Color(0xFFD8EEF2),
            nextRoute: '/register/weight',
          ),
        ),
        GetPage(
          name: "/register/weight",
          page: () => const ProfileWizardPage(
            stepIndex: 2,
            title: '你的体重是多少?',
            unit: '公斤',
            minValue: 30,
            maxValue: 200,
            initialValue: 60,
            stepColor: Color(0xFFF7F5B5),
            nextRoute: '/home',
            isFinalStep: true,
          ),
        ),
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

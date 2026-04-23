import 'package:get/get.dart';
import 'package:flutter/material.dart';

class BleUtil {
  static Future<void> initBle() async {
    // 检查是否是Web平台
    if (Get.context != null && GetPlatform.isWeb) {
      debugPrint("Web平台：蓝牙功能不可用");
      return;
    }

    // 如果是移动平台，执行蓝牙初始化
    try {
      debugPrint("初始化蓝牙...");
      // 这里添加你的蓝牙初始化代码
      // 例如：await flutterBlueInstance.scan();
    } catch (e) {
      debugPrint("蓝牙初始化失败: $e");
    }
  }

  static Future<void> scanBleDevices() async {
    // 检查是否是Web平台
    if (Get.context != null && GetPlatform.isWeb) {
      Get.snackbar(
        "提示",
        "Web平台不支持蓝牙扫描",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // 如果是移动平台，执行蓝牙扫描
    try {
      debugPrint("开始扫描蓝牙设备...");
      Get.snackbar(
        "提示",
        "开始扫描蓝牙设备",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      // 这里添加你的蓝牙扫描代码
    } catch (e) {
      debugPrint("蓝牙扫描失败: $e");
      Get.snackbar(
        "错误",
        "蓝牙扫描失败: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

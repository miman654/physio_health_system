// Permission utility placeholder
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class PermissionUtil {
  // 申请健康管理所需基础权限（蓝牙+位置+存储）
  static Future<bool> requestBasePermissions() async {
    // 在Web平台上，权限处理不同
    if (GetPlatform.isWeb) {
      debugPrint("Web平台：权限请求已跳过");
      return true;
    }

    Get.snackbar("提示", "正在申请必要权限...", colorText: Colors.white);
    // 申请权限组
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth, // 基础蓝牙
      Permission.bluetoothScan, // 蓝牙扫描
      Permission.bluetoothConnect, // 蓝牙连接
      Permission.location, // 蓝牙扫描需要位置权限（安卓）
      Permission.storage, // 本地数据存储
    ].request();

    // 检查权限是否全部授予
    bool isAllGranted = true;
    statuses.forEach((Permission perm, PermissionStatus status) {
      if (status != PermissionStatus.granted) {
        Get.snackbar("权限不足", "${_getPermName(perm)}权限未授予，部分功能无法使用",
            colorText: Colors.white);
        isAllGranted = false;
      }
    });

    if (isAllGranted) {
      Get.snackbar("成功", "所有必要权限已授予",
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white);
    }
    return isAllGranted;
  }

  // 检查单个权限（按需申请）
  static Future<bool> checkSinglePermission(Permission permission) async {
    if (GetPlatform.isWeb) {
      return true;
    }

    PermissionStatus status = await permission.status;
    if (status == PermissionStatus.denied ||
        status == PermissionStatus.permanentlyDenied) {
      status = await permission.request();
    }
    return status == PermissionStatus.granted;
  }

  // 权限枚举转中文名称，方便提示
  static String _getPermName(Permission perm) {
    switch (perm) {
      case Permission.bluetooth:
        return "蓝牙";
      case Permission.bluetoothScan:
        return "蓝牙扫描";
      case Permission.bluetoothConnect:
        return "蓝牙连接";
      case Permission.location:
        return "位置";
      case Permission.storage:
        return "存储";
      default:
        return "未知";
    }
  }
}

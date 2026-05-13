import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserNotice {
  static DateTime? _lastBackendNoticeAt;
  static DateTime? _lastNetworkNoticeAt;
  static DateTime? _lastInfoNoticeAt;

  static void showBackendUnavailable({
    String title = '后台异常',
    String message = '服务暂时不可用，请稍后再试',
    Duration cooldown = const Duration(seconds: 8),
  }) {
    if (_shouldSkip(_lastBackendNoticeAt, cooldown)) return;
    _lastBackendNoticeAt = DateTime.now();
    _show(title, message, Colors.red.withValues(alpha: 0.82));
  }

  static void showNetworkIssue({
    String title = '网络异常',
    String message = '当前无法连接服务，请检查网络或后端是否已启动',
    Duration cooldown = const Duration(seconds: 8),
  }) {
    if (_shouldSkip(_lastNetworkNoticeAt, cooldown)) return;
    _lastNetworkNoticeAt = DateTime.now();
    _show(title, message, Colors.orange.withValues(alpha: 0.82));
  }

  static void showInfoOnce({
    required String title,
    required String message,
    Duration cooldown = const Duration(seconds: 4),
  }) {
    if (_shouldSkip(_lastInfoNoticeAt, cooldown)) return;
    _lastInfoNoticeAt = DateTime.now();
    _show(title, message, Colors.black.withValues(alpha: 0.72));
  }

  static bool _shouldSkip(DateTime? lastShownAt, Duration cooldown) {
    if (lastShownAt == null) return false;
    return DateTime.now().difference(lastShownAt) < cooldown;
  }

  static void _show(String title, String message, Color backgroundColor) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }
}

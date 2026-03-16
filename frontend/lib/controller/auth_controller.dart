import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import 'package:flutter/material.dart';

// 使用 GetX 状态管理框架，负责用户登录状态和业务逻辑。
// 定义响应式状态
class AuthController extends GetxController {
  final ApiService _apiService = ApiService();
  RxBool isLoading = false.obs; // 加载状态可观察）
  RxString token = "".obs; // 登录令牌可观察）
  RxInt userId = 0.obs; // 用户ID可观察）
  RxString username = "".obs; // 用户名可观察）

  @override
  void onInit() {
    super.onInit();
    _loadLocalUserInfo(); // 初始化：读取本地缓存的用户信息
  }

  // 从本地SP加载用户信息
  Future<void> _loadLocalUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // 如果有token，直接跳转到首页
    token.value = prefs.getString("token") ?? "";
    userId.value = prefs.getInt("user_id") ?? 0;
    username.value = prefs.getString("username") ?? "";
    // 已登录则直接跳首页
    if (token.value.isNotEmpty && userId.value > 0) {
      Get.offAllNamed("/home");
    }
  }

  // 登录功能（适配接口返回：data内包含user_id/token/username）
  Future<void> login(String username, String password) async {
    // 表单校验
    if (username.trim().isEmpty || password.trim().isEmpty) {
      Get.snackbar("提示", "用户名和密码不能为空", colorText: Colors.white);
      return;
    }
    // 显示加载中
    isLoading.value = true;
    var result = await _apiService.login(username.trim(), password.trim());
    // 隐藏加载中
    isLoading.value = false;

    if (result["code"] == 200) {
      // 解析接口返回的data字段  1. 保存token和用户信息
      Map<String, dynamic> data = result["data"];
      token.value = data["token"] ?? "";
      userId.value = data["user_id"] ?? 0;
      this.username.value = data["username"] ?? "";

      // 本地持久化存储
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token.value);
      await prefs.setInt("user_id", userId.value);
      await prefs.setString("username", this.username.value);

      // 跳转到首页
      Get.offAllNamed("/home");
      Get.snackbar("成功", "登录成功，欢迎回来！",
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white);
    } else {
      Get.snackbar("登录失败", result["msg"] ?? "用户名或密码错误",
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  // 注册功能（适配接口的400：用户名已存在）
  Future<void> register(Map<String, dynamic> params) async {
    // 表单校验
    if (params["username"].trim().isEmpty ||
        params["password"].trim().isEmpty) {
      Get.snackbar("提示", "用户名和密码不能为空", colorText: Colors.white);
      return;
    }
    isLoading.value = true;
    var result = await _apiService.register(params);
    isLoading.value = false;

    if (result["code"] == 200) {
      Get.snackbar("成功", result["msg"] ?? "用户注册成功",
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white);
      Get.back(); // 返回登录页
    }
  }

  // 退出登录（清空缓存+跳登录页）
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("user_id");
    await prefs.remove("username");
    // 重置状态
    token.value = "";
    userId.value = 0;
    username.value = "";
    // 跳转登录页
    Get.offAllNamed("/login");
    Get.snackbar("提示", "已安全退出登录", colorText: Colors.white);
  }
}

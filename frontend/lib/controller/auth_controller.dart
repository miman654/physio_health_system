import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../api/ws_service.dart';
import 'package:flutter/material.dart';
import '../pages/user/login_page.dart';
import '../pages/home/home_page.dart';
import 'data_controller.dart';

// 使用 GetX 状态管理框架，负责用户登录状态和业务逻辑。
// 定义响应式状态
class AuthController extends GetxController {
  final ApiService _apiService = ApiService();
  RxBool isLoading = false.obs; // 加载状态可观察
  bool _isRegistering = false;
  RxString token = "".obs; // 登录令牌可观察
  RxInt userId = 0.obs; // 用户ID可观察
  RxString username = "".obs; // 用户名可观察
  RxString userGender = "".obs; // 用户性别可观察
  RxInt userAge = 0.obs; // 用户年龄可观察
  RxDouble userWeight = 0.0.obs; // 用户体重可观察
  RxDouble userHeight = 0.0.obs; // 用户身高可观察

  @override
  void onInit() {
    super.onInit();
    _loadLocalUserInfo(); // 初始化：读取本地缓存的用户信息
    loadUserInfo(); // 加载用户详细信息
  }

  // 加载用户详细信息（公开方法）
  Future<void> loadUserInfo() async {
    if (userId.value == 0) return;

    var result = await _apiService.getUserInfo();
    if (result["code"] == 200) {
      final data = result["data"] ?? {};
      userGender.value = data["gender"] ?? "";
      userAge.value = data["age"] ?? 0;
      userWeight.value = (data["weight"] ?? 0.0).toDouble();
      userHeight.value = (data["height"] ?? 0.0).toDouble();
      debugPrint("加载用户信息成功: 性别=${userGender.value}, 年龄=${userAge.value}");
    } else {
      debugPrint("加载用户信息失败: ${result["msg"]}");
    }
  }

  // 从本地SP加载用户信息
  Future<void> _loadLocalUserInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // 如果有token，直接跳转到首页
      token.value = prefs.getString("token") ?? "";
      userId.value = prefs.getInt("user_id") ?? 0;
      username.value = prefs.getString("username") ?? "";

      // 已登录则直接跳首页
      if (token.value.isNotEmpty && userId.value > 0) {
        // 先加载用户信息
        await loadUserInfo();

        // 延迟一点执行导航，确保widget树已构建
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            Get.offAllNamed("/home");
          } catch (e) {
            debugPrint("命名路由导航错误: $e");
            // 如果命名路由失败，使用组件导航
            Get.offAll(() => HomePage());
          }
        });
      }
    } catch (e) {
      debugPrint("加载本地用户信息失败: $e");
    }
  }

  // 登录功能（适配接口返回：data内包含user_id/token/username）
  Future<bool> login(
    String username,
    String password, {
    bool navigateToHome = true,
    bool showSuccessMessage = true,
  }) async {
    // 表单校验
    if (username.trim().isEmpty || password.trim().isEmpty) {
      Get.snackbar("提示", "用户名和密码不能为空",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(milliseconds: 1500));
      return false;
    }

    // 显示加载中
    isLoading.value = true;
    var result = await _apiService.login(username.trim(), password.trim());
    debugPrint('login() response: $result');
    // 隐藏加载中
    isLoading.value = false;

    if (result["code"] == 200) {
      // 解析接口返回的data字段
      Map<String, dynamic> data = result["data"];
      token.value = data["token"] ?? "";
      userId.value = data["user_id"] ?? 0;
      this.username.value = data["username"] ?? "";

      // 本地持久化存储
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token.value);
      await prefs.setInt("user_id", userId.value);
      await prefs.setString("username", this.username.value);

      // 登录成功后加载用户详细信息
      await loadUserInfo();

      // 关键改动：在跳转前，先完成首次数据同步
      final dataCtrl = Get.find<DataController>();
      await dataCtrl.refreshAllData();

      // 跳转到首页 - 添加错误处理
      if (navigateToHome) {
        try {
          Get.offAllNamed("/home");
        } catch (e) {
          debugPrint("导航错误: $e");
          Get.offAll(() => HomePage());
        }
        // 再次确保首页数据已经刷新（有时导航后首次连接可能丢失）
        try {
          final dataCtrl = Get.find<DataController>();
          await dataCtrl.refreshAllData();
        } catch (e) {
          debugPrint('登录后刷新数据失败: $e');
        }
      }

      return true;
    } else {
      String errorMsg = result["msg"] ?? "登录失败";
      if (result["code"] == 401) {
        errorMsg = "用户名或密码错误";
      }
      Get.snackbar("登录失败", errorMsg,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(milliseconds: 1500));
      return false;
    }
  }

  // 注册功能（适配接口的400：用户名已存在）
  Future<bool> register(Map<String, dynamic> params) async {
    if (_isRegistering) {
      debugPrint('register() ignored because a request is already in progress');
      return true;
    }

    // 表单校验
    if (params["username"].trim().isEmpty ||
        params["password"].trim().isEmpty) {
      Get.snackbar("提示", "用户名和密码不能为空",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(milliseconds: 1500));
      return false;
    }

    _isRegistering = true;
    isLoading.value = true;

    try {
      final result = await _apiService.register(params);
      debugPrint('register() response: $result');

      if (result["code"] == 200) {
        // 注册成功后自动登录并进入主页
        final loginOk = await login(
          params["username"].toString(),
          params["password"].toString(),
        );
        return loginOk;
      } else if (result["code"] == 400) {
        Get.snackbar("注册失败", result["msg"] ?? "用户名已存在",
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(milliseconds: 1500));
        return false;
      }

      return false;
    } finally {
      isLoading.value = false;
      _isRegistering = false;
    }
  }

  Future<bool> updateProfile({int? age, double? weight, double? height}) async {
    final params = <String, dynamic>{
      if (age != null) 'age': age,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
    };

    if (params.isEmpty) {
      return true;
    }

    isLoading.value = true;
    var result = await _apiService.updateProfile(params);
    isLoading.value = false;

    if (result["code"] == 200) {
      final data = result["data"] ?? {};
      userAge.value = data["age"] ?? userAge.value;
      userWeight.value = (data["weight"] ?? userWeight.value).toDouble();
      userHeight.value = (data["height"] ?? userHeight.value).toDouble();
      return true;
    }

    Get.snackbar("资料更新失败", result["msg"] ?? "操作失败，请稍后重试",
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(milliseconds: 1500));
    return false;
  }

// 退出登录
  Future<void> logout() async {
    // 立即跳转到登录页
    try {
      Get.offAllNamed("/login");
    } catch (e) {
      debugPrint("导航错误: $e");
      Get.offAll(() => LoginPage());
    }

    // 后台执行退出登录操作
    _apiService.logout().then((result) {
      WsService.close(showDisconnectNotice: false);
      // 清除本地缓存
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove("token");
        prefs.remove("user_id");
        prefs.remove("username");
      });

      // 重置状态
      token.value = "";
      userId.value = 0;
      username.value = "";
      userGender.value = "";
      userAge.value = 0;
      userWeight.value = 0.0;
      userHeight.value = 0.0;

      // 显示提示
    }).catchError((error) {
      debugPrint("退出登录接口调用失败: $error");
    });
  }

// 注销账号
  Future<void> deleteAccount() async {
    // 立即跳转到登录页
    try {
      Get.offAllNamed("/login");
    } catch (e) {
      debugPrint("导航错误: $e");
      Get.offAll(() => LoginPage());
    }

    // 后台执行注销操作
    _apiService.deleteAccount().then((result) {
      WsService.close(showDisconnectNotice: false);
      // 清除本地缓存
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove("token");
        prefs.remove("user_id");
        prefs.remove("username");
      });

      // 重置状态
      token.value = "";
      userId.value = 0;
      username.value = "";
      userGender.value = "";
      userAge.value = 0;
      userWeight.value = 0.0;
      userHeight.value = 0.0;

      // 显示提示
      if (result["code"] == 200) {
        Get.snackbar("成功", result["msg"] ?? "账号已注销",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(milliseconds: 1500));
      } else {
        Get.snackbar("注销失败", result["msg"] ?? "操作失败，请稍后重试",
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(milliseconds: 1500));
      }
    }).catchError((error) {
      debugPrint("注销账号接口调用失败: $error");
      Get.snackbar("注销失败", "网络错误",
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(milliseconds: 1500));
    });
  }
}

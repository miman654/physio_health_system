// Auth controller placeholder GetX状态管理
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class AuthController extends GetxController {
  final ApiService _apiService = ApiService();
  RxBool isLoading = false.obs;
  RxString token = "".obs;
  RxInt userId = 0.obs;

  // 登录
  Future<void> login(String username, String password) async {
    isLoading.value = true;
    var result = await _apiService.login(username, password);
    isLoading.value = false;
    if (result["code"] == 200) {
      // 保存token和用户ID
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", result["data"]["token"]);
      await prefs.setInt("user_id", result["data"]["user_id"]);
      token.value = result["data"]["token"];
      userId.value = result["data"]["user_id"];
      // 跳转到首页
      Get.offAllNamed("/home");
    } else {
      Get.snackbar("错误", result["msg"]);
    }
  }
}

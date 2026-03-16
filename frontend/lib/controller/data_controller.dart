// Data controller placeholder
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import 'package:flutter/material.dart';

class DataController extends GetxController {
  final ApiService _apiService = ApiService();
  RxBool isLoading = false.obs; // 全局数据加载状态

  // 生理数据（适配接口的timestamp字段）
  RxList physioDataList = [].obs;
  // 睡眠记录
  RxList sleepDataList = [].obs;
  // 运动记录
  RxList sportDataList = [].obs;
  // AI分析结果（适配接口的数组/对象返回）
  RxList aiPhysioSuggestions = [].obs; // AI生理分析建议数组
  RxList aiSportNutrition = [].obs; // AI运动营养建议数组

  // 获取当前登录用户ID（从SP读取，避免全局传参）
  Future<int> _getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt("user_id") ?? 1; // 默认为1，与测试接口一致
  }

  // ********************* 生理数据操作 *********************
  // 上传生理数据
  Future<void> uploadPhysioData(Map<String, dynamic> data) async {
    isLoading.value = true;
    var result = await _apiService.uploadPhysioData(data);
    isLoading.value = false;
    if (result["code"] == 200) {
      Get.snackbar("成功", result["msg"] ?? "生理数据上传成功",
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white);
      await queryPhysioData(); // 上传成功后刷新列表
    }
  }

  // 查询生理数据（按时间倒序，适配timestamp字段）
  Future<void> queryPhysioData({int limit = 10}) async {
    int userId = await _getCurrentUserId();
    isLoading.value = true;
    var result = await _apiService.queryPhysioData(userId, limit: limit);
    isLoading.value = false;
    if (result["code"] == 200) {
      physioDataList.value = result["data"] ?? [];
    }
  }

  // 生成模拟睡眠生理数据
  Future<void> mockSleepPhysioData() async {
    int userId = await _getCurrentUserId();
    isLoading.value = true;
    var result = await _apiService.mockSleepPhysioData(userId);
    isLoading.value = false;
    if (result["code"] == 200) {
      Get.snackbar("成功", result["msg"] ?? "模拟睡眠数据生成成功",
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white);
      await queryPhysioData(); // 生成后刷新列表
    }
  }

  // ********************* 睡眠记录操作 *********************
  // 上传睡眠记录
  Future<void> uploadSleepRecord(Map<String, dynamic> data) async {
    isLoading.value = true;
    var result = await _apiService.uploadSleepRecord(data);
    isLoading.value = false;
    if (result["code"] == 200) {
      Get.snackbar("成功", result["msg"] ?? "睡眠记录上传成功",
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white);
      await querySleepRecord(); // 上传成功后刷新列表
    }
  }

  // 查询睡眠记录
  Future<void> querySleepRecord({int limit = 7}) async {
    int userId = await _getCurrentUserId();
    isLoading.value = true;
    var result = await _apiService.querySleepRecord(userId, limit: limit);
    isLoading.value = false;
    if (result["code"] == 200) {
      sleepDataList.value = result["data"] ?? [];
    }
  }

  // ********************* 运动记录操作 *********************
  // 上传运动记录
  Future<void> uploadSportRecord(Map<String, dynamic> data) async {
    isLoading.value = true;
    var result = await _apiService.uploadSportRecord(data);
    isLoading.value = false;
    if (result["code"] == 200) {
      Get.snackbar("成功", result["msg"] ?? "运动记录上传成功",
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white);
      await querySportRecord(); // 上传成功后刷新列表
    }
  }

  // 查询运动记录
  Future<void> querySportRecord({int limit = 7}) async {
    int userId = await _getCurrentUserId();
    isLoading.value = true;
    var result = await _apiService.querySportRecord(userId, limit: limit);
    isLoading.value = false;
    if (result["code"] == 200) {
      sportDataList.value = result["data"] ?? [];
    }
  }

  // ********************* AI分析操作 *********************
  // AI生理数据分析（适配接口：data.suggestions数组）
  Future<void> getAiPhysioAnalysis() async {
    int userId = await _getCurrentUserId();
    isLoading.value = true;
    var result = await _apiService.aiPhysioAnalysis(userId);
    isLoading.value = false;
    if (result["code"] == 200) {
      Map<String, dynamic> data = result["data"] ?? {};
      aiPhysioSuggestions.value = data["suggestions"] ?? [];
    }
  }

  // AI运动营养建议（适配接口：data.nutrition_suggestions数组）
  Future<void> getAiSportNutrition(String sportType, int duration) async {
    isLoading.value = true;
    var result = await _apiService.aiSportNutrition({
      "sport_type": sportType,
      "sport_duration": duration,
    });
    isLoading.value = false;
    if (result["code"] == 200) {
      Map<String, dynamic> data = result["data"] ?? {};
      aiSportNutrition.value = data["nutrition_suggestions"] ?? [];
    }
  }

  // 刷新所有数据（首页初始化调用）
  Future<void> refreshAllData() async {
    isLoading.value = true;
    await Future.wait([
      queryPhysioData(),
      querySleepRecord(),
      querySportRecord(),
      getAiPhysioAnalysis(),
    ]);
    isLoading.value = false;
  }
}

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../api/ws_service.dart';
import 'package:flutter/material.dart';

class DataController extends GetxController {
  final ApiService _apiService = ApiService();
  RxBool isLoading = false.obs; // 全局数据加载状态
  RxBool isRealtimeConnected = false.obs;

  // 生理数据（适配接口的timestamp字段）
  RxList physioDataList = [].obs;
  RxMap realtimePhysioSnapshot = <String, dynamic>{}.obs;
  // 睡眠记录
  RxList sleepDataList = [].obs;
  // 运动记录
  RxList sportDataList = [].obs;
  RxMap sportCalendarData = {}.obs;
  // AI分析结果（适配接口的数组/对象返回）
  RxMap aiPhysioAnalysis = {}.obs; // AI生理分析完整数据
  RxList aiPhysioSuggestions = [].obs; // AI生理分析建议数组
  RxList aiSportNutrition = [].obs; // AI运动营养建议数组
  String? _realtimeDeviceId;

  // 获取当前登录用户ID（从SP读取，避免全局传参）
  Future<int> _getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt("user_id") ?? 0; // 默认为0，如果没有则返回0
  }

  Future<void> syncRealtimePhysioSnapshot(
      {String deviceId = "hi3861-01"}) async {
    final result = await _apiService.getDeviceLatest(deviceId);
    if (result["code"] == 200 && result["data"] is Map) {
      final normalized = _normalizeRealtimePhysio(
        Map<String, dynamic>.from(result["data"] as Map),
      );
      if (_shouldApplyRealtimeSnapshot(normalized)) {
        realtimePhysioSnapshot.value = normalized;
      }
    }
  }

  String _formatTimestampMs(int? timestampMs) {
    if (timestampMs == null || timestampMs <= 0) return "";
    final normalizedMs =
        timestampMs < 1000000000000 ? timestampMs * 1000 : timestampMs;
    final date = DateTime.fromMillisecondsSinceEpoch(normalizedMs);
    String pad(int value) => value.toString().padLeft(2, '0');
    return "${date.year}-${pad(date.month)}-${pad(date.day)} ${pad(date.hour)}:${pad(date.minute)}:${pad(date.second)}";
  }

  int? _extractTimestampMs(Map<String, dynamic> data) {
    final candidates = [
      data['timestamp_ms'],
      data['timestamp'],
      data['server_received_at'],
      data['last_ts_device_ms'],
      data['updated_at'],
    ];

    for (final candidate in candidates) {
      int? value;
      if (candidate is int) {
        value = candidate;
      } else if (candidate is String) {
        value = int.tryParse(candidate);
      }

      if (value != null && value > 0) {
        return value < 1000000000000 ? value * 1000 : value;
      }
    }

    return null;
  }

  Map<String, dynamic> _normalizeRealtimePhysio(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    final timestampMs = _extractTimestampMs(normalized);
    normalized["timestamp_ms"] = timestampMs;
    final formattedTimestamp = _formatTimestampMs(timestampMs);
    final rawTimestamp = normalized["timestamp"]?.toString();
    normalized["timestamp"] = formattedTimestamp.isNotEmpty
        ? formattedTimestamp
        : (rawTimestamp?.isNotEmpty == true ? rawTimestamp : "");
    normalized["scene"] = normalized["scene"] ?? 0;
    return normalized;
  }

  void applyRealtimePhysioSnapshot(Map<String, dynamic> data) {
    final normalized = _normalizeRealtimePhysio(data);
    if (_shouldApplyRealtimeSnapshot(normalized)) {
      realtimePhysioSnapshot.value = normalized;
    }

    if (physioDataList.isNotEmpty) {
      final latest = physioDataList.first;
      final sameSeq = latest is Map && latest["seq"] == normalized["seq"];
      if (sameSeq) {
        physioDataList[0] = normalized;
      } else {
        physioDataList.insert(0, normalized);
      }
    } else {
      physioDataList.insert(0, normalized);
    }

    while (physioDataList.length > 20) {
      physioDataList.removeLast();
    }
  }

  bool _shouldApplyRealtimeSnapshot(Map<String, dynamic> incoming) {
    if (realtimePhysioSnapshot.isEmpty) {
      return true;
    }

    final current = Map<String, dynamic>.from(realtimePhysioSnapshot);
    final currentSeq = _extractIntValue(current, ["seq"]);
    final incomingSeq = _extractIntValue(incoming, ["seq"]);
    if (currentSeq != null &&
        incomingSeq != null &&
        incomingSeq != currentSeq) {
      return incomingSeq > currentSeq;
    }

    final currentTimestamp =
        _extractIntValue(current, ["timestamp_ms", "timestamp"]);
    final incomingTimestamp =
        _extractIntValue(incoming, ["timestamp_ms", "timestamp"]);
    if (currentTimestamp != null &&
        incomingTimestamp != null &&
        incomingTimestamp != currentTimestamp) {
      return incomingTimestamp > currentTimestamp;
    }

    return true;
  }

  int? _extractIntValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Future<void> startRealtimePhysioStream(
      {String deviceId = "hi3861-01"}) async {
    if (isRealtimeConnected.value && _realtimeDeviceId == deviceId) {
      return;
    }

    if (isRealtimeConnected.value && _realtimeDeviceId != deviceId) {
      WsService.close();
      isRealtimeConnected.value = false;
    }

    // 尝试连接，最多重试 3 次，间隔 300ms
    const int maxAttempts = 3;
    int attempt = 0;
    while (attempt < maxAttempts) {
      attempt += 1;
      try {
        await WsService.connect(
          deviceId: deviceId,
          onMessage: applyRealtimePhysioSnapshot,
        );
        isRealtimeConnected.value = WsService.isConnected;
        if (isRealtimeConnected.value) {
          _realtimeDeviceId = deviceId;
          break;
        }
      } catch (e) {
        debugPrint('WebSocket 连接尝试 $attempt 失败: $e');
      }

      // 等待一小段时间再重试
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  void stopRealtimePhysioStream() {
    WsService.close(showDisconnectNotice: false);
    isRealtimeConnected.value = false;
    _realtimeDeviceId = null;
    realtimePhysioSnapshot.clear();
  }

  // ********************* 生理数据操作 *********************
// 上传生理数据
  Future<void> uploadPhysioData(Map<String, dynamic> data) async {
    isLoading.value = true;

    // 确保只传递必要的字段
    Map<String, dynamic> uploadData = {
      "user_id": data["user_id"],
      "scene": data["scene"],
    };

    // 如果有 timestamp 才添加
    if (data.containsKey("timestamp") && data["timestamp"] != null) {
      uploadData["timestamp"] = data["timestamp"];
    }

    var result = await _apiService.uploadPhysioData(uploadData);
    isLoading.value = false;

    if (result["code"] == 200) {
      Get.snackbar("成功", result["msg"] ?? "生理数据上传成功",
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white);
      await queryPhysioData(); // 上传成功后刷新列表
      await startRealtimePhysioStream();
    } else {
      Get.snackbar("上传失败", result["msg"] ?? "请稍后重试",
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white);
    }
  }

  // 查询生理数据（按时间倒序，适配timestamp字段）
  Future<void> queryPhysioData({int limit = 10}) async {
    int userId = await _getCurrentUserId();
    if (userId == 0) {
      Get.snackbar("提示", "请先登录",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    var result = await _apiService.queryPhysioData(userId, limit: limit);
    isLoading.value = false;

    if (result["code"] == 200) {
      physioDataList.value = result["data"] ?? [];
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
    } else {
      Get.snackbar("上传失败", result["msg"] ?? "请检查时间格式",
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white);
    }
  }

  // 查询睡眠记录
  Future<void> querySleepRecord({int limit = 7}) async {
    int userId = await _getCurrentUserId();
    if (userId == 0) {
      return;
    }

    isLoading.value = true;
    var result = await _apiService.querySleepRecord(userId, limit: limit);
    isLoading.value = false;

    if (result["code"] == 200) {
      sleepDataList.value = result["data"] ?? [];
    }
  }

// ********************* 运动记录操作 *********************
// 上传运动记录
// 上传运动记录
  Future<Map<String, dynamic>?> uploadSportRecord(
      Map<String, dynamic> data) async {
    isLoading.value = true;

    // 确保只传递必要的字段
    Map<String, dynamic> uploadData = {
      "user_id": data["user_id"],
      "sport_type": data["sport_type"],
      "sport_start": data["sport_start"],
      "sport_end": data["sport_end"],
    };

    var result = await _apiService.uploadSportRecord(uploadData);
    isLoading.value = false;

    if (result["code"] == 200) {
      Get.snackbar("成功", result["msg"] ?? "运动记录上传成功",
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white);
      await querySportRecord(); // 上传成功后刷新列表
      return result; // 返回结果，包含 calorie 数据
    } else {
      Get.snackbar("上传失败", result["msg"] ?? "请检查运动类型或时间格式",
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white);
      return null;
    }
  }

// 查询运动记录
  Future<void> querySportRecord({int limit = 7}) async {
    int userId = await _getCurrentUserId();
    if (userId == 0) {
      Get.snackbar("提示", "请先登录",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    var result = await _apiService.querySportRecord(userId, limit: limit);
    isLoading.value = false;

    if (result["code"] == 200) {
      sportDataList.value = result["data"] ?? [];
      debugPrint("查询到 ${sportDataList.length} 条运动记录");
    } else {
      debugPrint("查询运动记录失败: ${result["msg"]}");
      sportDataList.value = [];
    }
  }

  Future<Map<String, dynamic>?> querySportCalendar({
    required int year,
    required int month,
  }) async {
    int userId = await _getCurrentUserId();
    if (userId == 0) {
      Get.snackbar("提示", "请先登录",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return null;
    }

    isLoading.value = true;
    var result = await _apiService.querySportCalendar(userId, year, month);
    isLoading.value = false;

    if (result["code"] == 200) {
      sportCalendarData.value = result["data"] ?? {};
      return result;
    }

    sportCalendarData.clear();
    return result;
  }

  // ********************* AI分析操作 *********************
  // AI生理数据分析（适配接口：返回完整的data对象，包含suggestions数组）
  // AI生理数据分析（适配接口：返回完整的data对象，包含suggestions数组）
  Future<void> getAiPhysioAnalysis() async {
    int userId = await _getCurrentUserId();
    if (userId == 0) {
      Get.snackbar("提示", "请先登录",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    // 不要在这里设置 isLoading，因为已经在 refreshAllData 中设置了
    var result = await _apiService.aiPhysioAnalysis(userId);

    if (result["code"] == 200) {
      Map<String, dynamic> data = result["data"] ?? {};
      aiPhysioAnalysis.value = data;
      aiPhysioSuggestions.value = data["suggestions"] ?? [];
      debugPrint("AI分析成功，获得 ${aiPhysioSuggestions.length} 条建议");
    } else {
      debugPrint("AI分析失败: ${result["msg"]}");
      // 不显示错误弹窗，避免干扰用户体验
    }
  }

  // AI运动营养建议（适配接口：返回data.nutrition_suggestions数组）
  Future<void> getAiSportNutrition(
      String sportType, int duration, String sportTime) async {
    int userId = await _getCurrentUserId();
    if (userId == 0) {
      Get.snackbar("提示", "请先登录",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    var result = await _apiService.aiSportNutrition({
      "user_id": userId,
      "sport_type": sportType,
      "sport_duration": duration,
      "sport_time": sportTime,
    });
    isLoading.value = false;

    if (result["code"] == 200) {
      Map<String, dynamic> data = result["data"] ?? {};
      aiSportNutrition.value = data["nutrition_suggestions"] ?? [];

      Get.snackbar("营养建议", "获取成功",
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white);
    } else {
      Get.snackbar("获取失败", result["msg"] ?? "请稍后重试",
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white);
    }
  }

  // 刷新所有数据（首页初始化调用）
  Future<void> refreshAllData() async {
    int userId = await _getCurrentUserId();
    if (userId == 0) {
      Get.offAllNamed("/login");
      return;
    }

    isLoading.value = true;
    try {
      await Future.wait([
        queryPhysioData(),
        querySleepRecord(),
        querySportRecord(),
        getAiPhysioAnalysis(), // 这个可能失败，但不影响其他数据
      ]);
      await startRealtimePhysioStream();
    } catch (e) {
      debugPrint("刷新数据失败: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

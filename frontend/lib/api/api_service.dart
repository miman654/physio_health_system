import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart' hide Response;
import 'package:flutter/material.dart';
import '../utils/user_notice.dart';

class ApiService {
  final Dio _dio = Dio();

  String _friendlyRequestMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '服务响应超时，请稍后再试';
      case DioExceptionType.connectionError:
        return '当前无法连接后台，请检查后端是否已启动';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.badCertificate:
        return '连接安全证书异常，请稍后重试';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode == 401) return '登录已过期，请重新登录';
        if (statusCode == 403) return '没有权限执行该操作';
        if (statusCode == 404) return '请求的服务不存在';
        if (statusCode >= 500) return '后台服务暂时异常，请稍后再试';
        return '请求失败，请稍后重试';
      case DioExceptionType.unknown:
        final message = (e.message ?? '').toLowerCase();
        if (message.contains('xmlhttprequest') ||
            message.contains('failed to fetch')) {
          return '后台服务暂时不可用，请稍后再试';
        }
        return '网络异常，请稍后再试';
    }
  }

  String _friendlyResponseMessage(Response<dynamic>? response) {
    final statusCode = response?.statusCode ?? 0;
    if (statusCode == 422) return '输入格式有误，请检查后重试';
    if (statusCode == 401) return '登录已失效，请重新登录';
    if (statusCode == 403) return '当前操作没有权限';
    if (statusCode == 404) return '未找到对应数据';
    if (statusCode >= 500) return '后台服务暂时异常，请稍后再试';
    return '请求失败，请稍后重试';
  }

  // 根据不同平台设置不同的 baseUrl
  static String get baseUrl {
    if (GetPlatform.isAndroid) {
      return "http://10.0.2.2:8008"; // Android模拟器
    } else if (GetPlatform.isIOS) {
      return "http://127.0.0.1:8008"; // iOS模拟器
    } else if (GetPlatform.isWeb) {
      return "http://localhost:8008"; // Web
    } else {
      return "http://10.0.2.2:8008"; // 默认
    }
  }

  ApiService() {
    // 使用动态baseUrl
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10); // 增加到10秒
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers["Content-Type"] = "application/json;charset=utf-8";

    // 拦截器：统一添加Token + 统一错误处理
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 请求前统一添加Token（如果存在）
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? token = prefs.getString("token");
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          handler.next(options);
        },
        // 请求错误统一处理（适配接口的400/500错误格式）
        onError: (DioException e, handler) {
          final statusCode = e.response?.statusCode ?? 0;
          final isBackendDown = e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              statusCode >= 500 ||
              e.type == DioExceptionType.unknown;
          final message = e.response != null
              ? _friendlyResponseMessage(e.response)
              : _friendlyRequestMessage(e);

          if (isBackendDown) {
            UserNotice.showBackendUnavailable(message: message);
          } else {
            UserNotice.showInfoOnce(title: '提示', message: message);
          }
          handler.next(e);
        },
      ),
    );
  }

  // ********************* 一、用户鉴权接口 *********************
  // 登录 /auth/login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        "/auth/login",
        data: {"username": username, "password": password},
      );
      return response.data; // 返回格式: {"code":200, "msg":"登录成功", "data":{...}}
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return {"code": 401, "msg": e.response?.data["detail"] ?? "用户名或密码错误"};
      }
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // 注册 /auth/register
  Future<Map<String, dynamic>> register(Map<String, dynamic> params) async {
    try {
      final response = await _dio.post("/auth/register", data: params);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return {"code": 400, "msg": e.response?.data["detail"] ?? "注册失败"};
      }
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // 用户名查重 /auth/check-username
  Future<Map<String, dynamic>> checkUsername(String username) async {
    try {
      final response = await _dio.post(
        "/auth/check-username",
        data: {"username": username},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return {"code": 400, "msg": e.response?.data["detail"] ?? "用户名校验失败"};
      }
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // 获取用户信息 /auth/userinfo
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final response = await _dio.get("/auth/userinfo");
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return {"code": 401, "msg": "token已失效，请重新登录"};
      }
      if (e.response?.statusCode == 404) {
        return {"code": 404, "msg": e.response?.data["detail"] ?? "用户不存在"};
      }
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // 更新用户基础资料 /auth/profile
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await _dio.patch("/auth/profile", data: params);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return {"code": 400, "msg": e.response?.data["detail"] ?? "资料更新失败"};
      }
      if (e.response?.statusCode == 401) {
        return {"code": 401, "msg": "token已失效，请重新登录"};
      }
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // 退出登录 /auth/logout
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _dio.post("/auth/logout");
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return {"code": 401, "msg": "token已失效"};
      }
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // 注销账号 /auth/account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await _dio.delete("/auth/account");
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        return {"code": 500, "msg": e.response?.data["detail"] ?? "注销失败"};
      }
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // ********************* 二、生理数据接口 *********************
  // 上传生理数据（静息/运动/睡眠通用）/data/upload/physio
  Future<Map<String, dynamic>> uploadPhysioData(
      Map<String, dynamic> data) async {
    try {
      // 确保只传递后端需要的字段
      final response = await _dio.post("/data/upload/physio", data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return {"code": 400, "msg": e.response?.data["detail"] ?? "参数错误"};
      }
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // 查询生理数据 /data/query/physio
  Future<Map<String, dynamic>> queryPhysioData(int userId,
      {int limit = 10}) async {
    try {
      final response = await _dio.get(
        "/data/query/physio",
        queryParameters: {"user_id": userId, "limit": limit},
      );
      return response.data;
    } on DioException catch (e) {
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // ********************* 三、睡眠记录接口 *********************
  // 上传睡眠记录 /data/upload/sleep
  Future<Map<String, dynamic>> uploadSleepRecord(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/data/upload/sleep", data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return {"code": 400, "msg": e.response?.data["detail"] ?? "参数错误"};
      }
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // 查询睡眠记录 /data/query/sleep
  Future<Map<String, dynamic>> querySleepRecord(int userId,
      {int limit = 7}) async {
    try {
      final response = await _dio.get(
        "/data/query/sleep",
        queryParameters: {"user_id": userId, "limit": limit},
      );
      return response.data;
    } on DioException catch (e) {
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

// ********************* 四、运动记录接口 *********************
// 上传运动记录 /data/upload/sport
  Future<Map<String, dynamic>> uploadSportRecord(
      Map<String, dynamic> data) async {
    try {
      debugPrint("调用上传运动接口，参数: $data");
      final response = await _dio.post("/data/upload/sport", data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return {"code": 400, "msg": e.response?.data["detail"] ?? "参数错误"};
      }
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

// 查询运动记录 /data/query/sport
  Future<Map<String, dynamic>> querySportRecord(int userId,
      {int limit = 7}) async {
    try {
      debugPrint("调用查询运动接口，userId: $userId, limit: $limit");
      final response = await _dio.get(
        "/data/query/sport",
        queryParameters: {"user_id": userId, "limit": limit},
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("查询运动记录失败: ${e.message}");
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // 查询运动汇总 /data/query/sport/summary
  Future<Map<String, dynamic>> querySportSummary(
    int userId, {
    String granularity = 'week',
    String? date,
    int? year,
    int? month,
  }) async {
    try {
      debugPrint(
          "调用查询运动汇总接口，userId: $userId, granularity: $granularity, date: $date, year: $year, month: $month");
      final queryParameters = <String, dynamic>{
        "user_id": userId,
        "granularity": granularity,
      };
      if (date != null && date.isNotEmpty) {
        queryParameters["date"] = date;
      }
      if (year != null) {
        queryParameters["year"] = year;
      }
      if (month != null) {
        queryParameters["month"] = month;
      }
      final response = await _dio.get(
        "/data/query/sport/summary",
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("查询运动汇总失败: ${e.message}");
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // ********************* 六、设备监控接口 *********************
  Future<Map<String, dynamic>> getDeviceLatest(String deviceId) async {
    try {
      final response = await _dio.get(
        "/api/device/$deviceId/latest",
      );
      return response.data;
    } on DioException catch (e) {
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  Future<Map<String, dynamic>> getDeviceHistory(
    String deviceId, {
    int seconds = 600,
  }) async {
    try {
      final response = await _dio.get(
        "/api/device/$deviceId/history",
        queryParameters: {"seconds": seconds},
      );
      return response.data;
    } on DioException catch (e) {
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // ********************* 五、AI分析接口 *********************
// AI生理数据分析 /ai/physio/analysis
  Future<Map<String, dynamic>> aiPhysioAnalysis(int userId) async {
    try {
      final response = await _dio.get(
        "/ai/physio/analysis",
        queryParameters: {"user_id": userId},
      );
      return response.data;
    } on DioException catch (e) {
      // 打印详细错误信息以便调试
      debugPrint("AI分析接口错误: ${e.message}");
      if (e.response != null) {
        debugPrint("响应状态码: ${e.response?.statusCode}");
        debugPrint("响应数据: ${e.response?.data}");
        // 如果是500错误，返回友好的错误信息
        if (e.response?.statusCode == 500) {
          return {"code": 500, "msg": "AI服务暂时不可用，请稍后重试"};
        }
      }
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }

  // AI运动营养建议 /ai/sport/nutrition
  Future<Map<String, dynamic>> aiSportNutrition(
      Map<String, dynamic> data) async {
    try {
      debugPrint("调用AI运动营养接口，参数: $data");
      final response = await _dio.post("/ai/sport/nutrition", data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return {"code": 400, "msg": e.response?.data["detail"] ?? "参数错误"};
      }
      return {"code": -1, "msg": _friendlyRequestMessage(e)};
    }
  }
}

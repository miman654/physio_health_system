import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ApiService {
  final Dio _dio = Dio();

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
          // 解析后端错误信息，适配接口的400/500返回格式
          String errorMsg = "网络请求失败";
          if (e.response != null) {
            // 处理 FastAPI 的 422 验证错误
            if (e.response?.statusCode == 422) {
              errorMsg = "参数验证失败，请检查输入格式";
            }
            // 处理自定义错误信息
            else if (e.response?.data["detail"] != null) {
              errorMsg = e.response?.data["detail"]; // 用户名已存在等校验错误
            } else if (e.response?.data["msg"] != null) {
              errorMsg = e.response?.data["msg"]; // 接口自定义错误
            } else {
              errorMsg = "状态码：${e.response?.statusCode}";
            }
          } else if (e.message != null) {
            errorMsg = e.message!;
          }
          Get.snackbar(
            "接口错误",
            errorMsg,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
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
      return {"code": -1, "msg": e.message ?? "登录失败"};
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
      return {"code": -1, "msg": e.message ?? "注册失败"};
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
      return {"code": -1, "msg": e.message ?? "获取用户信息失败"};
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
      return {"code": -1, "msg": e.message ?? "退出登录失败"};
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
      return {"code": -1, "msg": e.message ?? "注销失败"};
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
      return {"code": -1, "msg": e.message ?? "生理数据上传失败"};
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
      return {"code": -1, "msg": e.message ?? "生理数据查询失败"};
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
      return {"code": -1, "msg": e.message ?? "睡眠记录上传失败"};
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
      return {"code": -1, "msg": e.message ?? "睡眠记录查询失败"};
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
      return {"code": -1, "msg": e.message ?? "运动记录上传失败"};
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
      return {"code": -1, "msg": e.message ?? "运动记录查询失败"};
    }
  }

  // 查询运动月历 /data/query/sport/calendar
  Future<Map<String, dynamic>> querySportCalendar(
      int userId, int year, int month) async {
    try {
      debugPrint("调用查询运动月历接口，userId: $userId, year: $year, month: $month");
      final response = await _dio.get(
        "/data/query/sport/calendar",
        queryParameters: {"user_id": userId, "year": year, "month": month},
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("查询运动月历失败: ${e.message}");
      return {"code": -1, "msg": e.message ?? "运动月历查询失败"};
    }
  }

  // 查询周运动数据 /data/query/sport/week
  Future<Map<String, dynamic>> querySportWeek(int userId) async {
    try {
      debugPrint("调用查询周运动接口，userId: $userId");
      final response = await _dio.get(
        "/data/query/sport/week",
        queryParameters: {"user_id": userId},
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("查询周运动数据失败: ${e.message}");
      return {"code": -1, "msg": e.message ?? "周运动数据查询失败"};
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
      return {"code": -1, "msg": e.message ?? "获取设备最新态失败"};
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
      return {"code": -1, "msg": e.message ?? "获取设备历史失败"};
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
        // 处理其他错误
        if (e.response?.data["detail"] != null) {
          return {
            "code": e.response?.statusCode ?? -1,
            "msg": e.response?.data["detail"]
          };
        }
      }
      return {"code": -1, "msg": e.message ?? "生理数据AI分析失败"};
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
      return {"code": -1, "msg": e.message ?? "运动营养建议获取失败"};
    }
  }
}

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class ApiService {
  final Dio _dio = Dio(); // HTTP客户端
  // final String baseUrl = "http://10.0.2.2:8000"; // 模拟器指向本地后端，真机替换为电脑IP
  final String baseUrl = "http://localhost:8008";

  ApiService() {
    // 基础配置
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 8);
    _dio.options.receiveTimeout = const Duration(seconds: 8);
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
            if (e.response?.data["detail"] != null) {
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
      return response.data;
    } on DioException catch (e) {
      return {"code": -1, "msg": e.message ?? "登录失败"};
    }
  }

  // 注册 /auth/register
  Future<Map<String, dynamic>> register(Map<String, dynamic> params) async {
    try {
      final response = await _dio.post("/auth/register", data: params);
      return response.data;
    } on DioException catch (e) {
      return {"code": -1, "msg": e.message ?? "注册失败"};
    }
  }

  // 获取用户信息 /auth/userinfo
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final response = await _dio.get("/auth/userinfo");
      return response.data;
    } on DioException catch (e) {
      return {"code": -1, "msg": e.message ?? "获取用户信息失败"};
    }
  }

  // ********************* 二、生理数据接口 *********************
  // 上传生理数据（静息/运动/睡眠通用）/data/upload/physio
  Future<Map<String, dynamic>> uploadPhysioData(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/data/upload/physio", data: data);
      return response.data;
    } on DioException catch (e) {
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

  // 生成模拟睡眠生理数据 /data/mock/physio
  Future<Map<String, dynamic>> mockSleepPhysioData(int userId) async {
    try {
      final response = await _dio.get(
        "/data/mock/physio",
        queryParameters: {"user_id": userId, "scene": 2},
      );
      return response.data;
    } on DioException catch (e) {
      return {"code": -1, "msg": e.message ?? "模拟睡眠数据生成失败"};
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
      final response = await _dio.post("/data/upload/sport", data: data);
      return response.data;
    } on DioException catch (e) {
      return {"code": -1, "msg": e.message ?? "运动记录上传失败"};
    }
  }

  // 查询运动记录 /data/query/sport
  Future<Map<String, dynamic>> querySportRecord(int userId,
      {int limit = 7}) async {
    try {
      final response = await _dio.get(
        "/data/query/sport",
        queryParameters: {"user_id": userId, "limit": limit},
      );
      return response.data;
    } on DioException catch (e) {
      return {"code": -1, "msg": e.message ?? "运动记录查询失败"};
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
      return {"code": -1, "msg": e.message ?? "生理数据AI分析失败"};
    }
  }

  // AI运动营养建议 /ai/sport/nutrition
  Future<Map<String, dynamic>> aiSportNutrition(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/ai/sport/nutrition", data: data);
      return response.data;
    } on DioException catch (e) {
      return {"code": -1, "msg": e.message ?? "运动营养建议获取失败"};
    }
  }
}

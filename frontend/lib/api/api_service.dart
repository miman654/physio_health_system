// API service placeholder 接口封装
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart'; //持久化保存
import 'package:get/get.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = "http://10.0.2.2:8000"; // 替换为你的电脑IP

  // 初始化Dio（添加token）
  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? token = prefs.getString("token");
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
      ),
    );
  }

  // 登录
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

  // 上传生理数据
  Future<Map<String, dynamic>> uploadPhysioData(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post("/data/upload", data: data);
      return response.data;
    } on DioException catch (e) {
      return {"code": -1, "msg": e.message ?? "上传失败"};
    }
  }
}

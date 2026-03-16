import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/data_controller.dart';

class WsService {
  static WebSocketChannel? channel;
  static const String wsBaseUrl = "ws://10.0.2.2:8008/ws/physio";

  // 连接WebSocket（携带Token鉴权）
  static Future<void> connect() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      if (token == null || token.isEmpty) {
        Get.snackbar("提示", "请先登录再连接实时数据");
        return;
      }
      channel = IOWebSocketChannel.connect("$wsBaseUrl?token=$token");
      Get.snackbar("成功", "实时生理数据连接成功");
      // 监听WS消息
      channel!.stream.listen(
        (message) {
          Map<String, dynamic> data = jsonDecode(message);
          Get.find<DataController>().uploadPhysioData(data);
        },
        onError: (e) => Get.snackbar("WS错误", "实时数据连接异常：$e"),
        onDone: () => Get.snackbar("WS提示", "实时数据连接已断开"),
      );
    } catch (e) {
      Get.snackbar("错误", "实时数据连接失败：$e");
    }
  }

  // 发送WS消息
  static void sendMessage(String msg) {
    if (channel != null) {
      channel!.sink.add(msg);
    } else {
      Get.snackbar("提示", "实时连接未建立，无法发送消息");
    }
  }

  // 关闭WS连接
  static void close() {
    if (channel != null) {
      channel!.sink.close();
      channel = null;
      Get.snackbar("提示", "已关闭实时数据连接");
    }
  }
}

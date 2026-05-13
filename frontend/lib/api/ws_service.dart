import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';
import 'api_service.dart';

class WsService {
  static WebSocketChannel? channel;
  static String? _connectedDeviceId;
  static bool _suppressDisconnectNotice = false;
  static bool get isConnected => channel != null;

  static String get wsBaseUrl {
    final base = ApiService.baseUrl;
    if (base.startsWith("http://")) {
      return base.replaceFirst("http://", "ws://");
    }
    if (base.startsWith("https://")) {
      return base.replaceFirst("https://", "wss://");
    }
    return base;
  }

  // 连接WebSocket（订阅 device latest 流）
  static Future<void> connect({
    required String deviceId,
    required void Function(Map<String, dynamic> data) onMessage,
  }) async {
    try {
      if (channel != null && _connectedDeviceId == deviceId) {
        return;
      }

      if (channel != null) {
        close(showDisconnectNotice: false);
      }

      channel =
          WebSocketChannel.connect(Uri.parse("$wsBaseUrl/ws/device/$deviceId"));
      _connectedDeviceId = deviceId;
      Get.snackbar("成功", "实时生理数据连接成功");
      // 监听WS消息
      channel!.stream.listen(
        (message) {
          final decoded = jsonDecode(message);
          Map<String, dynamic> data;
          if (decoded is Map<String, dynamic>) {
            if (decoded["data"] is Map<String, dynamic>) {
              data = Map<String, dynamic>.from(decoded["data"] as Map);
            } else if (decoded["data"] is Map) {
              data = Map<String, dynamic>.from(decoded["data"] as Map);
            } else {
              data = Map<String, dynamic>.from(decoded);
            }
          } else {
            return;
          }
          onMessage(data);
        },
        onError: (e) {
          channel = null;
          _connectedDeviceId = null;
          Get.snackbar("WS错误", "实时数据连接异常：$e");
        },
        onDone: () {
          channel = null;
          _connectedDeviceId = null;
          if (!_suppressDisconnectNotice) {
            Get.snackbar("WS提示", "实时数据连接已断开");
          }
          _suppressDisconnectNotice = false;
        },
      );
    } catch (e) {
      channel = null;
      _connectedDeviceId = null;
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
  static void close({bool showDisconnectNotice = true}) {
    if (channel != null) {
      _suppressDisconnectNotice = !showDisconnectNotice;
      channel!.sink.close();
      channel = null;
      _connectedDeviceId = null;
    }
  }
}

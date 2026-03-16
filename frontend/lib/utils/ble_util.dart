import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import '../controller/data_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BleUtil {
  static List<BluetoothDevice> scannedDevices = [];
  static BluetoothDevice? connectedDevice;
  static BluetoothCharacteristic? dataChar;

  // 初始化蓝牙：检查可用性+打开蓝牙
  static Future<bool> initBle() async {
    // 检查设备是否支持蓝牙
    if (!await FlutterBluePlus.isAvailable) {
      Get.snackbar("错误", "当前设备不支持蓝牙BLE");
      return false;
    }
    // 打开蓝牙（未开启时）
    if (!await FlutterBluePlus.isOn) {
      Get.snackbar("提示", "正在打开蓝牙...");
      await FlutterBluePlus.turnOn();
    }
    // 监听蓝牙状态（修复后）
    FlutterBluePlus.state.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.off) {
        Get.snackbar("提示", "蓝牙已关闭，硬件数据采集功能不可用");
        scannedDevices.clear();
        connectedDevice = null;
        dataChar = null;
      }
    });
    Get.snackbar("成功", "蓝牙初始化完成");
    return true;
  }

  // 扫描蓝牙设备
  static Future<void> scanBleDevices() async {
    scannedDevices.clear();
    Get.snackbar("提示", "正在扫描健康硬件设备...");
    // 开始扫描
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    // 监听扫描结果
    FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (!scannedDevices.contains(result.device) &&
            result.device.name.isNotEmpty) {
          scannedDevices.add(result.device);
        }
      }
    });
    // 停止扫描
    FlutterBluePlus.stopScan().then((_) {
      Get.snackbar("提示", "扫描完成，共发现${scannedDevices.length}台设备");
    });
  }

  // 连接蓝牙硬件
  static Future<bool> connectBleDevice(BluetoothDevice device) async {
    try {
      Get.snackbar("提示", "正在连接${device.name}...");
      await device.connect(timeout: const Duration(seconds: 10));
      connectedDevice = device;
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic char in service.characteristics) {
          if (char.uuid.toString().toLowerCase().contains("fff1")) {
            dataChar = char;
            await char.setNotifyValue(true);
            char.value.listen((List<int> value) {
              _parseBleData(value);
            });
          }
        }
      }
      Get.snackbar("成功", "已连接${device.name}，开始采集生理数据");
      return true;
    } catch (e) {
      Get.snackbar("连接失败", "连接${device.name}异常：$e");
      return false;
    }
  }

  // 解析蓝牙硬件数据
  static void _parseBleData(List<int> value) {
    try {
      if (value.length < 5) return;
      int heartRate = value[0];
      int spo2 = value[1];
      double temp = value[2] + value[3] / 10;
      int scene = value[4];
      final dataController = Get.find<DataController>();
      SharedPreferences.getInstance().then((prefs) {
        int userId = prefs.getInt("user_id") ?? 1;
        dataController.uploadPhysioData({
          "user_id": userId,
          "heart_rate": heartRate,
          "spo2": spo2,
          "temp": temp,
          "scene": scene,
        });
      });
    } catch (e) {
      Get.snackbar("解析失败", "硬件数据解析异常：$e");
    }
  }

  // 断开蓝牙连接
  static Future<void> disconnectBleDevice() async {
    if (connectedDevice != null && connectedDevice!.isConnected) {
      await connectedDevice!.disconnect();
      scannedDevices.clear();
      connectedDevice = null;
      dataChar = null;
      Get.snackbar("提示", "已断开蓝牙硬件连接");
    }
  }
}

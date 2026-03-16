import 'package:flutter/material.dart';
import 'package:get/get.dart';
// 导入项目内的核心文件
import '../controller/auth_controller.dart';
import '../controller/data_controller.dart';
import '../utils/ble_util.dart';
import '../utils/permission_util.dart';
import '../component/bottom_tab_bar.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  // 获取全局控制器
  final AuthController authCtrl = Get.find<AuthController>();
  final DataController dataCtrl = Get.find<DataController>();

  // 页面初始化：权限+蓝牙+刷新数据
  void _initPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PermissionUtil.requestBasePermissions();
      await BleUtil.initBle();
      await dataCtrl.refreshAllData();
      // 可选：开启实时数据推送（如需WS功能取消注释）
      // WsService.connect();
    });
  }

  // 上传测试生理数据（静息场景）
  void _uploadTestPhysioData() {
    dataCtrl.uploadPhysioData({
      "user_id": authCtrl.userId.value,
      "heart_rate": 75,
      "spo2": 98,
      "temp": 36.5,
      "scene": 0,
    });
  }

  // 构建空数据提示（补全之前缺失的方法）
  Widget _buildEmptyTip(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // 构建指标卡片（心率/血氧/体温）
  Widget _buildIndicatorCard(
      String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // 构建功能按钮
  Widget _buildFuncButton(String title, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 80,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: onPressed,
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _initPage();
    return Scaffold(
      appBar: AppBar(
        title: const Text("健康首页"),
        centerTitle: true,
        actions: [
          // 退出登录按钮
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authCtrl.logout(),
            tooltip: "退出登录",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 欢迎卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "你好，${authCtrl.username.value}！",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text("当前生理指标总览", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 核心生理指标卡片（心率/血氧/体温）
            Obx(
              () {
                if (dataCtrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (dataCtrl.physioDataList.isEmpty) {
                  return _buildEmptyTip("暂无生理数据，点击下方按钮上传测试数据");
                }
                final latest = dataCtrl.physioDataList[0];
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey[200]!,
                          blurRadius: 8,
                          spreadRadius: 2)
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 心率
                      _buildIndicatorCard(
                          "心率",
                          "${latest["heart_rate"] ?? "--"} bpm",
                          Colors.red,
                          Icons.favorite),
                      // 血氧
                      _buildIndicatorCard("血氧", "${latest["spo2"] ?? "--"} %",
                          Colors.blue, Icons.bloodtype),
                      // 体温
                      _buildIndicatorCard("体温", "${latest["temp"] ?? "--"} ℃",
                          Colors.orange, Icons.thermostat),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // 功能按钮区
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFuncButton("上传测试数据", Icons.upload, _uploadTestPhysioData),
                _buildFuncButton(
                    "模拟睡眠数据", Icons.bed, () => dataCtrl.mockSleepPhysioData()),
                _buildFuncButton(
                    "刷新数据", Icons.refresh, () => dataCtrl.refreshAllData()),
                _buildFuncButton(
                    "蓝牙扫描", Icons.bluetooth, () => BleUtil.scanBleDevices()),
              ],
            ),
            const SizedBox(height: 30),
            // 近期生理数据列表
            const Text(
              "近期生理数据",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 10),
            Obx(
              () {
                if (dataCtrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = dataCtrl.physioDataList;
                if (list.length <= 1) {
                  return _buildEmptyTip("暂无历史生理数据");
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length - 1,
                  itemBuilder: (context, index) {
                    var data = list[index + 1];
                    String scene = data["scene"] == 0
                        ? "静息"
                        : data["scene"] == 1
                            ? "运动"
                            : "睡眠";
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text("场景：$scene",
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          "心率：${data["heart_rate"]} | 血氧：${data["spo2"]} | 体温：${data["temp"]}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Text(
                          (data["timestamp"] ?? "").toString().substring(0, 16),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      // 底部Tab导航
      bottomNavigationBar: const BottomTabBar(currentIndex: 0),
    );
  }
}

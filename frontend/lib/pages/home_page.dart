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

  // 上传测试生理数据的表单控制器
  final TextEditingController heartRateCtrl = TextEditingController();
  final TextEditingController spo2Ctrl = TextEditingController();
  final TextEditingController tempCtrl = TextEditingController();
  final RxInt selectedScene = 0.obs; // 0=静息 1=运动 2=睡眠

  // 页面初始化：权限+蓝牙+刷新数据
  void _initPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Web平台直接刷新数据，跳过权限和蓝牙
      if (GetPlatform.isWeb) {
        await dataCtrl.refreshAllData();
        return;
      }

      // 移动平台：尝试权限和蓝牙，但不影响主要功能
      try {
        await PermissionUtil.requestBasePermissions();
      } catch (e) {
        debugPrint("权限请求失败: $e，但不影响主要功能");
      }

      try {
        await BleUtil.initBle();
      } catch (e) {
        debugPrint("蓝牙初始化失败: $e，但不影响主要功能");
      }

      // 刷新数据
      try {
        await dataCtrl.refreshAllData();
      } catch (e) {
        debugPrint("刷新数据失败: $e");
      }
    });
  }

// 安全的蓝牙扫描方法
  void _scanBleDevices() {
    if (GetPlatform.isWeb) {
      Get.snackbar(
        "提示",
        "Web平台不支持蓝牙扫描",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      BleUtil.scanBleDevices();
    } catch (e) {
      Get.snackbar(
        "提示",
        "蓝牙功能暂时不可用",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

// 显示上传数据弹窗
  void _showUploadDialog() {
    // 重置场景选择
    selectedScene.value = 0;

    Get.dialog(
      AlertDialog(
        title: const Text(
          "选择场景",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // 场景选择卡片 - 用一个 Obx 包裹整个 Column，而不是每个卡片单独 Obx
              Obx(
                () => Column(
                  children: [
                    // 静息选项
                    _buildSceneOption(
                      scene: 0,
                      title: "静息",
                      icon: Icons.self_improvement,
                      color: Colors.green,
                      heartRate: 72,
                      spo2: 98,
                      temp: 36.5,
                      isSelected: selectedScene.value == 0,
                      onTap: () => selectedScene.value = 0,
                    ),
                    const SizedBox(height: 8),
                    // 运动选项
                    _buildSceneOption(
                      scene: 1,
                      title: "运动",
                      icon: Icons.directions_run,
                      color: Colors.orange,
                      heartRate: 125,
                      spo2: 95,
                      temp: 37.2,
                      isSelected: selectedScene.value == 1,
                      onTap: () => selectedScene.value = 1,
                    ),
                    const SizedBox(height: 8),
                    // 睡眠选项
                    _buildSceneOption(
                      scene: 2,
                      title: "睡眠",
                      icon: Icons.bed,
                      color: Colors.purple,
                      heartRate: 58,
                      spo2: 97,
                      temp: 36.0,
                      isSelected: selectedScene.value == 2,
                      onTap: () => selectedScene.value = 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 提示信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "选择场景后，系统会自动生成对应的生理数据",
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // 取消按钮
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen ?? false) {
                Get.back();
              }
            },
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          // 上传按钮
          Obx(
            () => ElevatedButton(
              onPressed: dataCtrl.isLoading.value
                  ? null
                  : () async {
                      // 立即关闭弹窗
                      if (Get.isDialogOpen ?? false) {
                        Get.back();
                      }

                      // 构建上传参数 - 只传user_id和scene
                      Map<String, dynamic> uploadData = {
                        "user_id": authCtrl.userId.value,
                        "scene": selectedScene.value,
                      };

                      // 上传数据
                      await dataCtrl.uploadPhysioData(uploadData);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: dataCtrl.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("上传"),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

// 构建场景选项卡片 - 修改为接受 isSelected 和 onTap 参数
  Widget _buildSceneOption({
    required int scene,
    required String title,
    required IconData icon,
    required Color color,
    required int heartRate,
    required int spo2,
    required double temp,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            // 图标
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            // 标题和默认值
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildDefaultValueChip(
                        label: "心率 $heartRate",
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      _buildDefaultValueChip(
                        label: "血氧 $spo2",
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      _buildDefaultValueChip(
                        label: "体温 $temp",
                        color: color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 选中标记
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

// 构建默认值标签
  Widget _buildDefaultValueChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }

  // 构建空数据提示
  Widget _buildEmptyTip(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // 格式化时间显示
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return "";
    if (timestamp.length >= 16) {
      return timestamp.substring(0, 16);
    }
    return timestamp;
  }

  // 获取场景名称
  String _getSceneName(int scene) {
    switch (scene) {
      case 0:
        return "静息";
      case 1:
        return "运动";
      case 2:
        return "睡眠";
      default:
        return "未知";
    }
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
      body: RefreshIndicator(
        onRefresh: () => dataCtrl.refreshAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.1),
                      Colors.blue.withOpacity(0.05)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                    const Text("当前生理指标总览",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 核心生理指标卡片（心率/血氧/体温）- 使用最新数据
              Obx(
                () {
                  if (dataCtrl.isLoading.value &&
                      dataCtrl.physioDataList.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (dataCtrl.physioDataList.isEmpty) {
                    return _buildEmptyTip("暂无生理数据，点击上方按钮上传测试数据");
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
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // 心率
                            _buildIndicatorCard(
                                "心率",
                                "${latest["heart_rate"] ?? "--"} bpm",
                                Colors.red,
                                Icons.favorite),
                            // 血氧
                            _buildIndicatorCard(
                                "血氧",
                                "${latest["spo2"] ?? "--"} %",
                                Colors.blue,
                                Icons.bloodtype),
                            // 体温
                            _buildIndicatorCard(
                                "体温",
                                "${latest["temp"] ?? "--"} ℃",
                                Colors.orange,
                                Icons.thermostat),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 显示当前场景和时间
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getSceneName(latest["scene"] ?? 0),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatTimestamp(latest["timestamp"]),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
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
                  _buildFuncButton("上传数据", Icons.upload, _showUploadDialog),
                  _buildFuncButton(
                      "模拟睡眠", Icons.bed, () => dataCtrl.mockSleepPhysioData()),
                  _buildFuncButton(
                      "刷新数据", Icons.refresh, () => dataCtrl.refreshAllData()),
                  _buildFuncButton(
                      "蓝牙扫描", Icons.bluetooth, () => _scanBleDevices()),
                ],
              ),
              const SizedBox(height: 30),
              // 在功能按钮区之后，近期生理数据之前添加
              const SizedBox(height: 20),
// AI建议卡片
              Obx(
                () {
                  if (dataCtrl.aiPhysioSuggestions.isEmpty) {
                    return const SizedBox.shrink(); // 没有建议就不显示
                  }
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.1),
                          Colors.blue.withOpacity(0.1)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purple.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.purple),
                            SizedBox(width: 8),
                            Text(
                              "AI健康建议",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...dataCtrl.aiPhysioSuggestions
                            .map((suggestion) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("• ",
                                          style: TextStyle(
                                              color: Colors.purple,
                                              fontSize: 14)),
                                      Expanded(
                                        child: Text(
                                          suggestion,
                                          style: const TextStyle(
                                              fontSize: 13, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        const SizedBox(height: 8),
                        Text(
                          "分析时间: ${_formatTimestamp(dataCtrl.aiPhysioAnalysis["analysis_time"])}",
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              // 近期生理数据列表（最近10条）
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
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final list = dataCtrl.physioDataList;
                  if (list.isEmpty) {
                    return _buildEmptyTip("暂无历史生理数据");
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      var data = list[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getSceneName(data["scene"] ?? 0),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _formatTimestamp(data["timestamp"]),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text("心率: ${data["heart_rate"] ?? "--"}"),
                                Text("血氧: ${data["spo2"] ?? "--"}%"),
                                Text("体温: ${data["temp"] ?? "--"}℃"),
                              ],
                            ),
                          ),
                          trailing: index == 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "最新",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      // 底部Tab导航
      bottomNavigationBar: const BottomTabBar(currentIndex: 0),
    );
  }
}

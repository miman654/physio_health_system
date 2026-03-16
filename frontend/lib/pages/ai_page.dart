// AI page placeholder

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../component/bottom_tab_bar.dart';
import '../api/api_service.dart';
import '../controller/auth_controller.dart';
import '../utils/api_formatter.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final ApiService _apiService = ApiService();
  final AuthController _authController = Get.find<AuthController>();

  String aiAnalysisResult = "";
  String nutritionResult = "";
  String sportType = "跑步";
  int sportDuration = 60;
  String sportTime = "";
  String userName = "";
  int? userAge;
  double? userWeight;
  double? userHeight;
  bool loadingAI = false;
  bool loadingNutrition = false;
  bool loadingUserInfo = false;
  bool loggingOut = false;

  @override
  void initState() {
    super.initState();
    sportTime = DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now().subtract(Duration(minutes: sportDuration)));
    _loadUserInfo();
    _fetchAIAnalysis();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      loadingUserInfo = true;
    });
    final res = await _apiService.getUserInfo();
    setState(() {
      loadingUserInfo = false;
      if (res["code"] == 200) {
        final data = res["data"] ?? {};
        userName = data["username"] ?? "";
        userAge = data["age"];
        userWeight =
            (data["weight"] is num) ? (data["weight"] as num).toDouble() : null;
        userHeight =
            (data["height"] is num) ? (data["height"] as num).toDouble() : null;
      } else {
        userName = "未登录";
      }
    });
  }

  Future<void> _handleLogout() async {
    setState(() {
      loggingOut = true;
    });
    await _authController.logout();
    setState(() {
      loggingOut = false;
    });
  }

  Future<void> _handleDeleteAccount() async {
    setState(() {
      loggingOut = true;
    });
    // 如果有账号注销接口，这里调用；当前仅清除本地并登出
    await _authController.logout();
    setState(() {
      loggingOut = false;
    });
  }

  Widget _buildDateTimeField(
      {required String value, required VoidCallback onTap}) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: value),
      decoration: const InputDecoration(
        labelText: '运动开始时间',
        suffixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      onTap: onTap,
    );
  }

  Future<void> _pickSportDateTime() async {
    DateTime initialDate = DateTime.now();
    try {
      initialDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(sportTime);
    } catch (_) {
      try {
        initialDate = DateFormat('yyyy-MM-dd HH:mm').parse(sportTime);
      } catch (_) {}
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      sportTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(selected);
    });
  }

  Future<void> _fetchAIAnalysis() async {
    setState(() {
      loadingAI = true;
    });
    final res =
        await _apiService.aiPhysioAnalysis(_authController.userId.value);
    debugPrint("AI分析接口返回: $res");
    setState(() {
      loadingAI = false;
      if (res["code"] == 200) {
        aiAnalysisResult = ApiResponseFormatter.formatApiData(res["data"]);
      } else {
        aiAnalysisResult = res["msg"] ?? "分析失败";
      }
    });
  }

  Future<void> _fetchNutrition() async {
    setState(() {
      loadingNutrition = true;
    });
    final res = await _apiService.aiSportNutrition({
      "sport_type": sportType,
      "sport_duration": sportDuration,
      "sport_time": sportTime,
    });
    debugPrint("运动营养建议接口返回: $res");
    setState(() {
      loadingNutrition = false;
      if (res["code"] == 200) {
        nutritionResult = ApiResponseFormatter.formatApiData(res["data"]);
      } else {
        nutritionResult = res["msg"] ?? "建议获取失败";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("我的", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xfff5f5f5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: loadingUserInfo
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage('images/image.png'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName.isEmpty ? '未设置用户名' : userName,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '年龄：${userAge ?? '--'}  体重：${userWeight?.toStringAsFixed(1) ?? '--'}kg  身高：${userHeight?.toStringAsFixed(1) ?? '--'}cm',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black54),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade300,
                                        foregroundColor: Colors.black87,
                                      ),
                                      onPressed: loggingOut
                                          ? null
                                          : _handleDeleteAccount,
                                      child: loggingOut
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('注销账号'),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                      ),
                                      onPressed:
                                          loggingOut ? null : _handleLogout,
                                      child: loggingOut
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('退出登录'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // 生理数据AI分析卡片
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.blue, size: 28),
                        SizedBox(width: 8),
                        Text("生理数据AI分析",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    loadingAI
                        ? const Center(child: CircularProgressIndicator())
                        : Text(
                            aiAnalysisResult.isEmpty
                                ? "暂无分析结果"
                                : aiAnalysisResult,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87),
                          ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("重新分析"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: loadingAI ? null : _fetchAIAnalysis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 运动营养建议卡片
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.restaurant_menu,
                            color: Colors.orange, size: 28),
                        SizedBox(width: 8),
                        Text("运动营养建议",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: "运动类型",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            controller: TextEditingController(text: sportType),
                            onChanged: (v) => sportType = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: "运动时长(分钟)",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(
                                text: sportDuration.toString()),
                            onChanged: (v) {
                              sportDuration = int.tryParse(v) ?? 60;
                              setState(() {
                                sportTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                                    .format(DateTime.now().subtract(
                                        Duration(minutes: sportDuration)));
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickSportDateTime,
                            child: AbsorbPointer(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: "运动开始时间",
                                  suffixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                controller:
                                    TextEditingController(text: sportTime),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    loadingNutrition
                        ? const Center(child: CircularProgressIndicator())
                        : Text(
                            nutritionResult.isEmpty ? "暂无建议" : nutritionResult,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87),
                          ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.tips_and_updates),
                        label: const Text("获取建议"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: loadingNutrition ? null : _fetchNutrition,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomTabBar(currentIndex: 3),
    );
  }
}

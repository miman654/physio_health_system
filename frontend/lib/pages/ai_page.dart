// AI page

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
    await _authController.loadUserInfo();
    setState(() {
      loadingUserInfo = false;
    });
  }

  Future<void> _handleLogout() async {
    setState(() {
      loggingOut = true;
    });

    // 调用退出登录
    await _authController.logout();

    // 注意：这里不需要再设置 loggingOut = false，因为页面已经跳转
    // 如果还在这里设置，会触发 mounted 检查
  }

  Future<void> _handleDeleteAccount() async {
    setState(() {
      loggingOut = true;
    });

    // 调用注销账号
    await _authController.deleteAccount();

    // 注意：这里不需要再设置 loggingOut = false，因为页面已经跳转
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

  Future<void> _fetchNutrition() async {
    setState(() {
      loadingNutrition = true;
    });

    try {
      final res = await _apiService.aiSportNutrition({
        "user_id": _authController.userId.value,
        "sport_type": sportType,
        "sport_duration": sportDuration,
        "sport_time": sportTime,
      });

      debugPrint("运动营养建议接口返回: $res");

      setState(() {
        loadingNutrition = false;
        if (res["code"] == 200) {
          final data = res["data"] ?? {};

          // 优先显示 nutrition_suggestions 数组
          if (data["nutrition_suggestions"] != null &&
              (data["nutrition_suggestions"] as List).isNotEmpty) {
            final suggestions = data["nutrition_suggestions"] as List;
            nutritionResult = suggestions.map((s) => "• $s").join("\n\n");
          }
          // 如果有 estimated_calorie 和 user_weight 等信息，也显示出来
          else {
            StringBuffer buffer = StringBuffer();
            if (data["estimated_calorie"] != null) {
              buffer.writeln("预估消耗: ${data["estimated_calorie"]}千卡");
            }
            if (data["user_weight"] != null) {
              buffer.writeln("用户体重: ${data["user_weight"]}kg");
            }
            if (data["sport_type"] != null) {
              buffer.writeln("运动类型: ${data["sport_type"]}");
            }
            if (data["sport_duration"] != null) {
              buffer.writeln("运动时长: ${data["sport_duration"]}分钟");
            }
            nutritionResult = buffer.toString();
          }
        } else {
          nutritionResult = res["msg"] ?? "建议获取失败";
        }
      });
    } catch (e) {
      setState(() {
        loadingNutrition = false;
        nutritionResult = "请求异常: $e";
      });
    }
  }

  Future<void> _fetchAIAnalysis() async {
    setState(() {
      loadingAI = true;
    });

    try {
      final res =
          await _apiService.aiPhysioAnalysis(_authController.userId.value);
      debugPrint("AI分析接口返回: $res");

      setState(() {
        loadingAI = false;
        if (res["code"] == 200) {
          final data = res["data"] ?? {};

          // 优先显示 suggestions 数组
          if (data["suggestions"] != null &&
              (data["suggestions"] as List).isNotEmpty) {
            final suggestions = data["suggestions"] as List;
            aiAnalysisResult = suggestions.map((s) => "• $s").join("\n\n");
          }
          // 否则显示其他信息
          else {
            StringBuffer buffer = StringBuffer();
            if (data["analysis_time"] != null) {
              buffer.writeln("分析时间: ${data["analysis_time"]}");
            }
            if (data["user_info"] != null) {
              final userInfo = data["user_info"];
              buffer.writeln(
                  "年龄: ${userInfo["age"] ?? '--'} 性别: ${userInfo["gender"] ?? '--'}");
              buffer.writeln(
                  "体重: ${userInfo["weight"] ?? '--'}kg 身高: ${userInfo["height"] ?? '--'}cm");
              if (userInfo["bmi"] != null) {
                buffer.writeln("BMI: ${userInfo["bmi"]}");
              }
            }
            aiAnalysisResult = buffer.toString();
          }
        } else {
          aiAnalysisResult = res["msg"] ?? "分析失败";
        }
      });
    } catch (e) {
      setState(() {
        loadingAI = false;
        aiAnalysisResult = "请求异常: $e";
      });
    }
  }

  // 辅助方法：构建信息项
  Widget _buildInfoItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 根据性别获取颜色
    Color getGenderColor() {
      if (_authController.userGender.value == "男") return Colors.blue;
      if (_authController.userGender.value == "女") return Colors.pink;
      return Colors.purple;
    }

    Color getGenderLightColor() {
      if (_authController.userGender.value == "男") return Colors.blue.shade300;
      if (_authController.userGender.value == "女") return Colors.pink.shade300;
      return Colors.purple.shade300;
    }

    Color getGenderDarkColor() {
      if (_authController.userGender.value == "男") return Colors.blue.shade600;
      if (_authController.userGender.value == "女") return Colors.pink.shade600;
      return Colors.purple.shade600;
    }

    IconData getGenderIcon() {
      if (_authController.userGender.value == "男") return Icons.male;
      if (_authController.userGender.value == "女") return Icons.female;
      return Icons.person;
    }

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
            // 用户信息卡片
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: loadingUserInfo
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          // 头像区域
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      getGenderLightColor(),
                                      getGenderDarkColor()
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: getGenderColor().withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage:
                                      _authController.username.value.isNotEmpty
                                          ? const AssetImage(
                                              'assets/images/image.png')
                                          : null,
                                  child: _authController.username.value.isEmpty
                                      ? Icon(
                                          getGenderIcon(),
                                          size: 40,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              // 性别角标
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: getGenderColor(),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            getGenderColor().withOpacity(0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    getGenderIcon(),
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // 用户信息区域
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _authController.username.value.isEmpty
                                          ? '未设置用户名'
                                          : _authController.username.value,
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            getGenderColor().withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _authController.userGender.value.isEmpty
                                            ? '未知'
                                            : _authController.userGender.value,
                                        style: TextStyle(
                                          color: getGenderColor(),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // 信息卡片
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        getGenderColor().withOpacity(0.05),
                                        getGenderColor().withOpacity(0.02),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: getGenderColor().withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildInfoItem(
                                        Icons.calendar_today,
                                        '年龄',
                                        _authController.userAge.value > 0
                                            ? '${_authController.userAge.value}岁'
                                            : '--',
                                        getGenderColor(),
                                      ),
                                      _buildInfoItem(
                                        Icons.line_weight,
                                        '体重',
                                        _authController.userWeight.value > 0
                                            ? '${_authController.userWeight.value.toStringAsFixed(1)}kg'
                                            : '--',
                                        getGenderColor(),
                                      ),
                                      _buildInfoItem(
                                        Icons.height,
                                        '身高',
                                        _authController.userHeight.value > 0
                                            ? '${_authController.userHeight.value.toStringAsFixed(1)}cm'
                                            : '--',
                                        getGenderColor(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // 操作按钮
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.grey.shade700,
                                        side: BorderSide(
                                            color: Colors.grey.shade300),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
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
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
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
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.analytics,
                                color: Colors.blue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "AI 健康分析",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "基于您的健康数据",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      loadingAI
                          ? const Center(child: CircularProgressIndicator())
                          : aiAnalysisResult.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "暂无分析结果，点击下方按钮获取建议",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.blue.shade200, width: 1),
                                  ),
                                  child: Text(
                                    aiAnalysisResult,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                        height: 1.5),
                                  ),
                                ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text("重新分析"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: loadingAI ? null : _fetchAIAnalysis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 运动营养建议卡片
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade100.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.restaurant_menu,
                                color: Colors.orange, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "运动营养建议",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 输入区域美化
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: "运动类型",
                                      labelStyle: TextStyle(
                                          color: Colors.orange.shade700),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.orange.shade400),
                                      ),
                                      prefixIcon: Icon(Icons.directions_run,
                                          color: Colors.orange.shade400),
                                    ),
                                    controller:
                                        TextEditingController(text: sportType),
                                    onChanged: (v) => sportType = v,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: "时长(分钟)",
                                      labelStyle: TextStyle(
                                          color: Colors.orange.shade700),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.orange.shade400),
                                      ),
                                      prefixIcon: Icon(Icons.timer,
                                          color: Colors.orange.shade400),
                                    ),
                                    keyboardType: TextInputType.number,
                                    controller: TextEditingController(
                                        text: sportDuration.toString()),
                                    onChanged: (v) {
                                      sportDuration = int.tryParse(v) ?? 60;
                                      setState(() {
                                        sportTime =
                                            DateFormat('yyyy-MM-dd HH:mm:ss')
                                                .format(DateTime.now().subtract(
                                                    Duration(
                                                        minutes:
                                                            sportDuration)));
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _pickSportDateTime,
                              child: AbsorbPointer(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: "开始时间",
                                    labelStyle: TextStyle(
                                        color: Colors.orange.shade700),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.orange.shade400),
                                    ),
                                    prefixIcon: Icon(Icons.calendar_today,
                                        color: Colors.orange.shade400),
                                  ),
                                  controller:
                                      TextEditingController(text: sportTime),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      loadingNutrition
                          ? const Center(child: CircularProgressIndicator())
                          : nutritionResult.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "暂无建议，点击下方按钮获取",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.orange.shade200,
                                        width: 1),
                                  ),
                                  child: Text(
                                    nutritionResult,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                        height: 1.5),
                                  ),
                                ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.tips_and_updates, size: 18),
                          label: const Text("获取建议"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: loadingNutrition ? null : _fetchNutrition,
                        ),
                      ),
                    ],
                  ),
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

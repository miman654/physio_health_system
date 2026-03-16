// Sleep page placeholder

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../component/bottom_tab_bar.dart';
import 'package:get/get.dart';
import '../api/api_service.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  final ApiService _apiService = ApiService();

  // 用户信息（从后端获取）
  final int userId = 1; // 从登录获取
  String userName = '';
  int? userAge;
  double? userWeight;
  double? userHeight;

  // 表单控制器
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  final TextEditingController scoreController = TextEditingController();
  final TextEditingController deepController = TextEditingController();
  final TextEditingController lightController = TextEditingController();

  // 睡眠记录
  List<Map<String, dynamic>> sleepRecords = [];
  bool loading = false;
  bool scoreError = false;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    fetchSleepRecords();

    scoreController.addListener(() {
      if (scoreError && scoreController.text.isNotEmpty) {
        setState(() {
          scoreError = false;
        });
      }
    });
  }

  Future<void> fetchUserInfo() async {
    final resp = await _apiService.getUserInfo();
    if (resp["code"] == 200) {
      setState(() {
        userName = resp["data"]["username"] ?? '';
        userAge = resp["data"]["age"];
        userWeight = resp["data"]["weight"];
        userHeight = resp["data"]["height"];
      });
    } else {
      Get.snackbar('获取用户信息失败', resp["msg"] ?? "未知错误");
    }
  }

  Future<void> fetchSleepRecords() async {
    setState(() {
      loading = true;
    });
    final resp = await _apiService.querySleepRecord(userId, limit: 7);
    setState(() {
      loading = false;
      if (resp["code"] == 200) {
        List<Map<String, dynamic>> records =
            List<Map<String, dynamic>>.from(resp["data"]);
        sleepRecords = records;
      } else {
        Get.snackbar('查询失败', resp["msg"] ?? "未知错误");
      }
    });
  }

  Future<void> uploadSleepRecord() async {
    final start = startController.text;
    final end = endController.text;
    final score = int.tryParse(scoreController.text);
    final deep = int.tryParse(deepController.text);
    final light = int.tryParse(lightController.text);
    if (start.isEmpty || end.isEmpty || score == null) {
      Get.snackbar('提示', '请填写必填项');
      return;
    }

    if (score < 0 || score > 100) {
      setState(() {
        scoreError = true;
        scoreController.clear();
      });
      Get.snackbar('接口错误', '睡眠评分异常（范围0-100）');
      return;
    }

    setState(() {
      scoreError = false;
      loading = true;
    });

    // 后端期望的时间格式带秒，前端只展示到分钟
    String normalize(String s) {
      try {
        final dt = DateFormat('yyyy-MM-dd HH:mm').parse(s);
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
      } catch (_) {}
      return s;
    }

    setState(() {
      loading = true;
    });
    final resp = await _apiService.uploadSleepRecord({
      'user_id': userId,
      'sleep_start': normalize(start),
      'sleep_end': normalize(end),
      'sleep_score': score,
      if (deep != null) 'deep_sleep_duration': deep,
      if (light != null) 'light_sleep_duration': light,
    });
    setState(() {
      loading = false;
    });
    if (resp["code"] == 200) {
      Get.snackbar('上传成功', '睡眠记录已上传');
      fetchSleepRecords();
    } else {
      Get.snackbar('上传失败', resp["msg"] ?? "未知错误");
    }
  }

  Widget buildProfile() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Stack(
          alignment: Alignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('images/image.png'),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.edit, size: 18, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(userName.isNotEmpty ? userName : '未设置',
            style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(userAge != null ? '$userAge岁' : '',
            style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(userWeight != null ? '${userWeight}kg' : '',
            style: const TextStyle(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 2),
        Text(userHeight != null ? '${userHeight}cm' : '',
            style: const TextStyle(fontSize: 16, color: Colors.white)),
      ],
    );
  }

  Widget buildSleepForm() {
    return Card(
      color: Colors.white.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('上传睡眠记录',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            buildDateTimeField(startController, '开始时间'),
            buildDateTimeField(endController, '结束时间'),
            buildTextField(scoreController, '睡眠评分 (0-100)',
                inputType: TextInputType.number, error: scoreError),
            buildTextField(deepController, '深睡时长 (分钟)',
                inputType: TextInputType.number),
            buildTextField(lightController, '浅睡时长 (分钟)',
                inputType: TextInputType.number),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: loading ? null : uploadSleepRecord,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('上传'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDateTimeField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.yellow),
            borderRadius: BorderRadius.circular(10),
          ),
          fillColor: Colors.white.withOpacity(0.05),
          filled: true,
        ),
        onTap: () => _pickDateTime(context, controller),
      ),
    );
  }

  Future<void> _pickDateTime(
      BuildContext context, TextEditingController controller) async {
    final ctx = context;
    DateTime initial = DateTime.now();
    try {
      initial = DateFormat('yyyy-MM-dd HH:mm').parse(controller.text);
    } catch (_) {
      try {
        initial = DateFormat('yyyy-MM-dd HH:mm:ss').parse(controller.text);
      } catch (_) {}
    }

    final date = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (date == null) return;

    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) return;
    if (time == null) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    controller.text = DateFormat('yyyy-MM-dd HH:mm').format(selected);
  }

  Widget buildTextField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text, bool error = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: error ? Colors.red : Colors.white24),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: error ? Colors.red : Colors.yellow),
            borderRadius: BorderRadius.circular(10),
          ),
          fillColor: Colors.white.withOpacity(0.05),
          filled: true,
        ),
      ),
    );
  }

  Widget buildSleepRecords() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: Colors.white.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('最近睡眠记录',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (sleepRecords.isEmpty)
                const Text('暂无记录', style: TextStyle(color: Colors.white70))
              else
                LayoutBuilder(builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  const minItemWidth = 260.0;
                  final count = (maxWidth / minItemWidth).floor().clamp(1, 3);
                  final itemWidth = (maxWidth - (count - 1) * 12) / count;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: sleepRecords
                        .map((record) => SizedBox(
                              width: itemWidth,
                              child: buildSleepRecordItem(record),
                            ))
                        .toList(),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      try {
        final dt = DateFormat('yyyy-MM-dd HH:mm').parse(raw);
        return DateFormat('yyyy-MM-dd HH:mm').format(dt);
      } catch (_) {
        return raw;
      }
    }
  }

  Widget buildSleepRecordItem(Map<String, dynamic> record) {
    final start = _formatDateTime(record['sleep_start']?.toString());
    final end = _formatDateTime(record['sleep_end']?.toString());
    final score = record['sleep_score']?.toString() ?? '--';
    final deep = record['deep_sleep_duration']?.toString() ?? '--';
    final light = record['light_sleep_duration']?.toString() ?? '--';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('开始: $start', style: const TextStyle(color: Colors.white)),
          Text('结束: $end', style: const TextStyle(color: Colors.white)),
          Text('评分: $score', style: const TextStyle(color: Colors.yellow)),
          Text('深睡: $deep 分钟', style: const TextStyle(color: Colors.white70)),
          Text('浅睡: $light 分钟', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2344),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildProfile(),
              buildSleepForm(),
              buildSleepRecords(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomTabBar(currentIndex: 2),
    );
  }
}

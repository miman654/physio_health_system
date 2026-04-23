// Sleep page

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../component/bottom_tab_bar.dart';
import 'package:get/get.dart';
import '../api/api_service.dart';
import '../controller/auth_controller.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  final ApiService _apiService = ApiService();
  final AuthController _authController = Get.find<AuthController>();

  // 用户信息
  String userName = '';
  int? userAge;
  double? userWeight;
  double? userHeight;

  // 表单控制器
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  // 睡眠记录
  List<Map<String, dynamic>> sleepRecords = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    fetchSleepRecords();
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
    final resp = await _apiService.querySleepRecord(
      _authController.userId.value,
      limit: 7,
    );
    setState(() {
      loading = false;
      if (resp["code"] == 200) {
        List<Map<String, dynamic>> records =
            List<Map<String, dynamic>>.from(resp["data"] ?? []);
        sleepRecords = records;
      } else {
        Get.snackbar('查询失败', resp["msg"] ?? "未知错误");
      }
    });
  }

  Future<void> uploadSleepRecord() async {
    final start = startController.text;
    final end = endController.text;

    if (start.isEmpty || end.isEmpty) {
      Get.snackbar('提示', '请填写入睡时间和起床时间');
      return;
    }

    setState(() {
      loading = true;
    });

    // 后端期望的时间格式带秒，前端只展示到分钟
    String normalize(String s) {
      try {
        final dt = DateFormat('yyyy-MM-dd HH:mm').parse(s);
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
      } catch (_) {
        try {
          final dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(s);
          return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
        } catch (_) {}
      }
      return s;
    }

    final resp = await _apiService.uploadSleepRecord({
      'user_id': _authController.userId.value,
      'sleep_start': normalize(start),
      'sleep_end': normalize(end),
    });

    setState(() {
      loading = false;
    });

    if (resp["code"] == 200) {
      Get.snackbar('上传成功', '睡眠记录已上传');
      // 清空表单
      startController.clear();
      endController.clear();
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
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.transparent,
                child:
                    Icon(Icons.nightlight_round, size: 40, color: Colors.white),
              ),
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
        if (userAge != null)
          Text('$userAge岁',
              style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 2),
        if (userWeight != null)
          Text('${userWeight}kg',
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 2),
        if (userHeight != null)
          Text('${userHeight}cm',
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.bedtime, color: Colors.yellow, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('上传睡眠记录',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            buildDateTimeField(startController, '入睡时间', Icons.nightlight),
            const SizedBox(height: 8),
            buildDateTimeField(endController, '起床时间', Icons.wb_sunny),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.yellow.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.yellow, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '系统会根据您的睡眠时长自动计算评分和深度睡眠时间',
                      style: TextStyle(color: Colors.yellow, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: loading ? null : uploadSleepRecord,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('上传睡眠记录',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDateTimeField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.yellow),
        suffixIcon: const Icon(Icons.calendar_today, color: Colors.yellow),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  const Text('最近睡眠记录',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (sleepRecords.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.night_shelter,
                          size: 48, color: Colors.white24),
                      SizedBox(height: 8),
                      Text('暂无睡眠记录', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sleepRecords.length,
                  itemBuilder: (context, index) {
                    return buildSleepRecordItem(sleepRecords[index]);
                  },
                ),
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
      return DateFormat('MM-dd HH:mm').format(dt);
    } catch (_) {
      try {
        final dt = DateFormat('yyyy-MM-dd HH:mm').parse(raw);
        return DateFormat('MM-dd HH:mm').format(dt);
      } catch (_) {
        return raw;
      }
    }
  }

  String _getScoreQuality(int score) {
    if (score >= 85) return '优秀';
    if (score >= 70) return '良好';
    if (score >= 60) return '一般';
    return '较差';
  }

  Widget buildSleepRecordItem(Map<String, dynamic> record) {
    final start = _formatDateTime(record['sleep_start']?.toString());
    final end = _formatDateTime(record['sleep_end']?.toString());
    final score = record['sleep_score'] ?? 0;
    final deepSleep = record['deep_sleep_duration'] ?? 0;
    final avgHeartRate = record['avg_heart_rate'] ?? '--';
    final avgSpo2 = record['avg_spo2'] ?? '--';
    final avgTemp = record['avg_temp'] ?? '--';
    final suggestion = record['suggestion'] ?? '';

    // 计算睡眠时长
    String durationText = '';
    if (record['sleep_duration_hours'] != null) {
      durationText = '${record['sleep_duration_hours']}小时';
    } else if (record['sleep_duration'] != null) {
      durationText = '${(record['sleep_duration'] / 60).toStringAsFixed(1)}小时';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间和评分
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$start - $end',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: score >= 80 ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score分 ${_getScoreQuality(score)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 睡眠时长和深睡
          Row(
            children: [
              Icon(Icons.timer, size: 14, color: Colors.yellow.shade700),
              const SizedBox(width: 4),
              Text(
                '时长: $durationText',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Icon(Icons.night_shelter, size: 14, color: Colors.blue.shade300),
              const SizedBox(width: 4),
              Text(
                '深睡: $deepSleep分钟',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 生理指标
          Row(
            children: [
              _buildPhysioChip(
                  '心率', '$avgHeartRate', Icons.favorite, Colors.red),
              const SizedBox(width: 8),
              _buildPhysioChip('血氧', '$avgSpo2%', Icons.bloodtype, Colors.blue),
              const SizedBox(width: 8),
              _buildPhysioChip(
                  '体温', '$avgTemp°C', Icons.thermostat, Colors.orange),
            ],
          ),
          if (suggestion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.yellow, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhysioChip(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '$label $value',
            style: TextStyle(fontSize: 11, color: color),
          ),
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

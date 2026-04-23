// Sport page

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../component/bottom_tab_bar.dart';
import '../api/api_service.dart';
import '../controller/auth_controller.dart';
import '../controller/data_controller.dart';

class SportPage extends StatefulWidget {
  const SportPage({super.key});

  @override
  State<SportPage> createState() => _SportPageState();
}

class _SportPageState extends State<SportPage> {
  final ApiService _apiService = ApiService();
  final AuthController _authController = Get.find<AuthController>();
  final DataController _dataController = Get.find<DataController>();

  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  String sportType = '跑步';
  final List<String> sportTypes = [
    '步行',
    '快走',
    '跑步',
    '快跑',
    '骑行',
    '游泳',
    '瑜伽',
    '健身'
  ];

  bool loading = false; // 用于上传操作的loading

  @override
  void initState() {
    super.initState();
    fetchSportRecords(); // 初始化时获取数据
  }

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  Future<void> fetchSportRecords() async {
    setState(() {
      loading = true;
    });
    await _dataController.querySportRecord(limit: 10);
    setState(() {
      loading = false;
    });
  }

  Future<void> uploadSportRecord() async {
    final start = startController.text;
    final end = endController.text;

    if (start.isEmpty || end.isEmpty) {
      Get.snackbar('提示', '请填写运动开始和结束时间');
      return;
    }

    setState(() {
      loading = true;
    });

    // 调用上传接口并获取返回值
    var result = await _dataController.uploadSportRecord({
      'user_id': _authController.userId.value,
      'sport_type': sportType,
      'sport_start': _formatWithSeconds(start),
      'sport_end': _formatWithSeconds(end),
    });

    setState(() {
      loading = false;
      // 清空表单
      startController.clear();
      endController.clear();
    });

    // 如果上传成功，输出卡路里
    if (result != null && result["code"] == 200) {
      final data = result["data"];
      if (data != null && data["calorie"] != null) {
        // 在控制台输出卡路里
        debugPrint('本次运动消耗卡路里: ${data["calorie"]} 千卡');

        // 也可以显示一个提示框
        Get.snackbar(
          '运动消耗',
          '本次运动消耗了 ${data["calorie"]} 千卡',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  String _formatWithSeconds(String value) {
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(value);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (_) {
      try {
        final dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(value);
        return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
      } catch (_) {}
      return value;
    }
  }

  Future<void> _pickDateTime(
      BuildContext context, TextEditingController controller) async {
    DateTime initial = DateTime.now();
    try {
      initial = DateFormat('yyyy-MM-dd HH:mm').parse(controller.text);
    } catch (_) {
      try {
        initial = DateFormat('yyyy-MM-dd HH:mm:ss').parse(controller.text);
      } catch (_) {}
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
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

  Widget buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.yellow.withOpacity(0.15),
              Colors.orange.withOpacity(0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.yellow.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: sportType,
            isExpanded: true,
            dropdownColor: const Color(0xFF2C2344),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_drop_down,
                  color: Colors.yellow, size: 28),
            ),
            items: sportTypes.map((type) {
              IconData iconData;
              Color iconColor;

              // 根据运动类型选择不同的图标
              switch (type) {
                case '步行':
                  iconData = Icons.directions_walk;
                  iconColor = Colors.green;
                  break;
                case '快走':
                  iconData = Icons.directions_walk;
                  iconColor = Colors.lightGreen;
                  break;
                case '跑步':
                  iconData = Icons.directions_run;
                  iconColor = Colors.orange;
                  break;
                case '快跑':
                  iconData = Icons.run_circle;
                  iconColor = Colors.deepOrange;
                  break;
                case '骑行':
                  iconData = Icons.directions_bike;
                  iconColor = Colors.blue;
                  break;
                case '游泳':
                  iconData = Icons.pool;
                  iconColor = Colors.lightBlue;
                  break;
                case '瑜伽':
                  iconData = Icons.self_improvement;
                  iconColor = Colors.purple;
                  break;
                case '健身':
                  iconData = Icons.fitness_center;
                  iconColor = Colors.red;
                  break;
                default:
                  iconData = Icons.sports;
                  iconColor = Colors.yellow;
              }

              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(iconData, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      type,
                      style: TextStyle(
                        color:
                            sportType == type ? Colors.yellow : Colors.white70,
                        fontWeight: sportType == type
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  sportType = value;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget buildDateTimeField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
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
      ),
    );
  }

  Widget buildRecordItem(Map<String, dynamic> record) {
    final start = _formatDateTime(record['sport_start']?.toString());
    final end = _formatDateTime(record['sport_end']?.toString());
    final type = record['sport_type']?.toString() ?? '';
    final hr = record['avg_heart_rate']?.toString() ?? '--';
    final spo2 = record['avg_spo2']?.toString() ?? '--';
    final temp = record['avg_temp']?.toString() ?? '--';
    final calorie = record['calorie']?.toString() ?? '--';
    final suggestion = record['suggestion']?.toString() ?? '';

    // 计算运动时长
    String durationText = '';
    if (record['sport_start'] != null && record['sport_end'] != null) {
      try {
        final startTime =
            DateFormat('yyyy-MM-dd HH:mm:ss').parse(record['sport_start']);
        final endTime =
            DateFormat('yyyy-MM-dd HH:mm:ss').parse(record['sport_end']);
        final minutes = endTime.difference(startTime).inMinutes;
        if (minutes > 0) {
          durationText = '$minutes分钟';
        }
      } catch (_) {}
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
          // 运动类型和时间
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (durationText.isNotEmpty)
                    Text(
                      durationText,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
              Text(
                '$start - $end',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 生理指标
          Row(
            children: [
              _buildPhysioChip('心率', hr, Icons.favorite, Colors.red),
              const SizedBox(width: 8),
              _buildPhysioChip('血氧', '$spo2%', Icons.bloodtype, Colors.blue),
              const SizedBox(width: 8),
              _buildPhysioChip(
                  '体温', '$temp°C', Icons.thermostat, Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          // 卡路里
          Row(
            children: [
              Icon(Icons.local_fire_department,
                  size: 14, color: Colors.orange.shade300),
              const SizedBox(width: 4),
              Text(
                '消耗: $calorie 千卡',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          if (suggestion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.green, size: 16),
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

  Widget buildRecordsSection() {
    return Card(
      color: Colors.white.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                  child: const Icon(Icons.history, color: Colors.yellow),
                ),
                const SizedBox(width: 12),
                const Text(
                  '运动记录',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 使用 Obx 监听数据变化
            Obx(() {
              if (_dataController.isLoading.value && loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final records = _dataController.sportDataList;

              if (records.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.sports_score, size: 48, color: Colors.white24),
                      SizedBox(height: 8),
                      Text(
                        '暂无运动记录',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  return buildRecordItem(records[index]);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/sport.png',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.25)),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    '运动记录',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 上传表单卡片
                  Card(
                    color: Colors.white.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                                child: const Icon(Icons.upload,
                                    color: Colors.yellow),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '上传运动记录',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          buildDropdown(),
                          buildDateTimeField(
                              startController, '开始时间', Icons.play_arrow),
                          buildDateTimeField(endController, '结束时间', Icons.stop),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.yellow.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.yellow.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.yellow, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '系统会根据您的运动类型和时长自动计算卡路里消耗',
                                    style: TextStyle(
                                        color: Colors.yellow, fontSize: 12),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: loading ? null : uploadSportRecord,
                              child: loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.black)
                                  : const Text(
                                      '上传运动记录',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  buildRecordsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomTabBar(currentIndex: 1),
    );
  }
}
